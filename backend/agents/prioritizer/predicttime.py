from river import compose, preprocessing, linear_model, optim, metrics
import pickle
import math
from pathlib import Path

MODEL_PATH = Path("backend/agents/prioritizer/time_model.pkl")
MIN_TRAINING_SAMPLES = 30
CONFIDENCE_THRESHOLD = 0.7
MIN_PREDICTED_MINUTES = 5.0
CATEGORY_TO_ID = {
    "Personal Errands": 0.0,
    "Health and Fitness": 1.0,
    "Social": 2.0,
    "Learning": 3.0,
    "House Chore": 4.0,
    "School Work": 5.0,
    "Work Related": 6.0,
    "Other": 7.0,
}

class OnlineTimeModel:
    def __init__(self):
        self.model = compose.Pipeline(
            preprocessing.StandardScaler(),
            linear_model.LinearRegression(optimizer=optim.SGD(0.01))
        )
        self.mae = metrics.MAE()   # running error for confidence
        self.n = 0

    # x is the dict with task features, y is the actual time taken in minutes
    def predict(self, x: dict) -> dict:
        x = _normalize_features(x)
        try:
            y_hat = self.model.predict_one(x)
        except Exception:
            return {
                "predicted_minutes": None,
                "confidence": 0.0,
                "reason": "no_estimate",
            }

        # If we do not have a usable prediction, return no estimate so the agent asks the user.
        if y_hat is None or not math.isfinite(y_hat):
            return {
                "predicted_minutes": None,
                "confidence": 0.0,
                "reason": "no_estimate",
            }
        y_hat = max(float(y_hat), MIN_PREDICTED_MINUTES)

        # confidence is based on the running MAE error, scaled to the predicted value (with a floor to avoid overconfidence on very low predictions)
        err = self.mae.get() if self.n > 20 else 20.0
        # confidence is 1.0 if err is 0, and approaches 0.0 as err approaches or exceeds y_hat (with a floor to avoid overconfidence on very low predictions)
        confidence = max(0.0, min(1.0, 1.0 - (err / max(y_hat, 15.0))))

        # if we have very little training data, or if confidence is low, we return no estimate with the confidence and reason
        if self.n < MIN_TRAINING_SAMPLES:
            return {
                "predicted_minutes": None,
                "confidence": float(confidence),
                "reason": "insufficient_training_data",
            }

        # if confidence is low, we return no estimate with the confidence and reason
        if confidence < CONFIDENCE_THRESHOLD:
            return {
                "predicted_minutes": None,
                "confidence": float(confidence),
                "reason": "low_confidence",
            }

        # if we have a prediction and confidence is sufficient, we return the prediction with the confidence and reason
        return {
            "predicted_minutes": float(y_hat),
            "confidence": float(confidence),
            "reason": "model_prediction",
        }

    def learn(self, x: dict, y: float):
        if y is None or not math.isfinite(y) or y <= 0:
            return
        x = _normalize_features(x)
        y = max(float(y), MIN_PREDICTED_MINUTES)
        try:
            y_hat = self.model.predict_one(x) or 45.0
        except Exception:
            y_hat = 45.0
        if not math.isfinite(y_hat):
            y_hat = 45.0
        y_hat = max(float(y_hat), MIN_PREDICTED_MINUTES)
        self.mae.update(y, y_hat)
        try:
            self.model.learn_one(x, y)
        except Exception:
            return
        self.n += 1


def _to_int(value, default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _to_bool(value) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "y"}
    return False


def _normalize_features(x: dict) -> dict:
    category_raw = str((x or {}).get("category", "Other")).strip()
    category_id = CATEGORY_TO_ID.get(category_raw, CATEGORY_TO_ID["Other"])
    hour_of_day = max(0, min(23, _to_int((x or {}).get("hour_of_day"), 12)))
    day_of_week = max(0, min(6, _to_int((x or {}).get("day_of_week"), 0)))
    estimated_subtasks = max(1, _to_int((x or {}).get("estimated_subtasks"), 1))
    is_vague = 1.0 if _to_bool((x or {}).get("is_vague")) else 0.0
    has_dependencies = 1.0 if _to_bool((x or {}).get("has_dependencies")) else 0.0

    return {
        "category_id": category_id,
        "hour_of_day": float(hour_of_day),
        "day_of_week": float(day_of_week),
        "estimated_subtasks": float(estimated_subtasks),
        "is_vague": is_vague,
        "has_dependencies": has_dependencies,
    }

def load_or_create():
    if MODEL_PATH.exists():
        with open(MODEL_PATH, "rb") as f:
            return pickle.load(f)
    return OnlineTimeModel()

def save(m):
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(m, f)
