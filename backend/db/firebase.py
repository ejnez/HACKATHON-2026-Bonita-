import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent  # goes up from db/ to backend/
SERVICE_ACCOUNT_PATH = BASE_DIR / "serviceAccountKey.json"
cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()
