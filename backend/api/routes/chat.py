import json
import re
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from db.firebase import db
from agents.prioritizer.agent import root_agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

APP_NAME = "bonita-prioritizer"
session_service = InMemorySessionService()
runner = Runner(agent=root_agent, app_name=APP_NAME, session_service=session_service)
FINAL_LIST_MESSAGE = "The list will be created for you very soon!"

async def call_prioritizer_agent(user_id: str, session_id: str, text: str) -> str:
    existing = await session_service.get_session(
        app_name=APP_NAME,
        user_id=user_id,
        session_id=session_id,
    )
    
    if not existing:
        await session_service.create_session(
            app_name=APP_NAME,
            user_id=user_id,
            session_id=session_id,
        )

    msg = types.Content(role="user", parts=[types.Part(text=text)])
    reply = ""

    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message=msg,
    ):
        if event.is_final_response() and event.content and event.content.parts:
            reply = "".join(
                p.text for p in event.content.parts if getattr(p, "text", None)
            )
            break

    return reply or "No response from agent."


def _extract_json_candidate(reply: str) -> str | None:
    text = (reply or "").strip()
    if not text:
        return None

    fenced = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", text, re.IGNORECASE)
    if fenced:
        return fenced.group(1).strip()

    return text


def _parse_task_list_payload(payload):
    if isinstance(payload, list):
        return payload

    if isinstance(payload, dict):
        for key in ("tasks", "final_tasks", "task_list", "list"):
            value = payload.get(key)
            if isinstance(value, list):
                return value

    return None


def parse_final_tasks(reply: str):
    candidate = _extract_json_candidate(reply)
    if not candidate:
        return None

    parse_attempts = [candidate]

    # Fallback for extra leading/trailing prose around a JSON array/object.
    array_match = re.search(r"\[[\s\S]*\]", candidate)
    object_match = re.search(r"\{[\s\S]*\}", candidate)
    if array_match:
        parse_attempts.append(array_match.group(0))
    if object_match:
        parse_attempts.append(object_match.group(0))

    for attempt in parse_attempts:
        try:
            parsed = json.loads(attempt)
        except (json.JSONDecodeError, TypeError):
            continue

        final_tasks = _parse_task_list_payload(parsed)
        if final_tasks is not None:
            return final_tasks

    return None


def _safe_int(value, default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def save_tasks_for_session(user_id: str, session_id: str, final_tasks: list[dict]) -> list[dict]:
    now = datetime.now(timezone.utc)
    saved_tasks = []

    valid_tasks = [t for t in final_tasks if isinstance(t, dict)]
    for idx, task in enumerate(valid_tasks, start=1):
        task_id = f"{session_id}-{idx}"
        task_ref = db.collection("tasks").document(task_id)
        task_doc = task_ref.get()

        payload = {
            "task_id": task_id,
            "user_id": user_id,
            "session_id": session_id,
            "priority_rank": _safe_int(task.get("priority_rank"), idx),
            "task_name": task.get("task_name"),
            "category": task.get("category", "Other"),
            "estimated_time": _safe_int(task.get("estimated_time"), 0),
            "urgency": task.get("urgency"),
            "stress_level": task.get("stress_level"),
            "summary": task.get("summary"),
            "hour_of_day": now.hour,
            "day_of_week": now.weekday(),
            "estimated_subtasks": 1,
            "is_vague": False,
            "has_dependencies": False,
        }

        if not task_doc.exists:
            payload["created_at"] = now.isoformat()
            payload["completed"] = False
            task_ref.set(payload)
        else:
            task_ref.set(payload, merge=True)

        saved_tasks.append(payload)

    return saved_tasks


router = APIRouter()

class ChatMessage(BaseModel):
    session_id: str
    user_id: str
    message: str

@router.post("/chat")
async def chat(body: ChatMessage):
    # reference the session document in Firestore
    session_ref = db.collection("sessions").document(body.session_id)
    # fetches the existing session document, if it exists
    session_doc = session_ref.get()

    if session_doc.exists:
        history = session_doc.to_dict().get("history", [])
    else:
        history = []
    
    # append the new message to the history
    history.append({
        "role": "user",
        "message": body.message
    })

    try:
        raw_agent_reply = await call_prioritizer_agent(
            user_id=body.user_id,
            session_id=body.session_id,
            text=body.message,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Prioritizer agent failed: {exc}") from exc
    final_tasks = parse_final_tasks(raw_agent_reply)
    is_ready = final_tasks is not None
    agent_reply = FINAL_LIST_MESSAGE if is_ready else raw_agent_reply
    saved_tasks = save_tasks_for_session(body.user_id, body.session_id, final_tasks) if is_ready else []

    history.append({
        "role": "agent",
        "message": agent_reply
    })

    # save the updated history back to Firestore
    payload = {
        "user_id": body.user_id,
        "history": history,
        "list_ready": is_ready,
        "final_tasks": final_tasks if is_ready else None,
        "saved_tasks": saved_tasks if is_ready else [],
    }
    session_ref.set(payload)

    return {
        "session_id": body.session_id,
        "reply": agent_reply,
        "history": history,
        "list_ready": is_ready,
        "tasks": saved_tasks,
    }


@router.get("/chat/{session_id}/tasks")
async def get_final_task_list(session_id: str):
    session_ref = db.collection("sessions").document(session_id)
    session_doc = session_ref.get()

    if not session_doc.exists:
        raise HTTPException(status_code=404, detail="Session not found.")

    data = session_doc.to_dict() or {}
    if not data.get("list_ready"):
        return {
            "session_id": session_id,
            "list_ready": False,
            "tasks": [],
        }

    return {
        "session_id": session_id,
        "list_ready": True,
        "tasks": data.get("saved_tasks", []),
    }
