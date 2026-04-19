import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final String _col = 'attendance';

  // ─── Mark Attendance ─────────────────────────────────────────────────────────
  Future<void> markAttendance({
    required String studentId,
    required String classId,
    required DateTime date,
    required AttendanceStatus status,
    required String markedBy,
  }) async {
    // Check for duplicate: same date + class + student
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final existing = await _firestore
        .collection(_col)
        .where('student_id', isEqualTo: studentId)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .limit(1)
        .get();

    final model = AttendanceModel(
      id: existing.docs.isNotEmpty ? existing.docs.first.id : _uuid.v4(),
      studentId: studentId,
      classId: classId,
      date: dateStart,
      status: status,
      markedBy: markedBy,
      timestamp: DateTime.now(),
    );

    if (existing.docs.isNotEmpty) {
      // Update existing
      await _firestore
          .collection(_col)
          .doc(model.id)
          .update(model.toMap());
    } else {
      // Create new
      await _firestore
          .collection(_col)
          .doc(model.id)
          .set(model.toMap());
    }
  }

  // ─── Batch Mark Attendance ────────────────────────────────────────────────────
  Future<void> batchMarkAttendance({
    required List<Map<String, dynamic>> records, // {studentId, status}
    required String classId,
    required DateTime date,
    required String markedBy,
  }) async {
    final batch = _firestore.batch();
    final dateStart = DateTime(date.year, date.month, date.day);

    for (final record in records) {
      final id = _uuid.v4();
      final ref = _firestore.collection(_col).doc(id);
      final model = AttendanceModel(
        id: id,
        studentId: record['studentId'],
        classId: classId,
        date: dateStart,
        status: record['status'],
        markedBy: markedBy,
        timestamp: DateTime.now(),
      );
      batch.set(ref, model.toMap());
    }
    await batch.commit();
  }

  // ─── Get Attendance by Date & Class ──────────────────────────────────────────
  Future<List<AttendanceModel>> getAttendanceByDate({
    required String classId,
    required DateTime date,
  }) async {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final snap = await _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .get();

    return snap.docs
        .map((d) => AttendanceModel.fromMap(d.id, d.data()))
        .toList();
  }

  // ─── Get Student Attendance History ──────────────────────────────────────────
  Future<List<AttendanceModel>> getStudentAttendanceHistory({
    required String studentId,
    int? limitDays,
  }) async {
    Query query = _firestore
        .collection(_col)
        .where('student_id', isEqualTo: studentId)
        .orderBy('date', descending: true);

    if (limitDays != null) {
      final from = DateTime.now().subtract(Duration(days: limitDays));
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => AttendanceModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  // ─── Get Attendance Stats ─────────────────────────────────────────────────────
  Future<AttendanceStats> getAttendanceStats(String studentId) async {
    final records = await getStudentAttendanceHistory(studentId: studentId);
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => r.isAbsent).length;
    final late = records.where((r) => r.isLate).length;
    final total = records.length;
    final percentage = total > 0
        ? ((present + (late * 0.5)) / total) * 100
        : 0.0;

    return AttendanceStats(
      totalPresent: present,
      totalAbsent: absent,
      totalLate: late,
      percentage: percentage,
    );
  }

  // ─── Stream attendance for a class/date (real-time) ──────────────────────────
  Stream<List<AttendanceModel>> streamAttendanceByDate({
    required String classId,
    required DateTime date,
  }) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    return _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceModel.fromMap(d.id, d.data()))
            .toList());
  }
}
