import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String studentId;
  final String? teacherId;
  final String? teacherName;
  final String subject;
  final String title;
  final String content;
  final String? description;
  final String? fileUrl;
  final String? fileType;
  final String? classId;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.studentId,
    this.teacherId,
    this.teacherName,
    required this.subject,
    required this.title,
    required this.content,
    this.description,
    this.fileUrl,
    this.fileType,
    this.classId,
    required this.createdAt,
  });

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) {
    return NoteModel(
      id: id,
      studentId: map['student_id'] ?? map['userId'] ?? '',
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      subject: map['subject'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? map['description'] ?? '',
      description: map['description'],
      fileUrl: map['fileUrl'],
      fileType: map['fileType'],
      classId: map['class_id'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : map['created_at'] is Timestamp 
            ? (map['created_at'] as Timestamp).toDate()
            : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'title': title,
      'content': content,
      'description': description,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'class_id': classId,
      'createdAt': createdAt,
    };
  }
}
