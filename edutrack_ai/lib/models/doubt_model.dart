import 'package:cloud_firestore/cloud_firestore.dart';

class DoubtModel {
  final String id;
  final String studentId;
  final String subject;
  final String question;
  final String status; // 'Pending', 'Answered'
  final DateTime createdAt;

  DoubtModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.question,
    required this.status,
    required this.createdAt,
  });

  factory DoubtModel.fromMap(String id, Map<String, dynamic> map) {
    return DoubtModel(
      id: id,
      studentId: map['studentId'] ?? map['student_id'] ?? '',
      subject: map['subject'] ?? '',
      question: map['question'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] ?? map['created_at']) is Timestamp 
          ? (map['createdAt'] ?? map['created_at'] as Timestamp).toDate() 
          : DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'subject': subject,
      'question': question,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
