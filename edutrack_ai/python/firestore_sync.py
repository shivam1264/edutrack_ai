"""
EduTrack AI - Firestore Sync Script
Fetches all students from Firestore, runs AI predictions,
and saves results back to the ai_predictions collection.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
from datetime import datetime
from train_model import predict_student
import joblib

# ── Firebase Init ─────────────────────────────────────────────────────────────
def init_firebase():
    cred_path = os.environ.get(
        "FIREBASE_SERVICE_ACCOUNT", "service_account.json"
    )
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    return firestore.client()


# ── Compute student features from Firestore ───────────────────────────────────
def compute_student_features(db: firestore.Client, student_id: str) -> dict:
    """Compute all ML features for a student from Firestore data."""

    # Attendance rate
    attendance_docs = list(
        db.collection("attendance")
        .where("student_id", "==", student_id)
        .stream()
    )
    total = len(attendance_docs)
    present = sum(1 for d in attendance_docs
                  if d.to_dict().get("status") == "present")
    late = sum(1 for d in attendance_docs
               if d.to_dict().get("status") == "late")
    attendance_rate = ((present + late * 0.5) / total * 100) if total > 0 else 0

    # Quiz scores
    quiz_results = list(
        db.collection("quiz_results")
        .where("student_id", "==", student_id)
        .order_by("submitted_at", direction=firestore.Query.DESCENDING)
        .limit(10)
        .stream()
    )

    quiz_pct_scores = []
    for qr in quiz_results:
        d = qr.to_dict()
        score = d.get("score", 0)
        total_marks = d.get("total", 1)
        if total_marks > 0:
            quiz_pct_scores.append(score / total_marks * 100)

    avg_quiz_score = (sum(quiz_pct_scores) / len(quiz_pct_scores)
                      if quiz_pct_scores else 0)

    # Last 3 quiz trend
    last_3 = quiz_pct_scores[:3]
    if len(last_3) >= 2:
        if last_3[0] > last_3[-1] + 5:
            trend = 1   # improving
        elif last_3[0] < last_3[-1] - 5:
            trend = -1  # declining
        else:
            trend = 0   # stable
    else:
        trend = 0

    # Assignment submission rate
    submissions_raw = list(
        db.collection("submissions")
        .where("student_id", "==", student_id)
        .stream()
    )
    submissions = [s.to_dict() for s in submissions_raw]

    # Get the student's class assignments
    student_doc = db.collection("users").document(student_id).get()
    class_id = student_doc.to_dict().get("class_id", "") if student_doc.exists else ""

    total_assignments = 0
    if class_id:
        assignments_snap = list(
            db.collection("assignments")
            .where("class_id", "==", class_id)
            .stream()
        )
        total_assignments = len(assignments_snap)

    submitted_count = len(submissions)
    assignments_submitted_rate = (
        (submitted_count / total_assignments * 100)
        if total_assignments > 0 else 0
    )

    # Average submission delay
    delay_days_list = []
    for sub in submissions:
        submitted_at = sub.get("submitted_at")
        assignment_id = sub.get("assignment_id", "")
        if submitted_at and assignment_id:
            assign_doc = db.collection("assignments").document(assignment_id).get()
            if assign_doc.exists:
                due_date = assign_doc.to_dict().get("due_date")
                if due_date:
                    delay = (submitted_at.timestamp() - due_date.timestamp()) / 86400
                    delay_days_list.append(max(0, delay))

    avg_delay = (sum(delay_days_list) / len(delay_days_list)
                 if delay_days_list else 0)

    # Subject scores from graded submissions
    subject_scores = {}
    for sub in submissions:
        marks = sub.get("marks")
        if marks is not None:
            assign_id = sub.get("assignment_id", "")
            assign_doc = db.collection("assignments").document(assign_id).get()
            if assign_doc.exists:
                subject = assign_doc.to_dict().get("subject", "Other")
                max_marks = assign_doc.to_dict().get("max_marks", 100)
                pct = (marks / max_marks * 100) if max_marks > 0 else 0
                subject_scores.setdefault(subject, []).append(pct)

    subject_avg = {k: sum(v) / len(v) for k, v in subject_scores.items()}

    return {
        "attendance_rate": round(attendance_rate, 2),
        "avg_quiz_score": round(avg_quiz_score, 2),
        "assignments_submitted_rate": round(assignments_submitted_rate, 2),
        "avg_submission_delay_days": round(avg_delay, 2),
        "last_3_quiz_trend": trend,
        "subject_scores": subject_avg,
    }


# ── Main Sync Function ────────────────────────────────────────────────────────
def sync_predictions():
    print("🔄 EduTrack AI - Firestore Sync Starting...")
    db = init_firebase()

    model_path = os.path.join(os.path.dirname(__file__), "models", "model.pkl")
    model = joblib.load(model_path)
    print("✅ Model loaded")

    # Fetch all students
    students = list(
        db.collection("users")
        .where("role", "==", "student")
        .stream()
    )
    print(f"📚 Found {len(students)} students")

    success_count = 0
    error_count = 0

    for student_snap in students:
        student_id = student_snap.id
        student_data = student_snap.to_dict()
        name = student_data.get("name", "Unknown")

        try:
            print(f"  → Processing: {name} ({student_id})")

            # Compute features
            features = compute_student_features(db, student_id)

            # Predict
            prediction = predict_student(features, model)

            # Save to Firestore
            db.collection("ai_predictions").document(student_id).set({
                "student_id": student_id,
                "attendance_rate": features["attendance_rate"],
                "avg_quiz_score": features["avg_quiz_score"],
                "assignments_submitted_rate": features["assignments_submitted_rate"],
                "avg_submission_delay_days": features["avg_submission_delay_days"],
                "last_3_quiz_trend": features["last_3_quiz_trend"],
                "predicted_final_grade": prediction["predicted_final_grade"],
                "risk_level": prediction["risk_level"],
                "weak_subjects": prediction["weak_subjects"],
                "updated_at": firestore.SERVER_TIMESTAMP,
            })

            success_count += 1
            print(f"    ✅ Grade: {prediction['predicted_final_grade']:.1f}% | Risk: {prediction['risk_level']}")

        except Exception as e:
            error_count += 1
            print(f"    ❌ Error: {e}")

    print(f"\n🏁 Sync complete: {success_count} updated, {error_count} errors")


if __name__ == "__main__":
    sync_predictions()
