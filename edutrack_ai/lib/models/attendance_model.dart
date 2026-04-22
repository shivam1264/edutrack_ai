import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceModel {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String markedBy;
  final String? subject; // Added subject field
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.markedBy,
    this.subject,
    required this.timestamp,
  });

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceModel(
      id: id,
      studentId: map['student_id'] ?? '',
      classId: map['class_id'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(map['status']),
      markedBy: map['marked_by'] ?? '',
      subject: map['subject'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'class_id': classId,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'marked_by': markedBy,
      if (subject != null) 'subject': subject,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static AttendanceStatus _parseStatus(String? s) {
    switch (s) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.absent;
    }
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isLate => status == AttendanceStatus.late;
}

class AttendanceStats {
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final double percentage;
  final Map<String, AttendanceStats>? subjectStats; // Stats per subject

  const AttendanceStats({
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.percentage,
    this.subjectStats,
  });

  int get total => totalPresent + totalAbsent + totalLate;
}
