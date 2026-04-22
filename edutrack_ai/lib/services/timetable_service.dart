import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';

class TimetableService {
  static final TimetableService _instance = TimetableService._internal();
  factory TimetableService() => _instance;
  TimetableService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Get Timetable for a specific class ───────────────────────────────────
  Future<TimetableModel?> getTimetable(String classId) async {
    final doc = await _firestore.collection('timetable').doc(classId).get();
    if (!doc.exists) return null;
    return TimetableModel.fromMap(classId, doc.data()!);
  }

  // ─── Save Timetable ─────────────────────────────────────────────────────────
  Future<void> saveTimetable(TimetableModel timetable) async {
    await _firestore.collection('timetable').doc(timetable.classId).set(timetable.toMap());
  }

  // ─── Conflict Check ────────────────────────────────────────────────────────
  Future<List<String>> checkTeacherConflict({
    required String teacherId,
    required String day,
    required int startTime,
    required int endTime,
    required String currentClassId,
  }) async {
    final conflicts = <String>[];
    
    // Query all timetables to find if this teacher is assigned elsewhere at this time
    final snapshot = await _firestore.collection('timetable').get();
    
    for (var doc in snapshot.docs) {
      if (doc.id == currentClassId) continue; // Skip current class
      
      final data = doc.data();
      if (!data.containsKey(day)) continue;
      
      final periods = (data[day] as List)
          .map((p) => PeriodModel.fromMap(p as Map<String, dynamic>))
          .toList();
          
      for (var p in periods) {
        if (p.teacherId == teacherId) {
          // Check for time overlap
          // (StartA < EndB) and (EndA > StartB)
          if (startTime < p.endTime && endTime > p.startTime) {
            conflicts.add('Class: ${doc.id} (${p.subject} @ ${p.startTimeStr} - ${p.endTimeStr})');
          }
        }
      }
    }
    
    return conflicts;
  }
}
