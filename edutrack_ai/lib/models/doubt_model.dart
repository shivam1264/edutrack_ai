import 'package:cloud_firestore/cloud_firestore.dart';

class DoubtModel {
  final String id;
  final String studentId;
  final String subject;
  final String question;
  final String status; // 'Pending', 'Answered'
  final String? answer;
  final DateTime createdAt;

  DoubtModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.question,
    required this.status,
    this.answer,
    required this.createdAt,
  });

  factory DoubtModel.fromMap(String id, Map<String, dynamic> map) {
    final createdValue = map['createdAt'] ?? map['created_at'];
    return DoubtModel(
      id: id,
      studentId: map['studentId'] ?? map['student_id'] ?? '',
      subject: map['subject'] ?? '',
      question: map['question'] ?? '',
      status: map['status'] ?? 'pending',
      answer: map['answer'],
      createdAt: createdValue is Timestamp
          ? createdValue.toDate()
          : DateTime.tryParse(createdValue?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'subject': subject,
      'question': question,
      'status': status,
      if (answer != null) 'answer': answer,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
