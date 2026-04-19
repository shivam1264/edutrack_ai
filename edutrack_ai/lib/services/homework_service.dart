import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class HomeworkService {
  static final HomeworkService instance = HomeworkService._internal();
  factory HomeworkService() => instance;
  HomeworkService._internal();

  // Replace with your Cloud Run URL after deployment
  // Backend uses Gemini 1.5 Flash (FREE) for AI answers
  static const String _baseUrl = 'http://127.0.0.1:8080';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Ask homework question ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> askHomeworkQuestion({
    required String studentId,
    required String question,
    required String subject,
    required int studentClass,
    String? imageData, // Base64 string
    bool showHintFirst = false,
  }) async {
    // Check daily rate limit
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final rateRef = _db
        .collection('homework_usage')
        .doc('${studentId}_${todayStart.toIso8601String().split('T').first}');

    final rateDoc = await rateRef.get();
    final currentCount = rateDoc.exists ? (rateDoc.data()!['count'] ?? 0) : 0;

    if (currentCount >= 500) {
      throw Exception('Daily mission limit of 500 queries reached. System cooldown initiated!');
    }

    // Call Flask API
    final response = await http.post(
      Uri.parse('$_baseUrl/homework-help'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'subject': subject,
        'student_class': studentClass,
        'show_hint_first': showHintFirst,
        'image_data': imageData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI service error. Please try again.');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    // Update rate limit counter
    await rateRef.set({
      'student_id': studentId,
      'count': currentCount + 1,
      'date': Timestamp.fromDate(todayStart),
    }, SetOptions(merge: true));

    // Save to chat history
    await _saveChatMessage(
      studentId: studentId,
      question: question,
      answer: result['answer'] ?? '',
      subject: subject,
    );

    return {
      ...result,
      'daily_count': currentCount + 1,
    };
  }

  // ─── Save chat message ────────────────────────────────────────────────────────
  Future<void> _saveChatMessage({
    required String studentId,
    required String question,
    required String answer,
    required String subject,
  }) async {
    final sessionDate =
        DateTime.now().toIso8601String().split('T').first;
    await _db
        .collection('homework_chats')
        .doc('${studentId}_$sessionDate')
        .collection('messages')
        .add({
      'question': question,
      'answer': answer,
      'subject': subject,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── Get today's chat history ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTodayChatHistory(
      String studentId) async {
    final sessionDate =
        DateTime.now().toIso8601String().split('T').first;
    final snap = await _db
        .collection('homework_chats')
        .doc('${studentId}_$sessionDate')
        .collection('messages')
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ─── Get daily usage count ────────────────────────────────────────────────────
  Future<int> getDailyUsageCount(String studentId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final rateRef = _db
        .collection('homework_usage')
        .doc('${studentId}_${todayStart.toIso8601String().split('T').first}');
    final doc = await rateRef.get();
    return doc.exists ? (doc.data()!['count'] ?? 0) : 0;
  }
}
