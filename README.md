# HACKATHON-2026-Bonita-

Unfurl is an AI-powered productivity app that unfurls messy thoughts into actionable tasks, stay focused with a guided timer, and earn flower rewards for completed work.

# Features:
* Brain-dump chat - converts raw thoughts into a prioritized task list
* Focus mode with start/pause/resume timer flow
* Backend-tracked cumulative focus time per task
* Flower rewards after task completion (tier-based)
* Daily flower streak tracking (consecutive-day motivation)
* Bouquet view of earned flowers
# Project Structure:
* backend/ FastAPI API, AI agents, Firestore integration
* unfurl/ Flutter client app (web/desktop/mobile capable)
# Tech Stack
### Frontend: 
* Flutter
* Dart
* http
* flutter_svg
### Backend:
* FastAPI, Python, Firebase Firestore, Google ADK agents
* Data: Firestore collections for tasks, sessions, completed tasks, flowers, training events
# Main User Flow
1. User submits a brain dump in chat
2. AI prioritizer returns structured tasks
3. Tasks are saved and shown in task list
4. User starts focus session on a task
5. Timer state is tracked (frontend UI + backend cumulative truth)
6. User completes task
7. Flower agent awards a flower
8. Streak is updated if user earned at least one flower that day
### Backend API (Core)
* Chat / Task Generation
* POST /chat
* GET /chat/{session_id}/tasks
* Tasks / Timer / Completion
* GET /tasks/{user_id}
* POST /tasks/{task_id}/timer/start
* POST /tasks/{task_id}/timer/pause
* POST /tasks/{task_id}/timer/resume
* POST /tasks/complete
* Flowers / Streak
* POST /flowers/award
* GET /flowers/bouquet/{user_id}
* GET /flowers/trophy-room/{user_id}
* GET /flowers/streak/{user_id}
# Setup
### Backend:
From repo root:

pip install -r requirements.txt
Ensure these files are configured:

serviceAccountKey.json
backend/agents/prioritizer/.env
backend/agents/floweragent/.env
Run backend:

uvicorn backend.api.main:app --reload --port 8000
### Frontend:
cd unfurl
flutter pub get
Run app:

flutter run -d chrome
or:

flutter run -d windows
### Environment Notes
If Windows desktop build fails with Firebase linker/toolchain errors, use VS Build Tools 2022 (MSVC v143), then run:
flutter clean
flutter pub get
flutter run -d windows
If needed during setup, use web target (-d chrome) as fallback.
Branding
The app name is Unfurl.
App icon asset is at:

unfurl_icon.png
### Status
This project includes working flows for:

AI task generation
Focus timing lifecycle
Completion + flower awarding
Flower streak tracking and display
