import json

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


def parse_final_tasks(reply: str):
    try:
        cleaned = reply.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
        parsed = json.loads(cleaned)
    except (json.JSONDecodeError, TypeError):
        return None

    if isinstance(parsed, list):
        return parsed
    return None


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

    raw_agent_reply = await call_prioritizer_agent(
        user_id=body.user_id,
        session_id=body.session_id,
        text=body.message,
    )
    final_tasks = parse_final_tasks(raw_agent_reply)
    is_ready = final_tasks is not None
    agent_reply = FINAL_LIST_MESSAGE if is_ready else raw_agent_reply

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
    }
    session_ref.set(payload)

    return {
        "session_id": body.session_id,
        "reply": agent_reply,
        "history": history,
        "list_ready": is_ready,
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
        "tasks": data.get("final_tasks", []),
    }
