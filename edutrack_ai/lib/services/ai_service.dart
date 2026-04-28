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

  // API Keys - Strictly using Groq (Llama)
  static const String _groqKey = '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'; 

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String topic,
    required String subject,
    required int count,
    required String difficulty,
    required String type,
  }) async {
    final systemInstruction = """
You are an expert Teacher. Generate a high-quality quiz in valid JSON format.
The response MUST be ONLY a JSON list of objects.

Structure for 'MCQ' (type: "mcq"):
[{"text": "Question?", "options": ["A", "B", "C", "D"], "correctOption": 0, "marks": 1, "type": "mcq"}]

Structure for 'True/False' (type: "mcq"):
[{"text": "Question?", "options": ["True", "False"], "correctOption": 0, "marks": 1, "type": "mcq"}]

Structure for 'Short Answer' (type: "short"):
[{"text": "Question?", "options": [], "correctOption": -1, "marks": 2, "type": "short"}]

Difficulty: $difficulty. Topic: $topic. Subject: $subject.
""";
    return await _exhaustOptions(systemInstruction, "Generate $count questions of type $type.");
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String content) async {
    const systemInstruction = """
You are an AI Study Assistant. Summarize content into Flashcards.
Return STRICTLY as a JSON list: [{"q": "Question?", "a": "Answer"}].
""";
    return await _exhaustOptions(systemInstruction, "Content:\n$content");
  }

  Future<Map<String, dynamic>> generateMindMap(String content) async {
    const systemInstruction = """
You are an AI Visualizer. Convert content into a hierarchical Mind Map structure.
Return STRICTLY as a JSON object: {"mindmap": {"title": "Main Topic", "children": [{"title": "Subtopic 1", "children": [...]}]}}.
""";
    try {
      final res = await _requestGroq(systemInstruction, content);
      return res.isNotEmpty ? res[0] : {'mindmap': {'title': 'Analysis Failed', 'children': []}};
    } catch (e) {
      return {'mindmap': {'title': 'Error', 'children': []}};
    }
  }

  Future<Map<String, dynamic>> analyzePerformance(Map<String, dynamic> data) async {
    const systemInstruction = """
You are a Senior Academic Analyst. Analyze the provided class/student data.
Return STRICTLY as a JSON object: {
  "summary": "overall text",
  "insights": ["insight 1", "insight 2"],
  "recommendations": ["rec 1", "rec 2"],
  "risk_level": "Low/Medium/High"
}
""";
    try {
      final res = await _requestGroq(systemInstruction, jsonEncode(data));
      return res.isNotEmpty ? res[0] : _getFallbackAnalysis();
    } catch (e) {
      return _getFallbackAnalysis();
    }
  }

  Future<String> generateMonthlyReport(Map<String, dynamic> data) async {
    const systemInstruction = """
You are a Professional Academic Counselor. Generate a formal, detailed monthly progress report for a student.
Include sections: Academic Summary, Consistency Protocol, and Strategic Advisory.
Use a professional tone. Return as plain text.
""";
    try {
      return await _requestPlainGroq(systemInstruction, jsonEncode(data));
    } catch (e) {
      return "Unable to generate detailed report. Please review the dashboard metrics.";
    }
  }

  Future<String> chat(String message, {String context = 'parent', String? studentId}) async {
    final isParentChat = context == 'parent';
    Map<String, dynamic>? studentContext;

    if (isParentChat) {
      try {
        studentContext = await _buildAuthorizedParentStudentContext(studentId);
      } catch (e) {
        return "I couldn't load the linked child data right now. Please try again in a moment.";
      }

      if (studentContext?['access'] != 'granted') {
        final reason = studentContext?['reason'] ?? 'Child access could not be verified.';
        return "$reason Please contact the school admin if this looks incorrect.";
      }
    }

    final systemInstruction = """
You are an AI Education Assistant for EduTrack AI. Current Role: $context.
Keep responses concise (max 3-4 sentences).
${isParentChat ? """
For parent chats, answer only about the authorized child data provided below.
Do not reveal any other student's data. Do not invent marks, attendance, risk levels, deadlines, or teacher feedback.
If the parent asks for unavailable data, say that it is not available in EduTrack yet and suggest where they can check in the app.
Use the child's name when available and explain in simple parent-friendly language.
""" : ""}
""";

    final userPrompt = studentContext == null
        ? message
        : """
Authorized child data snapshot:
${jsonEncode(_jsonSafe(studentContext))}

Parent question:
$message
""";

    try {
      if (isParentChat && studentContext != null) {
        return await _requestParentChatBackend(
          query: message,
          studentContext: studentContext,
        );
      }
      return await _requestPlainGroq(systemInstruction, userPrompt);
    } catch (e) {
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

  // Helper for JSON requests
  Future<List<Map<String, dynamic>>> _exhaustOptions(String system, String user) async {
    try {
      return await _requestGroq(system, user);
    } catch (e) {
      print('Groq JSON Error: $e');
      return [];
    }
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

  Future<List<Map<String, dynamic>>> _requestGroq(String system, String user) async {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
        "temperature": 0.5,
        // Removed response_format: json_object to allow list returns reliably
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = data['choices'][0]['message']['content'];
      
      // Clean JSON string from potential markdown wrappers
      final cleanedText = _cleanJson(text);
      
      try {
        final decoded = jsonDecode(cleanedText);
        if (decoded is List) return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        if (decoded is Map && (decoded.containsKey('questions') || decoded.containsKey('flashcards'))) {
           final list = (decoded['questions'] ?? decoded['flashcards']) as List;
           return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [Map<String, dynamic>.from(decoded)];
      } catch (e) {
        print('❌ AIService JSON Parse Error: $e\nOriginal Text: $text');
        rethrow;
      }
    }
    print('❌ Groq API Error: ${response.statusCode} - ${response.body}');
    throw Exception('Groq Error: ${response.statusCode}');
  }

  String _cleanJson(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      // Remove opening block (e.g., ```json or just ```)
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      // Remove closing block
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return cleaned.trim();
  }

  Future<String> _requestPlainGroq(String system, String user) async {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
        "temperature": 0.6,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw Exception('Groq Error');
  }

  Map<String, dynamic> _getFallbackAnalysis() {
    return {
      "summary": "Analysis is currently unavailable, but student engagement remains steady.",
      "insights": ["Maintain regular attendance", "Complete pending assignments"],
      "recommendations": ["Review recent quiz scores"],
      "risk_level": "Low"
    };
  }
}
