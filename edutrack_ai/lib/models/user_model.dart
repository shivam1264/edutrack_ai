import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, teacher, student, parent }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String schoolId;
  final DateTime createdAt;
  final String? fcmToken;
  final String? avatarUrl;
  final String? phone;
  final String? classId;       // for students
  final String? rollNo;        // for students: roll number
  final List<String>? assignedClasses; // for teachers: multiple hubs
  final List<String>? parentOf; // for parents: list of child student_ids
  final List<String>? subjects; // for teachers: list of assigned subjects
  final int xp;                // For gamification
  final int level;             // For gamification
  final int streak;            // For gamification
  final List<String> badges;   // For gamification

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.schoolId,
    required this.createdAt,
    this.fcmToken,
    this.avatarUrl,
    this.phone,
    this.classId,
    this.rollNo,
    this.assignedClasses,
    this.parentOf,
    this.subjects,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.badges = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: _parseRole(map['role']),
      schoolId: map['school_id'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: map['fcm_token'],
      avatarUrl: map['avatar_url'],
      phone: map['phone'],
      classId: map['class_id'],
      rollNo: map['roll_no'],
      assignedClasses: _parseAssignedClasses(map),
      parentOf: _parseParentOf(map['parent_of']),
      subjects: map['subjects'] != null ? List<String>.from(map['subjects']) : null,
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      streak: map['streak'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'school_id': schoolId,
      'created_at': Timestamp.fromDate(createdAt),
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (classId != null) 'class_id': classId,
      if (rollNo != null) 'roll_no': rollNo,
      if (assignedClasses != null && assignedClasses!.isNotEmpty) 'assigned_classes': assignedClasses,
      if (parentOf != null && parentOf!.isNotEmpty) 'parent_of': parentOf,
      if (subjects != null && subjects!.isNotEmpty) 'subjects': subjects,
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      default:
        return UserRole.student;
      }
  }

  static List<String>? _parseParentOf(dynamic value) {
    if (value == null) return null;
    if (value is String) return [value];
    if (value is List) return List<String>.from(value);
    return null;
  }

  static List<String>? _parseAssignedClasses(Map<String, dynamic> map) {
    final assigned = map['assigned_classes'];
    if (assigned is List) return List<String>.from(assigned);
    
    // Legacy support for teachers who only had a single classId
    final legacyClass = map['class_id'];
    final role = map['role'];
    if (role == 'teacher' && legacyClass is String && legacyClass.isNotEmpty) {
      return [legacyClass];
    }
    return null;
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? schoolId,
    DateTime? createdAt,
    String? fcmToken,
    String? avatarUrl,
    String? phone,
    String? classId,
    String? rollNo,
    List<String>? assignedClasses,
    List<String>? parentOf,
    int? xp,
    int? level,
    List<String>? badges,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      classId: classId ?? this.classId,
      rollNo: rollNo ?? this.rollNo,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      parentOf: parentOf ?? this.parentOf,
      subjects: subjects ?? this.subjects,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      badges: badges ?? this.badges,
    );
  }
}
