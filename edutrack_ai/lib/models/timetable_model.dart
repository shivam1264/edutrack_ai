import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableModel {
  final String classId;
  final Map<String, List<PeriodModel>> weeklySchedule; // Key: 'Monday', Value: List of periods
  final DateTime updatedAt;

  TimetableModel({
    required this.classId,
    required this.weeklySchedule,
    required this.updatedAt,
  });

  factory TimetableModel.fromMap(String classId, Map<String, dynamic> map) {
    final Map<String, List<PeriodModel>> schedule = {};
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    for (final day in days) {
      if (map.containsKey(day)) {
        schedule[day] = (map[day] as List)
            .map((p) => PeriodModel.fromMap(p as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      } else {
        schedule[day] = [];
      }
    }

    return TimetableModel(
      classId: classId,
      weeklySchedule: schedule,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    weeklySchedule.forEach((day, periods) {
      map[day] = periods.map((p) => p.toMap()).toList();
    });
    return map;
  }
}

class PeriodModel {
  final String subject;
  final String teacherId;
  final String teacherName;
  final String? room;
  final int startTime; // Minutes from midnight (e.g., 9:00 AM = 540)
  final int endTime;   // Minutes from midnight (e.g., 9:45 AM = 585)

  PeriodModel({
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    this.room,
    required this.startTime,
    required this.endTime,
  });

  factory PeriodModel.fromMap(Map<String, dynamic> map) {
    return PeriodModel(
      subject: map['subject'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? (map['teacher'] ?? 'AI Faculty'),
      room: map['room'],
      startTime: map['startTime'] is int ? map['startTime'] : _parseTimeToMinutes(map['startTime']),
      endTime: map['endTime'] is int ? map['endTime'] : _parseTimeToMinutes(map['endTime']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  static int _parseTimeToMinutes(dynamic time) {
    if (time == null) return 0;
    if (time is int) return time;
    try {
      // Logic for backward compatibility with "9:00 AM" strings
      final str = time.toString().toLowerCase();
      final parts = str.split(':');
      int h = int.parse(parts[0]);
      int m = 0;
      if (parts[1].contains(' ')) {
        final mParts = parts[1].split(' ');
        m = int.parse(mParts[0]);
        if (mParts[1].contains('pm') && h < 12) h += 12;
        if (mParts[1].contains('am') && h == 12) h = 0;
      } else {
        m = int.parse(parts[1].substring(0, 2));
      }
      return (h * 60) + m;
    } catch (_) {
      return 0;
    }
  }

  String get startTimeStr => _minutesToTime(startTime);
  String get endTimeStr => _minutesToTime(endTime);

  static String _minutesToTime(int total) {
    int h = total ~/ 60;
    int m = total % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  }
}
