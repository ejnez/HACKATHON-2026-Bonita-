import json
from datetime import datetime, timedelta, timezone

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


def dt_to_iso(value):
    return value.isoformat() if hasattr(value, "isoformat") else value


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
            reply = "".join(p.text for p in event.content.parts if getattr(p, "text", None))
            break
    return reply or ""


def parse_award_response(reply: str) -> dict | None:
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
        return None

    if not isinstance(parsed, dict):
        return None

    selected_flower = parsed.get("selected_flower")
    tier = parsed.get("tier")
    congrats_message = parsed.get("congrats_message")
    if not all(isinstance(v, str) and v.strip() for v in [selected_flower, tier, congrats_message]):
        return None

    return {
        "selected_flower": selected_flower.strip(),
        "tier": tier.strip().upper(),
        "congrats_message": congrats_message.strip(),
    }


# ---------------------------------------------------------------------------
# POST /flowers/award
# Called after a task is completed. Asks the agent which flower to give,
# then writes one document to the flowers collection.
# ---------------------------------------------------------------------------
@router.post("/flowers/award")
async def award_flowers(body: AwardRequest):
    # fetch completed_tasks record
    completed_doc = db.collection("completed_tasks").document(body.task_id).get()
    if not completed_doc.exists:
        raise HTTPException(status_code=404, detail="Completed task not found.")

    completed = completed_doc.to_dict() or {}
    if completed.get("user_id") != body.user_id:
        raise HTTPException(status_code=403, detail="Task does not belong to this user.")

    # fetch original task for full context
    task_doc = db.collection("tasks").document(body.task_id).get()
    if not task_doc.exists:
        raise HTTPException(status_code=404, detail="Original task not found.")
    task = task_doc.to_dict() or {}

    # build task payload for agent
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
        "paused_count": task.get("paused_count", 0),
        "timer_cycle": task.get("timer_cycle"),
        "created_at": str(task.get("created_at")),
        "completed_at": str(completed.get("completed_at")),
    }

    # call agent
    raw_reply = await call_flower_agent(
        user_id=body.user_id,
        session_id=f"award-{body.task_id}",
        text=json.dumps(task_payload),
    )
    award = parse_award_response(raw_reply)
    if not award:
        raise HTTPException(status_code=422, detail="Agent did not return valid flower award JSON.")

    valid_tiers = {"EXCELLENT", "MEDIUM", "SMALL", "MICRO"}
    if award["tier"] not in valid_tiers:
        raise HTTPException(status_code=422, detail=f"Invalid tier from agent: {award['tier']}")

    # write to flowers collection
    awarded_at = datetime.now(timezone.utc)
    db.collection("flowers").document(body.task_id).set({
        "task_id": body.task_id,
        "user_id": body.user_id,
        "flower_type_id": award["selected_flower"],
        "tier": award["tier"],
        "message": award["congrats_message"],
        "earned_at": awarded_at,
    })

    return {
        "task_id": body.task_id,
        "user_id": body.user_id,
        "selected_flower": award["selected_flower"],
        "tier": award["tier"],
        "congrats_message": award["congrats_message"],
        "earned_at": awarded_at.isoformat(),
    }


# ---------------------------------------------------------------------------
# GET /flowers/bouquet/{user_id}
# Returns all flowers earned today for the given user.
# ---------------------------------------------------------------------------
@router.get("/flowers/bouquet/{user_id}")
async def get_active_bouquet(user_id: str):
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    tomorrow_start = today_start + timedelta(days=1)

    docs = (
        db.collection("flowers")
        .where("user_id", "==", user_id)
        .where("earned_at", ">=", today_start)
        .where("earned_at", "<", tomorrow_start)
        .stream()
    )

    flowers = []
    for doc in docs:
        data = doc.to_dict() or {}
        flowers.append({
            "flower_id": doc.id,
            "task_id": data.get("task_id"),
            "flower_type_id": data.get("flower_type_id"),
            "tier": data.get("tier"),
            "message": data.get("message"),
            "earned_at": dt_to_iso(data.get("earned_at")),
        })

    return {
        "user_id": user_id,
        "date": today_start.date().isoformat(),
        "flowers": flowers,
    }


# ---------------------------------------------------------------------------
# GET /flowers/trophy-room/{user_id}
# Returns all flowers ever earned, grouped by date, newest first.
# ---------------------------------------------------------------------------
@router.get("/flowers/trophy-room/{user_id}")
async def get_trophy_room(user_id: str):
    docs = (
        db.collection("flowers")
        .where("user_id", "==", user_id)
        .stream()
    )

    by_date = {}
    for doc in docs:
        data = doc.to_dict() or {}
        earned_at = data.get("earned_at")

        if hasattr(earned_at, "date"):
            date_str = earned_at.date().isoformat()
        else:
            date_str = str(earned_at)[:10]

        if date_str not in by_date:
            by_date[date_str] = []

        by_date[date_str].append({
            "flower_id": doc.id,
            "task_id": data.get("task_id"),
            "flower_type_id": data.get("flower_type_id"),
            "tier": data.get("tier"),
            "message": data.get("message"),
            "earned_at": dt_to_iso(earned_at),
        })

    bouquets = [
        {"date": date, "flowers": flowers}
        for date, flowers in sorted(by_date.items(), reverse=True)
    ]

    return {
        "user_id": user_id,
        "bouquets": bouquets,
    }