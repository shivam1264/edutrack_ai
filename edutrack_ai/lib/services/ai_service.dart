import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String topic,
    required String subject,
    required int count,
    required String difficulty,
    required String type,
  }) async {
    try {
      final data = await _postBackendJson(
        '/generate-quiz',
        body: {
          'topic': topic,
          'subject': subject,
          'count': count,
          'difficulty': difficulty,
          'type': type,
        },
      );
      return _readList(data, preferredKeys: const ['questions']);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> generateStudyPlan(String userId, {Map<String, dynamic>? studentData}) async {
    try {
      final data = await _postBackendJson(
        '/generate-study-plan',
        body: {
          'userId': userId,
          if (studentData != null) 'student_data': studentData,
        },
      );
      return _readList(data, preferredKeys: const ['tasks', 'plan']);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> generateTopicTasks({
    required String topic,
    required String subject,
  }) async {
    try {
      final data = await _postBackendJson(
        '/generate-topic-tasks',
        body: {
          'topic': topic,
          'subject': subject,
        },
      );
      return _readList(data, preferredKeys: const ['tasks']);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String content) async {
    try {
      final data = await _postBackendJson(
        '/generate-flashcards',
        body: {'content': content},
      );
      return _readList(data, preferredKeys: const ['flashcards']);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> generateMindMap(String content) async {
    try {
      final data = await _postBackendJson(
        '/generate-mindmap',
        body: {'content': content},
      );
      if (data['mindmap'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      }
      if (data['mindmap'] is Map) {
        return {
          'mindmap': Map<String, dynamic>.from(data['mindmap'] as Map),
        };
      }
      return {'mindmap': {'title': 'Analysis Failed', 'children': []}};
    } catch (_) {
      return {'mindmap': {'title': 'Error', 'children': []}};
    }
  }

  Future<Map<String, dynamic>> analyzePerformance(Map<String, dynamic> data) async {
    try {
      return await _postBackendJson(
        '/analyze-performance',
        body: data,
      );
    } catch (_) {
      return _getFallbackAnalysis();
    }
  }

  Future<String> generateMonthlyReport(Map<String, dynamic> data) async {
    try {
      final response = await _postBackendJson(
        '/generate-monthly-report',
        body: data,
      );
      return response['report']?.toString() ??
          'Unable to generate detailed report. Please review the dashboard metrics.';
    } catch (_) {
      return 'Unable to generate detailed report. Please review the dashboard metrics.';
    }
  }

  Future<String> chat(String message, {String context = 'parent', String? studentId}) async {
    final isParentChat = context == 'parent';
    Map<String, dynamic>? studentContext;

    if (isParentChat) {
      try {
        studentContext = await _buildAuthorizedParentStudentContext(studentId);
      } catch (_) {
        return "I couldn't load the linked child data right now. Please try again in a moment.";
      }

      if (studentContext?['access'] != 'granted') {
        final reason = studentContext?['reason'] ?? 'Child access could not be verified.';
        return '$reason Please contact the school admin if this looks incorrect.';
      }
    }

    try {
      if (isParentChat && studentContext != null) {
        return await _requestParentChatBackend(
          query: message,
          studentContext: studentContext,
        );
      }

      final response = await _postBackendJson(
        '/general-chat',
        body: {
          'message': message,
          'context': context,
        },
      );

      return response['answer']?.toString() ??
          "I'm processing your request. Please ask specifically about academic goals.";
    } catch (_) {
      return "I'm processing your request. Please ask specifically about academic goals.";
    }
  }

  Future<Map<String, dynamic>?> _buildAuthorizedParentStudentContext(String? studentId) async {
    final cleanStudentId = studentId?.trim();
    final parentUid = _auth.currentUser?.uid;

    if (parentUid == null) {
      return {
        'access': 'denied',
        'reason': 'Parent is not logged in.',
      };
    }

    final parentDoc = await _db.collection('users').doc(parentUid).get();
    final parentData = parentDoc.data();
    final parentOf = _asStringList(parentData?['parent_of']);

    if (parentData?['role'] != 'parent') {
      return {
        'access': 'denied',
        'reason': 'Current user is not a parent account.',
      };
    }

    if (parentOf.isEmpty) {
      return {
        'access': 'denied',
        'reason': 'No child is linked with this parent account.',
      };
    }

    final authorizedStudentId =
        (cleanStudentId == null || cleanStudentId.isEmpty) ? parentOf.first : cleanStudentId;

    if (!parentOf.contains(authorizedStudentId)) {
      return {
        'access': 'denied',
        'reason': 'This child is not linked with the logged-in parent.',
      };
    }

    final studentDoc = await _db.collection('users').doc(authorizedStudentId).get();
    final studentData = studentDoc.data();
    if (studentData == null || studentData['role'] != 'student') {
      return {
        'access': 'denied',
        'reason': 'Linked child profile was not found.',
      };
    }

    final classId = studentData['class_id'] as String?;
    final classInfo = classId == null ? null : await _getClassInfo(classId);

    final results = await _getStudentQuizSummary(authorizedStudentId);
    final attendance = await _getStudentAttendanceSummary(authorizedStudentId);
    final assignments = await _getStudentAssignmentSummary(authorizedStudentId, classId);
    final aiPrediction = await _getStudentPrediction(authorizedStudentId);

    return {
      'access': 'granted',
      'student': {
        'id': authorizedStudentId,
        'name': studentData['name'] ?? 'Student',
        'class_id': classId,
        'class': classInfo,
        'roll_no': studentData['roll_no'],
        'xp': studentData['xp'] ?? 0,
        'level': studentData['level'] ?? 1,
        'streak': studentData['streak'] ?? 0,
        'badges': studentData['badges'] ?? [],
      },
      'academics': results,
      'attendance': attendance,
      'assignments': assignments,
      'ai_prediction': aiPrediction,
      'snapshot_generated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>?> _getClassInfo(String classId) async {
    final doc = await _db.collection('classes').doc(classId).get();
    final data = doc.data();
    if (data == null) return {'id': classId};

    return {
      'id': classId,
      'standard': data['standard'],
      'section': data['section'],
      'name': data['name'],
    };
  }

  Future<Map<String, dynamic>> _getStudentQuizSummary(String studentId) async {
    final snap = await _db
        .collection('quiz_results')
        .where('student_id', isEqualTo: studentId)
        .get();

    final docs = snap.docs.toList();
    docs.sort((a, b) {
      final aTime = a.data()['submitted_at'] as Timestamp?;
      final bTime = b.data()['submitted_at'] as Timestamp?;
      return (bTime ?? Timestamp(0, 0)).compareTo(aTime ?? Timestamp(0, 0));
    });

    final scored = docs.map((doc) {
      final data = doc.data();
      final score = (data['score'] as num?)?.toDouble() ?? 0;
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final percentage = total > 0 ? (score / total) * 100 : 0.0;
      return {
        'quiz_id': data['quiz_id'],
        'subject': data['subject'],
        'score': score,
        'total': total,
        'percentage': _round(percentage),
        'submitted_at': _timestampIso(data['submitted_at']),
      };
    }).toList();

    final percentages = scored.map((e) => e['percentage'] as double).toList();
    final average = percentages.isEmpty
        ? null
        : percentages.reduce((a, b) => a + b) / percentages.length;

    return {
      'attempts': scored.length,
      'average_percentage': average == null ? null : _round(average),
      'recent_results': scored.take(8).toList(),
    };
  }

  Future<Map<String, dynamic>> _getStudentAttendanceSummary(String studentId) async {
    final snap = await _db
        .collection('attendance')
        .where('student_id', isEqualTo: studentId)
        .get();

    final records = snap.docs.map((doc) => doc.data()).toList();
    records.sort((a, b) {
      final aDate = a['date'] as Timestamp?;
      final bDate = b['date'] as Timestamp?;
      return (bDate ?? Timestamp(0, 0)).compareTo(aDate ?? Timestamp(0, 0));
    });

    int present = 0;
    int absent = 0;
    int late = 0;
    final subjectStats = <String, Map<String, int>>{};

    for (final record in records) {
      final status = record['status']?.toString().toLowerCase() ?? '';
      final subject = record['subject']?.toString() ?? 'General';
      subjectStats.putIfAbsent(subject, () => {'present': 0, 'absent': 0, 'late': 0, 'total': 0});
      subjectStats[subject]!['total'] = subjectStats[subject]!['total']! + 1;

      if (status == 'present') {
        present++;
        subjectStats[subject]!['present'] = subjectStats[subject]!['present']! + 1;
      } else if (status == 'late') {
        late++;
        subjectStats[subject]!['late'] = subjectStats[subject]!['late']! + 1;
      } else if (status == 'absent') {
        absent++;
        subjectStats[subject]!['absent'] = subjectStats[subject]!['absent']! + 1;
      }
    }

    final total = records.length;
    final percentage = total > 0 ? ((present + (late * 0.5)) / total) * 100 : null;

    return {
      'total_records': total,
      'present': present,
      'absent': absent,
      'late': late,
      'attendance_percentage': percentage == null ? null : _round(percentage),
      'subject_stats': subjectStats,
      'recent_records': records.take(10).map((record) {
        return {
          'date': _timestampIso(record['date']),
          'date_string': record['date_string'],
          'subject': record['subject'] ?? 'General',
          'status': record['status'],
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _getStudentAssignmentSummary(String studentId, String? classId) async {
    final submissionsSnap = await _db
        .collection('submissions')
        .where('student_id', isEqualTo: studentId)
        .get();

    final submissionsByAssignment = <String, Map<String, dynamic>>{};
    for (final doc in submissionsSnap.docs) {
      final data = doc.data();
      final assignmentId = data['assignment_id'] as String?;
      if (assignmentId != null) {
        submissionsByAssignment[assignmentId] = {
          'id': doc.id,
          ...data,
        };
      }
    }

    final assignments = <Map<String, dynamic>>[];
    if (classId != null && classId.isNotEmpty) {
      final assignmentSnap = await _db
          .collection('assignments')
          .where('class_id', isEqualTo: classId)
          .get();

      for (final doc in assignmentSnap.docs) {
        final data = doc.data();
        final submission = submissionsByAssignment[doc.id];
        final dueDate = (data['due_date'] as Timestamp?)?.toDate();
        final status = submission?['status']?.toString() ??
            (dueDate != null && DateTime.now().isAfter(dueDate) ? 'overdue' : 'pending');

        assignments.add({
          'id': doc.id,
          'title': data['title'],
          'subject': data['subject'],
          'due_date': _timestampIso(data['due_date']),
          'max_marks': data['max_marks'],
          'status': status,
          'marks': submission?['marks'],
          'feedback': submission?['feedback'],
          'submitted_at': _timestampIso(submission?['submitted_at']),
        });
      }
    }

    assignments.sort((a, b) => (a['due_date'] ?? '').toString().compareTo((b['due_date'] ?? '').toString()));

    return {
      'total_assigned': assignments.length,
      'submitted_count': assignments.where((a) => a['status'] == 'submitted' || a['status'] == 'graded').length,
      'graded_count': assignments.where((a) => a['status'] == 'graded').length,
      'pending_count': assignments.where((a) => a['status'] == 'pending').length,
      'overdue_count': assignments.where((a) => a['status'] == 'overdue').length,
      'upcoming_or_recent': assignments.take(10).toList(),
    };
  }

  Future<Map<String, dynamic>?> _getStudentPrediction(String studentId) async {
    final doc = await _db.collection('ai_predictions').doc(studentId).get();
    return doc.data();
  }

  List<String> _asStringList(dynamic value) {
    if (value is String && value.isNotEmpty) return [value];
    if (value is List) return value.whereType<String>().toList();
    return [];
  }

  String? _timestampIso(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return null;
  }

  double _round(double value) => double.parse(value.toStringAsFixed(1));

  dynamic _jsonSafe(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is List) return value.map(_jsonSafe).toList();
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _jsonSafe(val)));
    }
    return value;
  }

  Future<String> _requestParentChatBackend({
    required String query,
    required Map<String, dynamic> studentContext,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    final response = await http
        .post(
          Uri.parse(Config.endpoint('/parent-chat')),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'query': query,
            'student_data': _jsonSafe(studentContext),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['answer']?.toString() ?? 'I could not generate an answer right now.';
    }

    throw Exception('Parent chat backend error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _postBackendJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .post(
          Uri.parse(Config.endpoint(path)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is List) {
      return {'items': decoded};
    }
    throw Exception('Unexpected backend response format');
  }

  List<Map<String, dynamic>> _readList(
    Map<String, dynamic> data, {
    List<String> preferredKeys = const [],
  }) {
    for (final key in preferredKeys) {
      final value = data[key];
      if (value is List) {
        return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }

    final items = data['items'];
    if (items is List) {
      return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return [];
  }

  Map<String, dynamic> _getFallbackAnalysis() {
    return {
      'summary': 'Analysis is currently unavailable, but student engagement remains steady.',
      'insights': ['Maintain regular attendance', 'Complete pending assignments'],
      'recommendations': ['Review recent quiz scores'],
      'risk_level': 'Low'
    };
  }
}
