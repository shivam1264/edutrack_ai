import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BattleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<String> createRoom({
    required String hostId,
    required String hostName,
    required String quizId,
    required String quizTitle,
  }) async {
    final roomId = _uuid.v4();
    await _db.collection('battle_rooms').doc(roomId).set({
      'id': roomId,
      'host_id': hostId,
      'host_name': hostName,
      'quiz_id': quizId,
      'quiz_title': quizTitle,
      'players': [
        {'id': hostId, 'name': hostName, 'score': 0, 'status': 'waiting'}
      ],
      'status': 'waiting', // waiting, active, finished
      'created_at': FieldValue.serverTimestamp(),
    });
    return roomId;
  }

  Future<void> joinRoom(String roomId, String playerId, String playerName) async {
    await _db.collection('battle_rooms').doc(roomId).update({
      'players': FieldValue.arrayUnion([
        {'id': playerId, 'name': playerName, 'score': 0, 'status': 'waiting'}
      ]),
      'status': 'active', // Automatically start when 2nd player joins for now
    });
  }

  Stream<DocumentSnapshot> streamRoom(String roomId) {
    return _db.collection('battle_rooms').doc(roomId).snapshots();
  }

  Future<void> updateScore(String roomId, String playerId, int newScore) async {
    final doc = await _db.collection('battle_rooms').doc(roomId).get();
    if (!doc.exists) return;

    List players = doc.data()?['players'] ?? [];
    for (var p in players) {
      if (p['id'] == playerId) {
        p['score'] = newScore;
      }
    }

    await _db.collection('battle_rooms').doc(roomId).update({'players': players});
  }
}
