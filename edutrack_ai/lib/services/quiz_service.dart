import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/quiz_model.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Create Quiz ──────────────────────────────────────────────────────────────
  Future<QuizModel> createQuiz({
    required String classId,
    required String teacherId,
    required String title,
    required String subject,
    required int durationMins,
    required DateTime startTime,
    required DateTime endTime,
    required List<QuizQuestion> questions,
  }) async {
    final id = _uuid.v4();
    final quiz = QuizModel(
      id: id,
      classId: classId,
      teacherId: teacherId,
      title: title,
      subject: subject,
      durationMins: durationMins,
      startTime: startTime,
      endTime: endTime,
      questions: questions,
      createdAt: DateTime.now(),
    );
    await _db.collection('quizzes').doc(id).set(quiz.toMap());
    return quiz;
  }

  // ─── Get Quizzes for Class ────────────────────────────────────────────────────
  Stream<List<QuizModel>> streamQuizzesByClass(String classId) {
    return _db
        .collection('quizzes')
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => QuizModel.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.startTime.compareTo(a.startTime)); // Descending by start time
          return list;
        });
  }

  Future<List<QuizModel>> getQuizzesByClass(String classId) async {
    try {
      final snap = await _db
          .collection('quizzes')
          .where('class_id', isEqualTo: classId)
          .get();
      
      final list = snap.docs.map((d) => QuizModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.startTime.compareTo(a.startTime)); // Descending by start time
      return list;
    } catch (e) {
      debugPrint('QuizService Error: $e');
      rethrow;
    }
  }

  // ─── Get Single Quiz ──────────────────────────────────────────────────────────
  Future<QuizModel?> getQuiz(String quizId) async {
    final doc = await _db.collection('quizzes').doc(quizId).get();
    if (!doc.exists) return null;
    return QuizModel.fromMap(doc.id, doc.data()!);
  }

  // ─── Submit Quiz Result ───────────────────────────────────────────────────────
  Future<QuizResultModel> submitQuiz({
    required QuizModel quiz,
    required String studentId,
    required List<dynamic> answers,
  }) async {
    // Auto-calculate score for MCQ
    double score = 0;
    for (int i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      if (i >= answers.length) break;
      if (q.type == QuestionType.mcq) {
        if (answers[i] == q.correctOption) {
          score += q.marks;
        }
      }
      // Short answer: teacher grades manually
    }

    final id = _uuid.v4();
    final result = QuizResultModel(
      id: id,
      quizId: quiz.id,
      studentId: studentId,
      answers: answers,
      score: score,
      total: quiz.totalMarks,
      submittedAt: DateTime.now(),
    );

    await _db.collection('quiz_results').doc(id).set(result.toMap());
    return result;
  }

  // ─── Check if student already submitted ───────────────────────────────────────
  Future<QuizResultModel?> getStudentResult({
    required String quizId,
    required String studentId,
  }) async {
    final snap = await _db
        .collection('quiz_results')
        .where('quiz_id', isEqualTo: quizId)
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return QuizResultModel.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  // ─── Get All Results for Quiz ─────────────────────────────────────────────────
  Future<List<QuizResultModel>> getQuizResults(String quizId) async {
    final snap = await _db
        .collection('quiz_results')
        .where('quiz_id', isEqualTo: quizId)
        .get();
    return snap.docs
        .map((d) => QuizResultModel.fromMap(d.id, d.data()))
        .toList();
  }

  // ─── Get Student's All Results ────────────────────────────────────────────────
  Future<List<QuizResultModel>> getStudentResults(String studentId) async {
    final snap = await _db
        .collection('quiz_results')
        .where('student_id', isEqualTo: studentId)
        .get();
    final list = snap.docs
        .map((d) => QuizResultModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  // ─── Update Quiz ──────────────────────────────────────────────────────────────
  Future<void> updateQuiz(String id, Map<String, dynamic> updates) async {
    await _db.collection('quizzes').doc(id).update(updates);
  }

  // ─── Delete Quiz ──────────────────────────────────────────────────────────────
  Future<void> deleteQuiz(String id) async {
    final batch = _db.batch();
    
    // 1. Delete quiz doc
    batch.delete(_db.collection('quizzes').doc(id));
    
    // 2. Delete all related results
    final results = await _db.collection('quiz_results').where('quiz_id', isEqualTo: id).get();
    for (var doc in results.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
