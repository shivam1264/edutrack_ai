import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class GamificationProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;

  void updateUserData(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Calculate XP required for the NEXT level
  // Formula: Level * 250 (e.g., Level 1 takes 250 XP to reach Level 2)
  int get xpToNextLevel {
    if (_user == null) return 250;
    return _user!.level * 250; 
  }

  double get progressToNextLevel {
    if (_user == null) return 0.0;
    
    // Base XP for the current level
    final currentLevelBase = (_user!.level - 1) * 250;
    
    // XP earned within the current level's bucket
    final relativeXp = _user!.xp - currentLevelBase;
    
    // Total XP bucket size for this level
    const int bucketSize = 250;
    
    return (relativeXp / bucketSize).clamp(0.0, 1.0);
  }

  String get rankName {
    if (_user == null) return 'Initiate';
    if (_user!.level >= 10) return 'Neural Archon';
    if (_user!.level >= 7) return 'Master Scholar';
    if (_user!.level >= 4) return 'Elite Learner';
    return 'Initiate';
  }

  Future<void> addXp(String uid, int amount) async {
    // Note: We don't return early if _user is null because this might be called 
    // from a background trigger. We fetch current data from DB.
    
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return;
    
    final data = doc.data()!;
    int currentXp = (data['xp'] ?? 0) as int;
    int currentLevel = (data['level'] ?? 1) as int;

    final newXp = currentXp + amount;
    int newLevel = currentLevel;

    // Cumulative Level up logic: next level threshold is currentLevel * 250
    while (newXp >= newLevel * 250) {
      newLevel++;
    }

    final updateData = {
      'xp': newXp,
      'level': newLevel,
    };

    await _db.collection('users').doc(uid).update(updateData);
    
    // Update local state if this is the active user
    if (_user?.uid == uid) {
      _user = _user!.copyWith(xp: newXp, level: newLevel);
      notifyListeners();
    }
  }

  Future<void> awardBadge(String uid, String badgeId) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return;
    
    List badges = (doc.data()?['badges'] as List?) ?? [];
    if (badges.contains(badgeId)) return;

    await _db.collection('users').doc(uid).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
    
    if (_user?.uid == uid) {
      if (!_user!.badges.contains(badgeId)) {
        final newList = List<String>.from(_user!.badges)..add(badgeId);
        _user = _user!.copyWith(badges: newList);
        notifyListeners();
      }
    }
  }

  Future<List<UserModel>> getLeaderboard(String classId) async {
    try {
      final snap = await _db.collection('users')
        .where('role', isEqualTo: 'student')
        .where('class_id', isEqualTo: classId)
        .orderBy('xp', descending: true)
        .limit(10)
        .get();
        
      return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<List<UserModel>> getGlobalLeaderboard() async {
    try {
      final snap = await _db.collection('users')
        .where('role', isEqualTo: 'student')
        .orderBy('xp', descending: true)
        .limit(20)
        .get();
        
      return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching global leaderboard: $e');
      return [];
    }
  }

  Stream<List<UserModel>> streamLeaderboard(String classId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) {
          final users = snap.docs.map((doc) {
            final data = doc.data();
            // Ensure uid is present
            if (data['uid'] == null) data['uid'] = doc.id;
            return UserModel.fromMap(data);
          }).toList();
          // Sort by XP descending
          users.sort((a, b) => b.xp.compareTo(a.xp));
          return users.take(15).toList();
        });
  }

  Stream<List<UserModel>> streamSchoolLeaderboard(String schoolId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('school_id', isEqualTo: schoolId)
        .snapshots()
        .map((snap) {
          final users = snap.docs.map((doc) {
            final data = doc.data();
            if (data['uid'] == null) data['uid'] = doc.id;
            return UserModel.fromMap(data);
          }).toList();
          users.sort((a, b) => b.xp.compareTo(a.xp));
          return users.take(20).toList();
        });
  }
  Stream<List<UserModel>> streamGlobalLeaderboard() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snap) {
          final users = snap.docs.map((doc) {
            final data = doc.data();
            if (data['uid'] == null) data['uid'] = doc.id;
            return UserModel.fromMap(data);
          }).toList();
          // Sort by XP descending
          users.sort((a, b) => b.xp.compareTo(a.xp));
          return users.take(25).toList();
        });
  }
}
