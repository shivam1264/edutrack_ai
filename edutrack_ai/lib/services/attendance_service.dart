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
    String? subject,
  }) async {
    // Check for duplicate: same date + class + student + subject
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    var query = _firestore
        .collection(_col)
        .where('student_id', isEqualTo: studentId)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd));

    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    } else {
      query = query.where('subject', isNull: true);
    }

    final existing = await query.limit(1).get();

    final model = AttendanceModel(
      id: existing.docs.isNotEmpty ? existing.docs.first.id : _uuid.v4(),
      studentId: studentId,
      classId: classId,
      date: dateStart,
      status: status,
      markedBy: markedBy,
      subject: subject,
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
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    // 1. Fetch all existing attendance for this class/date
    final existingSnap = await _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .get();

    // Map existing records by studentId for fast lookup
    final Map<String, String> existingIds = {
      for (var doc in existingSnap.docs) doc.data()['student_id'] as String: doc.id
    };

    final batch = _firestore.batch();

    for (final record in records) {
      final studentId = record['studentId'];
      final existingId = existingIds[studentId];
      
      final id = existingId ?? _uuid.v4();
      final ref = _firestore.collection(_col).doc(id);
      
      final model = AttendanceModel(
        id: id,
        studentId: studentId,
        classId: classId,
        date: dateStart,
        status: record['status'],
        markedBy: markedBy,
        timestamp: DateTime.now(),
      );
      
      batch.set(ref, model.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─── Get Attendance by Date & Class ──────────────────────────────────────────
  Future<List<AttendanceModel>> getAttendanceByDate({
    required String classId,
    required DateTime date,
    String? subject,
  }) async {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    var query = _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd));

    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }

    final snap = await query.get();

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
    
    // Overall Stats
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => r.isAbsent).length;
    final late = records.where((r) => r.isLate).length;
    final total = records.length;
    final percentage = total > 0
        ? ((present + (late * 0.5)) / total) * 100
        : 0.0;

    // Subject-wise Stats
    final Map<String, List<AttendanceModel>> subjectGroups = {};
    for (var r in records) {
      final sub = r.subject ?? 'General';
      subjectGroups.putIfAbsent(sub, () => []).add(r);
    }

    final Map<String, AttendanceStats> subjectStats = {};
    subjectGroups.forEach((sub, subRecords) {
      final sPresent = subRecords.where((r) => r.isPresent).length;
      final sAbsent = subRecords.where((r) => r.isAbsent).length;
      final sLate = subRecords.where((r) => r.isLate).length;
      final sTotal = subRecords.length;
      final sPercentage = sTotal > 0
          ? ((sPresent + (sLate * 0.5)) / sTotal) * 100
          : 0.0;
          
      subjectStats[sub] = AttendanceStats(
        totalPresent: sPresent,
        totalAbsent: sAbsent,
        totalLate: sLate,
        percentage: sPercentage,
      );
    });

    return AttendanceStats(
      totalPresent: present,
      totalAbsent: absent,
      totalLate: late,
      percentage: percentage,
      subjectStats: subjectStats,
    );
  }
    // ─── Get unique dates with marked attendance ──────────────────────────────
  Future<List<DateTime>> getMarkedDates(String classId) async {
    final snap = await _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .orderBy('date', descending: true)
        .get();

    final Set<DateTime> uniqueDates = {};
    for (var doc in snap.docs) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      // Normalize to start of day
      uniqueDates.add(DateTime(date.year, date.month, date.day));
    }
    
    return uniqueDates.toList()..sort((a, b) => b.compareTo(a));
  }
}

  // ─── Stream attendance for a class/date (real-time) ──────────────────────────
  Stream<List<AttendanceModel>> streamAttendanceByDate({
    required String classId,
    required DateTime date,
    String? subject,
  }) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    var query = _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd));

    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => AttendanceModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }
}
