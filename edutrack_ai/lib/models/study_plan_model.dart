class StudyTaskModel {
  final String id;
  final String title;
  final String subject;
  final String type; // 'Review', 'Practice', 'Assignment'
  final int durationMinutes;
  final bool isCompleted;

  StudyTaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.durationMinutes,
    this.isCompleted = false,
  });

  factory StudyTaskModel.fromMap(String id, Map<String, dynamic> map) {
    return StudyTaskModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      type: map['type'] ?? 'Review',
      durationMinutes: map['duration_minutes'] ?? 30,
      isCompleted: map['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'type': type,
      'duration_minutes': durationMinutes,
      'is_completed': isCompleted,
    };
  }

  StudyTaskModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? type,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return StudyTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
