// EduTrack AI - Firebase Cloud Functions
// Auto-trigger notifications: attendance, grade drops, assignments, quizzes, AI risk

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ── Helper: Send FCM + Save to Notifications ──────────────────────────────────
async function sendNotification({ userId, title, body, type, data = {} }) {
  try {
    // Get user's FCM token
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const fcmToken = userData.fcm_token;

    // Save to Firestore notifications collection
    await db.collection("notifications").add({
      user_id: userId,
      title,
      body,
      type,
      data,
      is_read: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send FCM push
    if (fcmToken) {
      await messaging.send({
        token: fcmToken,
        notification: { title, body },
        data: { type, ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        )},
        android: {
          priority: "high",
          notification: { channel_id: "edutrack_channel" },
        },
        apns: {
          payload: { aps: { badge: 1, sound: "default" } },
        },
      });
    }

    console.log(`✅ Notification sent to ${userId}: ${title}`);
  } catch (error) {
    console.error(`❌ Failed to notify ${userId}:`, error);
  }
}

// ── Helper: Get Parent of Student ─────────────────────────────────────────────
async function getParentId(studentId) {
  const snap = await db.collection("users")
    .where("role", "==", "parent")
    .where("parent_of", "==", studentId)
    .limit(1)
    .get();
  return snap.empty ? null : snap.docs[0].id;
}

// ── 1. onAttendanceAbsent ─────────────────────────────────────────────────────
exports.onAttendanceCreated = functions.firestore
  .document("attendance/{docId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const { student_id, status, date } = data;

    if (status !== "absent") return null;

    // Get student info
    const studentDoc = await db.collection("users").doc(student_id).get();
    const studentName = studentDoc.data()?.name || "Your child";

    // Format date
    const dateObj = date.toDate();
    const dateStr = dateObj.toLocaleDateString("en-IN");

    // Notify parent
    const parentId = await getParentId(student_id);
    if (parentId) {
      await sendNotification({
        userId: parentId,
        title: "⚠️ Attendance Alert",
        body: `${studentName} was marked Absent on ${dateStr}.`,
        type: "attendance",
        data: { student_id, date: dateStr, status: "absent" },
      });
    }

    // Also notify student
    await sendNotification({
      userId: student_id,
      title: "📅 Attendance Recorded",
      body: `You were marked Absent on ${dateStr}. Contact your teacher if this is incorrect.`,
      type: "attendance",
      data: { date: dateStr, status: "absent" },
    });

    return null;
  });

// ── 2. onGradeDrop ────────────────────────────────────────────────────────────
exports.onQuizResultCreated = functions.firestore
  .document("quiz_results/{resultId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const { student_id, score, total, quiz_id } = data;

    if (!total || total === 0) return null;
    const percentage = (score / total) * 100;

    if (percentage >= 60) return null; // Only notify for poor performance

    const studentDoc = await db.collection("users").doc(student_id).get();
    const studentName = studentDoc.data()?.name || "Your child";

    const quizDoc = await db.collection("quizzes").doc(quiz_id).get();
    const quizTitle = quizDoc.data()?.title || "Quiz";

    const parentId = await getParentId(student_id);

    if (parentId) {
      await sendNotification({
        userId: parentId,
        title: "📉 Low Score Alert",
        body: `${studentName} scored ${percentage.toFixed(1)}% in ${quizTitle}. Extra attention needed!`,
        type: "grade",
        data: { student_id, quiz_id, score: String(percentage.toFixed(1)) },
      });
    }

    return null;
  });

// ── 3. onAssignmentDue ────────────────────────────────────────────────────────
exports.checkAssignmentDeadlines = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStart = new Date(tomorrow.setHours(0, 0, 0, 0));
    const tomorrowEnd = new Date(tomorrow.setHours(23, 59, 59, 999));

    const assignmentsSnap = await db.collection("assignments")
      .where("due_date", ">=", admin.firestore.Timestamp.fromDate(tomorrowStart))
      .where("due_date", "<=", admin.firestore.Timestamp.fromDate(tomorrowEnd))
      .get();

    for (const assignDoc of assignmentsSnap.docs) {
      const assign = assignDoc.data();
      const { class_id, title } = assign;

      // Get all students in class
      const studentsSnap = await db.collection("users")
        .where("class_id", "==", class_id)
        .where("role", "==", "student")
        .get();

      for (const studentDoc of studentsSnap.docs) {
        // Check if student already submitted
        const subSnap = await db.collection("submissions")
          .where("assignment_id", "==", assignDoc.id)
          .where("student_id", "==", studentDoc.id)
          .limit(1)
          .get();

        if (!subSnap.empty) continue; // Already submitted

        await sendNotification({
          userId: studentDoc.id,
          title: "⏰ Assignment Due Tomorrow!",
          body: `'${title}' is due tomorrow. Submit it now!`,
          type: "assignment",
          data: { assignment_id: assignDoc.id, title },
        });
      }
    }

    return null;
  });

// ── 4. onQuizPublished ────────────────────────────────────────────────────────
exports.onQuizCreated = functions.firestore
  .document("quizzes/{quizId}")
  .onCreate(async (snap) => {
    const quiz = snap.data();
    const { class_id, title, subject, start_time } = quiz;

    const startDate = start_time.toDate().toLocaleDateString("en-IN");

    // Notify all students in class
    const studentsSnap = await db.collection("users")
      .where("class_id", "==", class_id)
      .where("role", "==", "student")
      .get();

    for (const studentDoc of studentsSnap.docs) {
      await sendNotification({
        userId: studentDoc.id,
        title: `📝 New Quiz: ${subject}`,
        body: `${title} starts on ${startDate}. Prepare now!`,
        type: "quiz",
        data: { quiz_id: snap.id, title, subject },
      });
    }

    return null;
  });

// ── 5. onAtRiskDetected ───────────────────────────────────────────────────────
exports.onAIPredictionUpdated = functions.firestore
  .document("ai_predictions/{studentId}")
  .onWrite(async (change, context) => {
    const studentId = context.params.studentId;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData) return null;

    const newRisk = newData.risk_level;
    const oldRisk = oldData?.risk_level;

    // Only trigger if risk increased to "high"
    if (newRisk !== "high" || oldRisk === "high") return null;

    const studentDoc = await db.collection("users").doc(studentId).get();
    const studentName = studentDoc.data()?.name || "Student";
    const grade = newData.predicted_final_grade?.toFixed(1) || "—";
    const weakSubjects = (newData.weak_subjects || []).join(", ");

    // Notify parent
    const parentId = await getParentId(studentId);
    if (parentId) {
      await sendNotification({
        userId: parentId,
        title: "🚨 AI Risk Alert: High Risk",
        body: `${studentName}'s predicted grade is ${grade}%. Weak areas: ${weakSubjects || "Multiple subjects"}. Urgent attention needed!`,
        type: "ai_risk",
        data: { student_id: studentId, risk_level: "high" },
      });
    }

    // Notify teacher
    const classId = studentDoc.data()?.class_id;
    if (classId) {
      const teacherSnap = await db.collection("users")
        .where("class_id", "==", classId)
        .where("role", "==", "teacher")
        .limit(1)
        .get();

      if (!teacherSnap.empty) {
        await sendNotification({
          userId: teacherSnap.docs[0].id,
          title: "⚠️ At-Risk Student Alert",
          body: `${studentName} is now HIGH RISK (predicted: ${grade}%). Week subjects: ${weakSubjects}`,
          type: "ai_risk",
          data: { student_id: studentId, risk_level: "high" },
        });
      }
    }

    return null;
  });
