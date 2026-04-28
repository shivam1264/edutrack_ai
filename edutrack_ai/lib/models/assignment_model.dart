import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { pending, submitted, graded, overdue }

class AssignmentModel {
  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String description;
  final String subject;
  final DateTime dueDate;
  final double maxMarks;
  final String? fileUrl;
  final DateTime createdAt;

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.subject,
    required this.dueDate,
    required this.maxMarks,
    this.fileUrl,
    required this.createdAt,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  factory AssignmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AssignmentModel(
      id: id,
      classId: map['class_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      dueDate: (map['due_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxMarks: (map['max_marks'] ?? 100).toDouble(),
      fileUrl: map['file_url'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'subject': subject,
      'due_date': Timestamp.fromDate(dueDate),
      'max_marks': maxMarks,
      if (fileUrl != null) 'file_url': fileUrl,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final String? fileUrl;
  final DateTime submittedAt;
  final double? marks;
  final String? feedback;
  final AssignmentStatus status;
  final bool resubmissionAllowed;  // Teacher can allow resubmission
  final int resubmissionCount;     // Track number of resubmissions
  final Map<String, dynamic>? aiScanResult;  // AI scan results
  final DateTime? aiScanTimestamp;  // When AI scan was performed

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.fileUrl,
    required this.submittedAt,
    this.marks,
    this.feedback,
    required this.status,
    this.resubmissionAllowed = false,
    this.resubmissionCount = 0,
    this.aiScanResult,
    this.aiScanTimestamp,
  });

  factory SubmissionModel.fromMap(String id, Map<String, dynamic> map) {
    return SubmissionModel(
      id: id,
      assignmentId: map['assignment_id'] ?? '',
      studentId: map['student_id'] ?? '',
      content: map['content'],
      fileUrl: map['file_url'],
      submittedAt:
          (map['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      marks: (map['marks'] as num?)?.toDouble(),
      feedback: map['feedback'],
      status: _parseStatus(map['status']),
      resubmissionAllowed: map['resubmission_allowed'] ?? false,
      resubmissionCount: map['resubmission_count'] ?? 0,
      aiScanResult: map['ai_scan_result'] as Map<String, dynamic>?,
      aiScanTimestamp: (map['ai_scan_timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignment_id': assignmentId,
      'student_id': studentId,
      if (content != null) 'content': content,
      if (fileUrl != null) 'file_url': fileUrl,
      'submitted_at': Timestamp.fromDate(submittedAt),
      if (marks != null) 'marks': marks,
      if (feedback != null) 'feedback': feedback,
      'status': status.name,
      'resubmission_allowed': resubmissionAllowed,
      'resubmission_count': resubmissionCount,
      if (aiScanResult != null) 'ai_scan_result': aiScanResult,
      if (aiScanTimestamp != null) 'ai_scan_timestamp': Timestamp.fromDate(aiScanTimestamp!),
    };
  }

  bool get canResubmit {
    // Can resubmit if:
    // 1. Never submitted before (resubmissionCount == 0 and status != submitted/graded)
    // 2. Teacher allowed resubmission (resubmissionAllowed == true)
    if (resubmissionCount == 0 && status == AssignmentStatus.pending) return true;
    return resubmissionAllowed;
  }

  static AssignmentStatus _parseStatus(String? s) {
    switch (s) {
      case 'submitted':
        return AssignmentStatus.submitted;
      case 'graded':
        return AssignmentStatus.graded;
      case 'overdue':
        return AssignmentStatus.overdue;
      default:
        return AssignmentStatus.pending;
    }
  }
}
