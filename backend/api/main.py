from dotenv import load_dotenv
from pathlib import Path
from fastapi import FastAPI

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / "agents" / "prioritizer" / ".env")

from api.routes.chat import router as chat_router
from api.routes.actualTime import router as complete_task_router
from api.routes.flowers.award import router as flower_award_router

app = FastAPI()
app.include_router(chat_router)
app.include_router(complete_task_router)
app.include_router(flower_award_router)


@app.get("/")
async def root():
    return {"message": "Hello World"}
