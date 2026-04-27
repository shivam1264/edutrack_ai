import 'package:cloud_firestore/cloud_firestore.dart';

class StudyTaskModel {
  final String id;
  final String title;
  final String subject;
  final String type; // 'Review', 'Practice', 'Assignment'
  final int durationMinutes;
  final bool isCompleted;
  final DateTime createdAt;

  StudyTaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.durationMinutes,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory StudyTaskModel.fromMap(String id, Map<String, dynamic> map) {
    final createdValue = map['created_at'] ?? map['createdAt'];
    return StudyTaskModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      type: map['type'] ?? 'Review',
      durationMinutes: map['duration_minutes'] ?? 30,
      isCompleted: map['is_completed'] ?? false,
      createdAt: createdValue is Timestamp
          ? createdValue.toDate()
          : DateTime.tryParse(createdValue?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'type': type,
      'duration_minutes': durationMinutes,
      'is_completed': isCompleted,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  StudyTaskModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? type,
    int? durationMinutes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return StudyTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
