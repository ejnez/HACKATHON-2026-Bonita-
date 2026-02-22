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
