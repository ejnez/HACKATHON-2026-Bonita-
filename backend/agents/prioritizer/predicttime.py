from river import compose, preprocessing, linear_model, optim, metrics
import pickle
import math
from pathlib import Path

MODEL_PATH = Path("backend/agents/prioritizer/time_model.pkl")
MIN_TRAINING_SAMPLES = 30
CONFIDENCE_THRESHOLD = 0.7
MIN_PREDICTED_MINUTES = 5.0

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
        y_hat = self.model.predict_one(x)

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
        y = max(float(y), MIN_PREDICTED_MINUTES)
        y_hat = self.model.predict_one(x) or 45.0
        if not math.isfinite(y_hat):
            y_hat = 45.0
        y_hat = max(float(y_hat), MIN_PREDICTED_MINUTES)
        self.mae.update(y, y_hat)
        self.model.learn_one(x, y)
        self.n += 1

def load_or_create():
    if MODEL_PATH.exists():
        with open(MODEL_PATH, "rb") as f:
            return pickle.load(f)
    return OnlineTimeModel()

def save(m):
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(m, f)
