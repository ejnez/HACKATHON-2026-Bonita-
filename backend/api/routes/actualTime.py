from datetime import datetime, timezone
from threading import Lock

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from agents.prioritizer import agent as prioritizer_agent
from agents.prioritizer.predicttime import save as save_time_model
from db.firebase import db

router = APIRouter()
MODEL_UPDATE_LOCK = Lock()

class CompleteTaskRequest(BaseModel):
    task_id: str
    user_id: str
    actual_time_spent_minutes: int = Field(gt=0)


def _to_iso(value):
    return value.isoformat() if hasattr(value, "isoformat") else value


def _parse_iso_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _require_task(task_id: str):
    task_ref = db.collection("tasks").document(task_id)
    task_doc = task_ref.get()
    if not task_doc.exists:
        raise HTTPException(status_code=404, detail="Task not found.")
    return task_ref, (task_doc.to_dict() or {})


@router.get("/tasks/{user_id}")
async def get_tasks(user_id: str):
    docs = db.collection("tasks").where("user_id", "==", user_id).stream()
    tasks = []

    for doc in docs:
        data = doc.to_dict() or {}
        tasks.append({
            "task_id": doc.id,
            "user_id": data.get("user_id"),
            "session_id": data.get("session_id"),
            "priority_rank": data.get("priority_rank"),
            "task_name": data.get("task_name"),
            "category": data.get("category"),
            "estimated_time": data.get("estimated_time"),
            "actual_time_spent_minutes": data.get("actual_time_spent_minutes"),
            "time_spent_seconds": int(data.get("time_spent_seconds") or 0),
            "time_spent_minutes": int(data.get("time_spent_minutes") or 0),
            "timer_started_at": data.get("timer_started_at"),
            "is_active": bool(data.get("is_active", False)),
            "urgency": data.get("urgency"),
            "stress_level": data.get("stress_level"),
            "summary": data.get("summary"),
            "completed": bool(data.get("completed", False)),
            "created_at": _to_iso(data.get("created_at")),
            "completed_at": _to_iso(data.get("completed_at")),
        })

    tasks.sort(
        key=lambda t: (
            t["completed"],
            t["priority_rank"] if isinstance(t["priority_rank"], int) else 10**9,
        )
    )

    return {
        "user_id": user_id,
        "count": len(tasks),
        "tasks": tasks,
    }


@router.post("/tasks/{task_id}/timer/start")
async def start_task_timer(task_id: str):
    task_ref, task_data = _require_task(task_id)
    if task_data.get("completed"):
        raise HTTPException(status_code=400, detail="Completed task timer cannot be started.")

    now_iso = datetime.now(timezone.utc).isoformat()
    task_ref.update({
        "timer_started_at": now_iso,
        "is_active": True,
    })

    return {
        "task_id": task_id,
        "timer_started_at": now_iso,
        "is_active": True,
        "time_spent_seconds": int(task_data.get("time_spent_seconds") or 0),
        "time_spent_minutes": int(task_data.get("time_spent_minutes") or 0),
    }


@router.post("/tasks/{task_id}/timer/pause")
async def pause_task_timer(task_id: str):
    task_ref, task_data = _require_task(task_id)
    started_at = _parse_iso_datetime(task_data.get("timer_started_at"))
    if not task_data.get("is_active") or started_at is None:
        # idempotent pause
        task_ref.update({
            "timer_started_at": None,
            "is_active": False,
        })
        return {
            "task_id": task_id,
            "elapsed_seconds_added": 0,
            "elapsed_minutes_added": 0,
            "time_spent_seconds": int(task_data.get("time_spent_seconds") or 0),
            "time_spent_minutes": int(task_data.get("time_spent_minutes") or 0),
            "is_active": False,
        }

    elapsed_seconds = max(0, int((datetime.now(timezone.utc) - started_at).total_seconds()))
    new_total_seconds = int(task_data.get("time_spent_seconds") or 0) + elapsed_seconds
    new_total_minutes = new_total_seconds // 60
    task_ref.update({
        "time_spent_seconds": new_total_seconds,
        "time_spent_minutes": new_total_minutes,
        "timer_started_at": None,
        "is_active": False,
    })

    return {
        "task_id": task_id,
        "elapsed_seconds_added": elapsed_seconds,
        "elapsed_minutes_added": elapsed_seconds // 60,
        "time_spent_seconds": new_total_seconds,
        "time_spent_minutes": new_total_minutes,
        "is_active": False,
    }


@router.post("/tasks/{task_id}/timer/resume")
async def resume_task_timer(task_id: str):
    task_ref, task_data = _require_task(task_id)
    if task_data.get("completed"):
        raise HTTPException(status_code=400, detail="Completed task timer cannot be resumed.")

    now_iso = datetime.now(timezone.utc).isoformat()
    task_ref.update({
        "timer_started_at": now_iso,
        "is_active": True,
    })

    return {
        "task_id": task_id,
        "timer_started_at": now_iso,
        "is_active": True,
        "time_spent_seconds": int(task_data.get("time_spent_seconds") or 0),
        "time_spent_minutes": int(task_data.get("time_spent_minutes") or 0),
    }


@router.post("/tasks/complete")
async def complete_task(body: CompleteTaskRequest):
    # fetch the task from tasks collection
    task_ref = db.collection("tasks").document(body.task_id)
    task_doc = task_ref.get()

    if not task_doc.exists:
        raise HTTPException(status_code=404, detail="Task not found.")

    task_data = task_doc.to_dict()
    if task_data.get("user_id") != body.user_id:
        raise HTTPException(status_code=403, detail="Task does not belong to this user.")

    if task_data.get("completed"):
        completed_doc = db.collection("completed_tasks").document(body.task_id).get()
        if completed_doc.exists:
            completed_task = completed_doc.to_dict() or {}
        else:
            completed_task = {
                "task_id": body.task_id,
                "user_id": body.user_id,
                "task_name": task_data.get("task_name"),
                "category": task_data.get("category"),
                "actual_time_spent_minutes": task_data.get("actual_time_spent_minutes"),
                "estimated_time": task_data.get("estimated_time"),
                "completed_at": task_data.get("completed_at"),
            }
        return {
            "task_id": body.task_id,
            "completed_task": completed_task
        }

    now = datetime.now(timezone.utc)

    # mark task as completed in tasks collection
    task_ref.update({
        "completed": True,
        "completed_at": now.isoformat(),
        "actual_time_spent_minutes": body.actual_time_spent_minutes,
        "time_spent_seconds": body.actual_time_spent_minutes * 60,
        "time_spent_minutes": body.actual_time_spent_minutes,
        "timer_started_at": None,
        "is_active": False,
    })

    # update online model using completion feedback
    features = {
        "category": task_data.get("category", "Other"),
        "hour_of_day": int(task_data.get("hour_of_day", now.hour)),
        "day_of_week": int(task_data.get("day_of_week", now.weekday())),
        "estimated_subtasks": int(task_data.get("estimated_subtasks", 1)),
        "is_vague": bool(task_data.get("is_vague", False)),
        "has_dependencies": bool(task_data.get("has_dependencies", False)),
    }
    with MODEL_UPDATE_LOCK:
        prioritizer_agent._time_model.learn(features, float(body.actual_time_spent_minutes))
        save_time_model(prioritizer_agent._time_model)

    # write to completed_tasks collection
    completed_task = {
        "task_id": body.task_id,
        "user_id": body.user_id,
        "task_name": task_data.get("task_name"),
        "category": task_data.get("category"),
        "actual_time_spent_minutes": body.actual_time_spent_minutes,
        "estimated_time": task_data.get("estimated_time"),
        "completed_at": now.isoformat()
    }
    db.collection("completed_tasks").document(body.task_id).set(completed_task)
    db.collection("model_training_events").add({
        "task_id": body.task_id,
        "user_id": body.user_id,
        "features": features,
        "actual_time_spent_minutes": body.actual_time_spent_minutes,
        "estimated_time": task_data.get("estimated_time"),
        "created_at": now.isoformat(),
    })

    return {
        "task_id": body.task_id,
        "completed_task": completed_task
    }
