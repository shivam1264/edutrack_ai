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
  final String? classId;       // for students/teachers
  final List<String>? parentOf; // for parents: list of child student_ids
  final int xp;                // For gamification
  final int level;             // For gamification
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
    this.classId,
    this.parentOf,
    this.xp = 0,
    this.level = 1,
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
      classId: map['class_id'],
      parentOf: _parseParentOf(map['parent_of']),
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
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
      if (classId != null) 'class_id': classId,
      if (parentOf != null && parentOf!.isNotEmpty) 'parent_of': parentOf,
      'xp': xp,
      'level': level,
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
      }
  }

  static List<String>? _parseParentOf(dynamic value) {
    if (value == null) return null;
    if (value is String) return [value]; // Handle legacy single ID
    if (value is List) return List<String>.from(value);
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
    String? classId,
    String? parentOf,
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
      classId: classId ?? this.classId,
      parentOf: parentOf ?? this.parentOf,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      badges: badges ?? this.badges,
    );
  }
}
