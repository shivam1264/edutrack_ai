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
  int get xpToNextLevel {
    if (_user == null) return 100;
    return _user!.level * 250; 
  }

  double get progressToNextLevel {
    if (_user == null || _user!.xp == 0) return 0.0;
    // Simple linear progress for current level
    final currentLevelBase = (_user!.level - 1) * 250;
    final relativeXp = _user!.xp - currentLevelBase;
    final requiredXp = 250;
    return (relativeXp / requiredXp).clamp(0.0, 1.0);
  }

  String get rankName {
    if (_user == null) return 'Initiate';
    if (_user!.level >= 10) return 'Neural Archon';
    if (_user!.level >= 7) return 'Master Scholar';
    if (_user!.level >= 4) return 'Elite Learner';
    return 'Initiate';
  }

  Future<void> addXp(String uid, int amount) async {
    if (_user == null) return;

    final newXp = _user!.xp + amount;
    int newLevel = _user!.level;

    // Level up logic
    while (newXp >= newLevel * 250) {
      newLevel++;
    }

    final updateData = {
      'xp': newXp,
      'level': newLevel,
    };

    // If level increased, maybe add a badge?
    if (newLevel > _user!.level) {
      // Future: Trigger level up animation flag
    }

    await _db.collection('users').doc(uid).update(updateData);
  }

  Future<void> awardBadge(String uid, String badgeId) async {
    if (_user == null || _user!.badges.contains(badgeId)) return;

    await _db.collection('users').doc(uid).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }
}
