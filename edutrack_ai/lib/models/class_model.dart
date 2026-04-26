import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String standard;
  final String? section;
  final String schoolId;
  final String? classTeacherId;
  final String? classTeacherName;

  ClassModel({
    required this.id,
    required this.standard,
    this.section,
    required this.schoolId,
    this.classTeacherId,
    this.classTeacherName,
  });

  String get displayName => section != null && section!.isNotEmpty 
      ? '$standard - $section' 
      : standard;

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      standard: map['standard'] ?? '',
      section: map['section'],
      schoolId: map['school_id'] ?? 'SCH001',
      classTeacherId: map['class_teacher_id'],
      classTeacherName: map['class_teacher_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'standard': standard,
      'section': section,
      'school_id': schoolId,
      'class_teacher_id': classTeacherId,
      'class_teacher_name': classTeacherName,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
