import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'cloudinary_service.dart';

class LeaveRequestModel {
  final String id;
  final String studentId;
  final String parentId;
  final String classId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String type;
  final String status; // pending, approved, rejected
  final String? docUrl;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.studentId,
    required this.parentId,
    required this.classId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.type,
    required this.status,
    this.docUrl,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: id,
      studentId: map['student_id'] ?? '',
      parentId: map['parent_id'] ?? '',
      classId: map['class_id'] ?? '',
      startDate: (map['start_date'] as Timestamp).toDate(),
      endDate: (map['end_date'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      type: map['type'] ?? 'personal',
      status: map['status'] ?? 'pending',
      docUrl: map['doc_url'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'parent_id': parentId,
      'class_id': classId,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'reason': reason,
      'type': type,
      'status': status,
      'doc_url': docUrl,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

class LeaveService {
  static final LeaveService instance = LeaveService._internal();
  factory LeaveService() => instance;
  LeaveService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Submit Leave Request ──────────────────────────────────────────────────
  Future<void> submitLeaveRequest({
    required String studentId,
    required String parentId,
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String type,
    File? documentFile,
  }) async {
    String? docUrl;
    if (documentFile != null) {
      final res = await CloudinaryService.instance.uploadFile(
        documentFile,
        folder: 'edutrack_ai/leaves',
      );
      docUrl = res?.secureUrl;
    }

    final id = _uuid.v4();
    final model = LeaveRequestModel(
      id: id,
      studentId: studentId,
      parentId: parentId,
      classId: classId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      type: type,
      status: 'pending',
      docUrl: docUrl,
      createdAt: DateTime.now(),
    );

    await _db.collection('leave_requests').doc(id).set(model.toMap());
  }

  // ─── Get Pending Leaves for Class (Teacher) ──────────────────────────────
  Stream<List<LeaveRequestModel>> streamPendingLeaves(String classId) {
    return _db
        .collection('leave_requests')
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => LeaveRequestModel.fromMap(d.id, d.data()))
              .where((l) => l.status == 'pending')
              .toList();
          
          // Client-side sort to bypass index blockers
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ─── Get Leaves for Parent ──────────────────────────────────────────────────
  Stream<List<LeaveRequestModel>> streamParentLeaves(String parentId) {
    return _db
        .collection('leave_requests')
        .where('parent_id', isEqualTo: parentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => LeaveRequestModel.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ─── Update Leave Status ────────────────────────────────────────────────────
  Future<void> updateLeaveStatus(String leaveId, String status) async {
    await _db.collection('leave_requests').doc(leaveId).update({'status': status});
  }
}
