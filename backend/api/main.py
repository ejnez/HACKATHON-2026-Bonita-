from dotenv import load_dotenv
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / "agents" / "prioritizer" / ".env")

from api.routes.chat import router as chat_router
from api.routes.actualTime import router as complete_task_router
from api.routes.flowers.award import router as flower_award_router

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(chat_router)
app.include_router(complete_task_router)
app.include_router(flower_award_router)


@app.get("/")
async def root():
    return {"message": "Hello World"}
