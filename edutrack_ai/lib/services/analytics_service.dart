import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
        .get();

    final docs = quizSnap.docs.toList();
    // Sort in-memory to avoid composite index requirements
    docs.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['submitted_at'] as Timestamp?;
      final bTime = (b.data() as Map<String, dynamic>)['submitted_at'] as Timestamp?;
      return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
    });

    final scores = docs.take(20).map((d) {
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
    final Map<String, Map<String, dynamic>> assignmentCache = {}; // Local cache to avoid N+1 reads

    for (final doc in subSnap.docs) {
      final data = doc.data();
      if (data['status'] == 'graded' && data['marks'] != null) {
        final assignId = data['assignment_id'] as String?;
        if (assignId != null) {
          // Check cache first
          Map<String, dynamic>? aData = assignmentCache[assignId];
          
          if (aData == null) {
            final aDoc = await _db.collection('assignments').doc(assignId).get();
            if (aDoc.exists) {
              aData = aDoc.data();
              assignmentCache[assignId] = aData!;
            }
          }

          if (aData != null) {
            final subject = aData['subject'] as String? ?? 'Other';
            final marks = (data['marks'] as num).toDouble();
            final maxMarks = (aData['max_marks'] as num?)?.toDouble() ?? 100;
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

  // ─── Get student rank in class ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> getStudentRank(String studentId, String classId) async {
    final analytics = await getClassAnalytics(classId);
    final students = analytics['students'] as List<Map<String, dynamic>>;
    
    int rank = 0;
    for (int i = 0; i < students.length; i++) {
      if (students[i]['uid'] == studentId) {
        rank = i + 1;
        break;
      }
    }

    if (rank == 0) return null;

    return {
      'rank': rank,
      'total': students.length,
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
      try {
        final analytics = await getStudentAnalytics(uid);
        studentData.add({
          'uid': uid,
          'name': sDoc.data()['name'] ?? 'Incomplete Profile',
          ...analytics,
        });
      } catch (e) {
        print('DEBUG: Error processing student $uid: $e');
        // Add basic info even if analytics fail
        studentData.add({
          'uid': uid,
          'name': sDoc.data()['name'] ?? 'Incomplete Profile',
          'avg_score': 0.0,
          'last_5_scores': [],
          'subject_avg': {},
          'submitted_count': 0,
          'graded_count': 0,
        });
      }
    }

    studentData.sort((a, b) =>
        (b['avg_score'] as double).compareTo(a['avg_score'] as double));

    // Fetch pending submissions (ungraded)
    final pendingSubSnap = await _db.collection('submissions')
        .where('class_id', isEqualTo: classId)
        .where('status', isEqualTo: 'pending')
        .get();

    // Fetch announcements for this class
    final announceSnap = await _db.collection('announcements')
        .where('class_id', isEqualTo: classId)
        .get();

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
      'pending_tasks': pendingSubSnap.docs.length,
      'announcements_count': announceSnap.docs.length,
    };
  }

  // ─── Get Class Attendance (Today) ───────────────────────────────────────────
  Future<double> getClassAttendance(String classId) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final attendSnap = await _db.collection('attendance')
        .where('class_id', isEqualTo: classId)
        .where('date_string', isEqualTo: todayStr)
        .get();

    if (attendSnap.docs.isEmpty) return 0.0;

    int present = 0;
    int total = attendSnap.docs.length;
    
    for (var doc in attendSnap.docs) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase();
      if (status == 'present') {
        present++;
      } else if (status == 'late') {
        present++; // Counting late as present for % purposes, or 0.5 if preferred
      }
    }

    return total > 0 ? (present / total) * 100 : 0.0;
  }

  // ─── Get Class Performance Trend (Last 7 Days) ──────────────────────────────
  Future<List<double>> getClassPerformanceTrend(String classId) async {
    final resultsSnap = await _db.collection('quiz_results')
        .where('class_id', isEqualTo: classId)
        .get();

    final now = DateTime.now();
    final Map<int, List<double>> dailyScores = {};

    for (var doc in resultsSnap.docs) {
      final data = doc.data();
      final Timestamp? ts = data['submitted_at'];
      if (ts == null) continue;
      
      final diff = now.difference(ts.toDate()).inDays;
      if (diff >= 0 && diff < 7) {
        final score = (data['score'] as num).toDouble();
        final total = (data['total'] as num).toDouble();
        dailyScores.putIfAbsent(6 - diff, () => []);
        dailyScores[6 - diff]!.add((score / total) * 100);
      }
    }

    List<double> trend = List.filled(7, 70.0); // Default to 70% if no data
    for (int i = 0; i < 7; i++) {
      if (dailyScores.containsKey(i)) {
        trend[i] = dailyScores[i]!.reduce((a, b) => a + b) / dailyScores[i]!.length;
      } else if (i > 0) {
        trend[i] = trend[i-1]; 
      }
    }
    return trend;
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
        final dynamic data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('AI Study Plan Hub Error: $e');
    }
    return null;
  }
  
  // ─── Get Unified Wellness (Optimization) ──────────────────────────────────
  Future<Map<String, dynamic>?> getUnifiedWellness({
    required String name,
    required Map<String, dynamic> stats,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/get-unified-wellness')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'stats': stats}),
      ).timeout(const Duration(seconds: 40));
      
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('Unified Wellness Error: $e');
    }
    return null;
  }
}
