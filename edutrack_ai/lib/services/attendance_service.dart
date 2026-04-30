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
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    var query = _firestore
        .collection(_col)
        .where('student_id', isEqualTo: studentId)
        .where('class_id', isEqualTo: classId)
        .where('date_string', isEqualTo: dateStr);

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
      await _firestore
          .collection(_col)
          .doc(model.id)
          .update(model.toMap());
    } else {
      await _firestore
          .collection(_col)
          .doc(model.id)
          .set(model.toMap());
    }
  }

  // ─── Batch Mark Attendance ────────────────────────────────────────────────────
  Future<void> batchMarkAttendance({
    required List<Map<String, dynamic>> records,
    required String classId,
    required DateTime date,
    required String markedBy,
  }) async {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final existingSnap = await _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date_string', isEqualTo: dateStr)
        .get();

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
    bool filterBySubject = true,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    var query = _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date_string', isEqualTo: dateStr);

    if (filterBySubject) {
      if (subject != null) {
        query = query.where('subject', isEqualTo: subject);
      } else {
        query = query.where('subject', isNull: true);
      }
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
    // Removed orderBy to bypass composite index requirement
    Query query = _firestore
        .collection(_col)
        .where('student_id', isEqualTo: studentId);

    if (limitDays != null) {
      final from = DateTime.now().subtract(Duration(days: limitDays));
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    final snap = await query.get();
    final list = snap.docs
        .map((d) => AttendanceModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
    
    // Sort in-memory (descending)
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ─── Get Attendance Stats ─────────────────────────────────────────────────────
  Future<AttendanceStats> getAttendanceStats(String studentId) async {
    final records = await getStudentAttendanceHistory(studentId: studentId);
    
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => r.isAbsent).length;
    final late = records.where((r) => r.isLate).length;
    final total = records.length;
    final percentage = total > 0 ? ((present + (late * 0.5)) / total) * 100 : 0.0;

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
      final sPercentage = sTotal > 0 ? ((sPresent + (sLate * 0.5)) / sTotal) * 100 : 0.0;
          
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

  // ─── Get Aggregate Stats for a Class ─────────────────────────────────────────
  Future<AttendanceStats> getClassAttendanceStats(String classId) async {
    final snap = await _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .get();

    final records = snap.docs
        .map((d) => AttendanceModel.fromMap(d.id, d.data()))
        .toList();
    
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => r.isAbsent).length;
    final late = records.where((r) => r.isLate).length;
    final total = records.length;
    final percentage = total > 0 ? ((present + (late * 0.5)) / total) * 100 : 0.0;

    return AttendanceStats(
      totalPresent: present,
      totalAbsent: absent,
      totalLate: late,
      percentage: percentage,
    );
  }

  // ─── Get unique dates with marked attendance ──────────────────────────────
  Future<List<DateTime>> getMarkedDates(String classId) async {
    // Removed orderBy to avoid mandatory composite index requirement
    final snap = await _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .get();

    final Set<DateTime> uniqueDates = {};
    for (var doc in snap.docs) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      uniqueDates.add(DateTime(date.year, date.month, date.day));
    }
    
    // Sort in-memory (descending)
    final list = uniqueDates.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  // ─── Stream attendance for a class/date (real-time) ──────────────────────────
  Stream<List<AttendanceModel>> streamAttendanceByDate({
    required String classId,
    required DateTime date,
    String? subject,
    bool filterBySubject = true,
  }) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    var query = _firestore
        .collection(_col)
        .where('class_id', isEqualTo: classId)
        .where('date_string', isEqualTo: dateStr);

    if (filterBySubject) {
      if (subject != null) {
        query = query.where('subject', isEqualTo: subject);
      } else {
        query = query.where('subject', isNull: true);
      }
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => AttendanceModel.fromMap(d.id, d.data()))
        .toList());
  }
}
