import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart';

class HomeworkService {
  static final HomeworkService instance = HomeworkService._internal();
  factory HomeworkService() => instance;
  HomeworkService._internal();

  static const String _baseUrl = Config.baseUrl;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Ask homework question ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> askHomeworkQuestion({
    required String studentId,
    required String question,
    required String subject,
    required String studentClass, // Changed from int to String
    String? imageData, // Base64 string
    bool showHintFirst = false,
  }) async {
    // 1. Map String class (e.g. '10th A') to numeric year (e.g. 10)
    final int numericClass = _mapClassToYear(studentClass);

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
        'student_class': numericClass, // Pass numeric mapped class
        'show_hint_first': showHintFirst,
        'image_data': imageData,
      }),
    ).timeout(const Duration(seconds: 60));

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

  // ─── Helper: Map Standard Class String to Numeric ──────────────────────────────
  int _mapClassToYear(String cls) {
    final lower = cls.toLowerCase();
    
    // Check for KG/Primary
    if (lower.contains('kg') || lower.contains('primary')) return 0;
    
    // Extract digits (e.g. '10th A' -> 10)
    final match = RegExp(r'(\d+)').firstMatch(cls);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 1;
    }
    
    return 1; // Default fallback
  }
}
