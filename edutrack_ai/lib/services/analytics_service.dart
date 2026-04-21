import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  factory AnalyticsService() => instance;
  AnalyticsService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _baseUrl = Config.baseUrl;

  // ─── Get student overall average ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentAnalytics(String studentId) async {
    // Quiz scores
    final quizSnap = await _db
        .collection('quiz_results')
        .where('student_id', isEqualTo: studentId)
        .orderBy('submitted_at', descending: true)
        .limit(20)
        .get();

    final scores = quizSnap.docs.map((d) {
      final data = d.data();
      final score = (data['score'] as num?)?.toDouble() ?? 0;
      final total = (data['total'] as num?)?.toDouble() ?? 1;
      return total > 0 ? (score / total) * 100 : 0.0;
    }).toList();

    final avgScore = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;

    // Submissions
    final subSnap = await _db
        .collection('submissions')
        .where('student_id', isEqualTo: studentId)
        .get();
    final submitted = subSnap.docs.length;
    final graded =
        subSnap.docs.where((d) => d.data()['status'] == 'graded').length;

    // Subject breakdown from submissions
    final Map<String, List<double>> subjectScores = {};
    for (final doc in subSnap.docs) {
      final data = doc.data();
      if (data['status'] == 'graded' && data['marks'] != null) {
        final assignId = data['assignment_id'] as String?;
        if (assignId != null) {
          final aDoc = await _db.collection('assignments').doc(assignId).get();
          if (aDoc.exists) {
            final subject = aDoc.data()!['subject'] as String? ?? 'Other';
            final marks = (data['marks'] as num).toDouble();
            final maxMarks =
                (aDoc.data()!['max_marks'] as num?)?.toDouble() ?? 100;
            subjectScores.putIfAbsent(subject, () => []);
            subjectScores[subject]!.add((marks / maxMarks) * 100);
          }
        }
      }
    }

    final subjectAvg = subjectScores.map((k, v) =>
        MapEntry(k, v.reduce((a, b) => a + b) / v.length));

    return {
      'avg_score': avgScore,
      'last_5_scores': scores.take(5).toList(),
      'subject_avg': subjectAvg,
      'submitted_count': submitted,
      'graded_count': graded,
    };
  }

  // ─── Get class analytics for teacher ─────────────────────────────────────────
  Future<Map<String, dynamic>> getClassAnalytics(String classId) async {
    // FIX: Using 'users' collection instead of legacy 'students'
    final studentsSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('class_id', isEqualTo: classId)
        .get();

    final List<Map<String, dynamic>> studentData = [];
    for (final sDoc in studentsSnap.docs) {
      final uid = sDoc.id;
      final analytics = await getStudentAnalytics(uid);
      studentData.add({
        'uid': uid,
        'name': sDoc.data()['name'] ?? 'Incomplete Profile',
        ...analytics,
      });
    }

    studentData.sort((a, b) =>
        (b['avg_score'] as double).compareTo(a['avg_score'] as double));

    return {
      'students': studentData,
      'top5': studentData.take(5).toList(),
      'bottom5': studentData.reversed.take(5).toList(),
      'class_avg': studentData.isEmpty
          ? 0.0
          : studentData
                  .map((s) => s['avg_score'] as double)
                  .reduce((a, b) => a + b) /
              studentData.length,
    };
  }

  // ─── AI Prediction from Firestore ────────────────────────────────────────────
  Future<Map<String, dynamic>?> getAIPrediction(String studentId) async {
    final doc =
        await _db.collection('ai_predictions').doc(studentId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // ─── Get Study Plan from Flask API ───────────────────────────────────────────
  Future<Map<String, dynamic>?> getStudyPlan({
    required String studentId,
    required List<String> weakSubjects,
    required List<Map<String, dynamic>> upcomingDeadlines,
    required int studyHoursPerDay,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/generate-study-plan')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'weak_subjects': weakSubjects,
          'upcoming_deadlines': upcomingDeadlines,
          'study_hours_per_day': studyHoursPerDay,
        }),
      ).timeout(const Duration(seconds: 40));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('AI Study Plan Hub Error: $e');
    }
    return null;
  }
}
