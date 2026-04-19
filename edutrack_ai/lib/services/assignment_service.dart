import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/assignment_model.dart';
import 'cloudinary_service.dart';   // ← Cloudinary instead of Firebase Storage

class AssignmentService {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Upload file via Cloudinary (FREE) ───────────────────────────────────────
  Future<String?> uploadFile(File file, {String folder = 'assignments'}) async {
    final result = await CloudinaryService.instance.uploadFile(
      file,
      folder: 'edutrack_ai/$folder',
    );
    return result?.secureUrl;
  }

  // ─── Create Assignment ────────────────────────────────────────────────────────
  Future<AssignmentModel> createAssignment({
    required String classId,
    required String teacherId,
    required String title,
    required String description,
    required String subject,
    required DateTime dueDate,
    required double maxMarks,
    File? attachedFile,
  }) async {
    String? fileUrl;
    if (attachedFile != null) {
      fileUrl = await uploadFile(attachedFile, folder: 'assignments');
    }

    final id = _uuid.v4();
    final model = AssignmentModel(
      id: id,
      classId: classId,
      teacherId: teacherId,
      title: title,
      description: description,
      subject: subject,
      dueDate: dueDate,
      maxMarks: maxMarks,
      fileUrl: fileUrl,
      createdAt: DateTime.now(),
    );

    await _db.collection('assignments').doc(id).set(model.toMap());
    return model;
  }

  // ─── Get Assignments for Class ────────────────────────────────────────────────
  Future<List<AssignmentModel>> getAssignmentsByClass(String classId) async {
    final snap = await _db
        .collection('assignments')
        .where('class_id', isEqualTo: classId)
        .orderBy('due_date', descending: false)
        .get();
    return snap.docs
        .map((d) => AssignmentModel.fromMap(d.id, d.data()))
        .toList();
  }

  Stream<List<AssignmentModel>> streamAssignmentsByClass(String classId) {
    return _db
        .collection('assignments')
        .where('class_id', isEqualTo: classId)
        .orderBy('due_date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AssignmentModel.fromMap(d.id, d.data())).toList());
  }

  // ─── Submit Assignment (with optional Cloudinary file upload) ─────────────────
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    required String studentId,
    String? content,
    String? note,
    File? file,
  }) async {
    String? fileUrl;
    if (file != null) {
      fileUrl = await uploadFile(
        file,
        folder: 'submissions/$assignmentId',
      );
    }

    final id = _uuid.v4();
    final model = SubmissionModel(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      content: content ?? note,
      fileUrl: fileUrl,
      submittedAt: DateTime.now(),
      status: AssignmentStatus.submitted,
    );

    await _db.collection('submissions').doc(id).set(model.toMap());
    return model;
  }

  // ─── Get Submissions for Assignment ───────────────────────────────────────────
  Future<List<SubmissionModel>> getSubmissionsByAssignment(
      String assignmentId) async {
    final snap = await _db
        .collection('submissions')
        .where('assignment_id', isEqualTo: assignmentId)
        .get();
    return snap.docs
        .map((d) => SubmissionModel.fromMap(d.id, d.data()))
        .toList();
  }

  // ─── Get Student's Submission for Assignment ──────────────────────────────────
  Future<SubmissionModel?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    final snap = await _db
        .collection('submissions')
        .where('assignment_id', isEqualTo: assignmentId)
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SubmissionModel.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  // ─── Grade Submission ─────────────────────────────────────────────────────────
  Future<void> gradeSubmission({
    required String submissionId,
    required double marks,
    required String feedback,
  }) async {
    await _db.collection('submissions').doc(submissionId).update({
      'marks': marks,
      'feedback': feedback,
      'status': AssignmentStatus.graded.name,
    });
  }

  // ─── Get Student's All Submissions ────────────────────────────────────────────
  Future<List<SubmissionModel>> getStudentSubmissions(String studentId) async {
    final snap = await _db
        .collection('submissions')
        .where('student_id', isEqualTo: studentId)
        .orderBy('submitted_at', descending: true)
        .get();
    return snap.docs
        .map((d) => SubmissionModel.fromMap(d.id, d.data()))
        .toList();
  }
}
