import json
import re
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from agents.floweragent.agent import root_agent
from db.firebase import db
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

APP_NAME = "bonita-flower-award"
session_service = InMemorySessionService()
runner = Runner(agent=root_agent, app_name=APP_NAME, session_service=session_service)

router = APIRouter()


class AwardRequest(BaseModel):
    task_id: str
    user_id: str


async def call_flower_agent(user_id: str, session_id: str, text: str) -> str:
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
    return reply or ""


def parse_single_flower(reply: str) -> str | None:
    try:
        cleaned = (
            reply.strip()
            .removeprefix("```json")
            .removeprefix("```")
            .removesuffix("```")
            .strip()
        )
        parsed = json.loads(cleaned)
    except (json.JSONDecodeError, TypeError):
        plain = reply.strip().strip('"').strip("'")
        return plain if plain else None

    if isinstance(parsed, list) and parsed:
        first = parsed[0]
        return first if isinstance(first, str) else None

    if isinstance(parsed, str):
        return parsed

    return None


def normalize_flower_id(value: str) -> str:
    cleaned = value.strip().lower().replace("-", "_").replace(" ", "_")
    return re.sub(r"[^a-z0-9_]", "", cleaned)


@router.post("/flowers/award")
async def award_flowers(body: AwardRequest):
    completed_ref = db.collection("completed_tasks").document(body.task_id)
    completed_doc = completed_ref.get()

    if not completed_doc.exists:
        raise HTTPException(status_code=404, detail="Completed task not found.")

    completed = completed_doc.to_dict() or {}
    if completed.get("user_id") != body.user_id:
        raise HTTPException(status_code=403, detail="Task does not belong to this user.")

    task_doc = db.collection("tasks").document(body.task_id).get()
    if not task_doc.exists:
        raise HTTPException(status_code=404, detail="Original task not found.")
    task = task_doc.to_dict() or {}

    task_payload = {
        "task_id": body.task_id,
        "task_name": task.get("task_name"),
        "category": task.get("category"),
        "priority_rank": task.get("priority_rank"),
        "urgency": task.get("urgency"),
        "stress_level": task.get("stress_level"),
        "summary": task.get("summary"),
        "estimated_time": task.get("estimated_time"),
        "actual_time_spent_minutes": completed.get("actual_time_spent_minutes"),
        "created_at": str(task.get("created_at")),
        "completed_at": str(completed.get("completed_at")),
        "paused_count": task.get("paused_count", 0),
        "timer_cycle": task.get("timer_cycle"),
    }

    flower_docs = list(db.collection("flower_types").stream())
    valid_ids = {doc.id for doc in flower_docs}
    normalized_to_id = {normalize_flower_id(fid): fid for fid in valid_ids}
    flower_catalog = "\n".join(
        [f"- {doc.id}: {doc.to_dict().get('condition', '')}" for doc in flower_docs]
    )

    prompt = f"""
You are deciding which single flower a user has earned for completing a task.

TASK DETAILS:
{json.dumps(task_payload, indent=2, default=str)}

AVAILABLE FLOWERS AND THEIR CONDITIONS:
{flower_catalog}

Pick exactly ONE flower that best matches this task. Use this priority order when multiple conditions apply:
1. Category-based flowers (e.g. zinnia) - most specific to what the task was
2. Time-based flowers (forget_me_not, daffodil, marigold) - based on effort
3. Behavior-based flowers (begonia, poppy) - based on how they worked
4. Status-based flowers (snapdragon, dahlia, geranium) - fallback

Return ONLY a JSON string with the single flower_type_id.
Example: "marigold"
Do not return a list. Do not include any explanation. Just the flower_type_id as a JSON string.
"""

    raw_reply = await call_flower_agent(
        user_id=body.user_id,
        session_id=f"award-{body.task_id}",
        text=prompt,
    )
    flower = parse_single_flower(raw_reply)
    normalized_flower = normalize_flower_id(flower) if flower else None
    if not normalized_flower:
        raise HTTPException(status_code=422, detail=f"Agent returned invalid flower: '{flower}'")

    if normalized_to_id:
        flower_id = normalized_to_id.get(normalized_flower)
        if not flower_id:
            raise HTTPException(status_code=422, detail=f"Agent returned invalid flower: '{flower}'")
    else:
        flower_id = normalized_flower

    completed_ref.update(
        {
            "flower_awarded": flower_id,
            "awarded_at": datetime.now(timezone.utc).isoformat(),
        }
    )

    return {
        "task_id": body.task_id,
        "user_id": body.user_id,
        "flower": flower_id,
    }
