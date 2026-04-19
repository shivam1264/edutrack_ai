"""
EduTrack AI - ML Grade Prediction Model
Train Random Forest Regressor to predict student final grade and risk level.
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.preprocessing import StandardScaler
import joblib
import json
import os

# ── Reproducibility ───────────────────────────────────────────────────────────
np.random.seed(42)


def generate_training_data(n_students: int = 500) -> pd.DataFrame:
    """Generate synthetic training data with realistic patterns."""
    data = []

    for _ in range(n_students):
        attendance_rate = np.clip(np.random.normal(75, 18), 0, 100)
        avg_quiz_score = np.clip(np.random.normal(65, 20), 0, 100)
        assignments_submitted_rate = np.clip(
            np.random.normal(70, 22), 0, 100
        )
        avg_submission_delay = np.clip(np.random.exponential(2), 0, 14)

        # Trend: correlated with current quiz scores
        if avg_quiz_score > 70:
            trend = np.random.choice([1, 0], p=[0.65, 0.35])
        elif avg_quiz_score > 50:
            trend = np.random.choice([1, 0, -1], p=[0.3, 0.4, 0.3])
        else:
            trend = np.random.choice([0, -1], p=[0.35, 0.65])

        # Final grade formula (realistic)
        final_grade = (
            0.30 * attendance_rate
            + 0.35 * avg_quiz_score
            + 0.25 * assignments_submitted_rate
            - 2.0 * avg_submission_delay
            + 5.0 * trend
            + np.random.normal(0, 5)   # noise
        )
        final_grade = np.clip(final_grade, 0, 100)

        data.append({
            "attendance_rate": round(attendance_rate, 2),
            "avg_quiz_score": round(avg_quiz_score, 2),
            "assignments_submitted_rate": round(assignments_submitted_rate, 2),
            "avg_submission_delay_days": round(avg_submission_delay, 2),
            "last_3_quiz_trend": int(trend),
            "predicted_final_grade": round(final_grade, 2),
        })

    return pd.DataFrame(data)


def classify_risk(grade: float) -> str:
    if grade >= 70:
        return "low"
    elif grade >= 50:
        return "medium"
    else:
        return "high"


def identify_weak_subjects(student_data: dict) -> list[str]:
    """Identify weak subjects based on score thresholds."""
    weak = []
    subject_scores = student_data.get("subject_scores", {})
    for subject, score in subject_scores.items():
        if score < 60:
            weak.append(subject)
    return weak


def train_model():
    print("📊 Generating training data...")
    df = generate_training_data(500)

    features = [
        "attendance_rate",
        "avg_quiz_score",
        "assignments_submitted_rate",
        "avg_submission_delay_days",
        "last_3_quiz_trend",
    ]
    X = df[features]
    y = df["predicted_final_grade"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    print("🌲 Training Random Forest Regressor...")
    model = RandomForestRegressor(
        n_estimators=200,
        max_depth=10,
        min_samples_split=5,
        random_state=42,
        n_jobs=-1,
    )
    model.fit(X_train, y_train)

    # ── Evaluate ──────────────────────────────────────────────────────────────
    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)

    print(f"\n✅ Model Evaluation:")
    print(f"   MAE  : {mae:.2f}")
    print(f"   R²   : {r2:.4f}")
    print(f"   Score: {model.score(X_test, y_test):.4f}")

    # Feature importances
    importance = dict(zip(features, model.feature_importances_))
    print(f"\n📌 Feature Importances:")
    for k, v in sorted(importance.items(), key=lambda x: -x[1]):
        print(f"   {k}: {v:.4f}")

    # Save model
    os.makedirs("models", exist_ok=True)
    joblib.dump(model, "models/model.pkl")
    print("\n💾 Model saved to models/model.pkl")

    return model


def predict_student(student_data_dict: dict, model=None) -> dict:
    """
    Predict grade and risk level for a single student.

    Args:
        student_data_dict: {
            attendance_rate: float,
            avg_quiz_score: float,
            assignments_submitted_rate: float,
            avg_submission_delay_days: float,
            last_3_quiz_trend: int,  # 1, 0, or -1
            subject_scores: {subject: score}  # optional
        }
    Returns:
        {predicted_final_grade, risk_level, weak_subjects}
    """
    if model is None:
        model = joblib.load("models/model.pkl")

    features = np.array([[
        float(student_data_dict.get("attendance_rate", 75)),
        float(student_data_dict.get("avg_quiz_score", 60)),
        float(student_data_dict.get("assignments_submitted_rate", 70)),
        float(student_data_dict.get("avg_submission_delay_days", 2)),
        int(student_data_dict.get("last_3_quiz_trend", 0)),
    ]])

    predicted_grade = float(np.clip(model.predict(features)[0], 0, 100))
    risk_level = classify_risk(predicted_grade)
    weak_subjects = identify_weak_subjects(student_data_dict)

    return {
        "predicted_final_grade": round(predicted_grade, 2),
        "risk_level": risk_level,
        "weak_subjects": weak_subjects,
    }


if __name__ == "__main__":
    model = train_model()

    # Test prediction
    sample_student = {
        "attendance_rate": 65.0,
        "avg_quiz_score": 52.0,
        "assignments_submitted_rate": 60.0,
        "avg_submission_delay_days": 3.5,
        "last_3_quiz_trend": -1,
        "subject_scores": {
            "Mathematics": 48,
            "Science": 55,
            "English": 72,
        },
    }

    print("\n🔮 Sample Prediction:")
    result = predict_student(sample_student, model)
    print(json.dumps(result, indent=2))
