import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { mcq, shortAnswer }

class QuizQuestion {
  final String text;
  final QuestionType type;
  final List<String> options;
  final int? correctOption;   // index for MCQ
  final double marks;

  QuizQuestion({
    required this.text,
    required this.type,
    this.options = const [],
    this.correctOption,
    this.marks = 1,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      text: map['text'] ?? '',
      type: map['type'] == 'mcq' ? QuestionType.mcq : QuestionType.shortAnswer,
      options: List<String>.from(map['options'] ?? []),
      correctOption: map['correct_option'],
      marks: (map['marks'] ?? 1).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type == QuestionType.mcq ? 'mcq' : 'short_answer',
      'options': options,
      if (correctOption != null) 'correct_option': correctOption,
      'marks': marks,
    };
  }
}

class QuizModel {
  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String subject;
  final int durationMins;
  final DateTime startTime;
  final DateTime endTime;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.subject,
    required this.durationMins,
    required this.startTime,
    required this.endTime,
    required this.questions,
    required this.createdAt,
  });

  bool get isActive =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get isExpired => DateTime.now().isAfter(endTime);

  double get totalMarks =>
      questions.fold(0, (sum, q) => sum + q.marks);

  factory QuizModel.fromMap(String id, Map<String, dynamic> map) {
    return QuizModel(
      id: id,
      classId: map['class_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      durationMins: map['duration_mins'] ?? 30,
      startTime: (map['start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['end_time'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 1)),
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'teacher_id': teacherId,
      'title': title,
      'subject': subject,
      'duration_mins': durationMins,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'questions': questions.map((q) => q.toMap()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

class QuizResultModel {
  final String id;
  final String quizId;
  final String studentId;
  final List<dynamic> answers; // index or text
  final double score;
  final double total;
  final DateTime submittedAt;

  QuizResultModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.score,
    required this.total,
    required this.submittedAt,
  });

  double get percentage => total > 0 ? (score / total) * 100 : 0;

  factory QuizResultModel.fromMap(String id, Map<String, dynamic> map) {
    return QuizResultModel(
      id: id,
      quizId: map['quiz_id'] ?? '',
      studentId: map['student_id'] ?? '',
      answers: List.from(map['answers'] ?? []),
      score: (map['score'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      submittedAt:
          (map['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quiz_id': quizId,
      'student_id': studentId,
      'answers': answers,
      'score': score,
      'total': total,
      'submitted_at': Timestamp.fromDate(submittedAt),
    };
  }
}
