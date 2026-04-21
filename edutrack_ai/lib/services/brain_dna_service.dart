import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/knowledge_node.dart';

class BrainDNAService {
  static final BrainDNAService instance = BrainDNAService._internal();
  factory BrainDNAService() => instance;
  BrainDNAService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Get Student Brain DNA ──────────────────────────────────────────────────
  Stream<List<KnowledgeNode>> getBrainDNA(String studentId) {
    return _db
        .collection('users')
        .doc(studentId)
        .collection('brain_dna')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => KnowledgeNode.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ─── Update Node Mastery ────────────────────────────────────────────────────
  Future<void> updateNodeMastery({
    required String studentId,
    required String subject,
    required String topic,
    required double performance, // 0.0 to 1.0 (e.g. quiz score pct)
  }) async {
    final docId = '${subject}_${topic}'.replaceAll(' ', '_').toLowerCase();
    final docRef = _db
        .collection('users')
        .doc(studentId)
        .collection('brain_dna')
        .doc(docId);

    final docSnap = await docRef.get();
    
    double currentMastery = 0.0;
    if (docSnap.exists) {
      currentMastery = (docSnap.data()!['mastery_score'] ?? 0.0).toDouble();
    }

    // Weighted update logic: Growth depends on performance
    // If performance is high, mastery increases. If low, it dips slightly but not much 
    // to keep it encouraging.
    double newMastery = (currentMastery * 0.7) + (performance * 0.3);
    if (newMastery > 1.0) newMastery = 1.0;

    String status = 'learning';
    if (newMastery >= 0.8) status = 'mastered';
    else if (newMastery < 0.4) status = 'struggling';

    await docRef.set({
      'name': topic,
      'subject': subject,
      'mastery_score': newMastery,
      'retention_factor': 1.0, // Reset retention on activity
      'last_activity': FieldValue.serverTimestamp(),
      'status': status,
    }, SetOptions(merge: true));
  }

  // ─── Apply Forgetting Curve (Batch Process Simulation) ──────────────────────
  Future<void> applyForgettingCurve(String studentId) async {
    final snap = await _db
        .collection('users')
        .doc(studentId)
        .collection('brain_dna')
        .get();

    final now = DateTime.now();
    final batch = _db.batch();

    for (var doc in snap.docs) {
      final data = doc.data();
      final lastActivity = (data['last_activity'] as Timestamp?)?.toDate() ?? now;
      final daysSince = now.difference(lastActivity).inDays;

      if (daysSince > 2) {
        // Retention drops after 2 days of inactivity
        double currentRetention = (data['retention_factor'] ?? 1.0).toDouble();
        double decay = 0.05 * (daysSince / 2); // 5% drop every 2 idle days
        double newRetention = (currentRetention - decay).clamp(0.1, 1.0);
        
        String status = data['status'];
        if (newRetention < 0.5 && status != 'struggling') {
          status = 'fading';
        }

        batch.update(doc.reference, {
          'retention_factor': newRetention,
          'status': status,
        });
      }
    }
    await batch.commit();
  }

  // ─── Initial DNA Setup ─────────────────────────────────────────────────────
  Future<void> initializeDNA(String studentId, List<String> subjects) async {
    final defaultTopics = {
      'Mathematics': ['Algebra', 'Geometry', 'Calculus', 'Statistics'],
      'Science': ['Physics', 'Chemistry', 'Biology', 'Environment'],
      'English': ['Grammar', 'Literature', 'Vocabulary', 'Writing'],
      'Computer Science': ['Programming', 'Data Structures', 'AI Basics', 'Networking'],
    };

    final batch = _db.batch();
    for (var sub in subjects) {
      final topics = defaultTopics[sub] ?? ['General Concepts'];
      for (var topic in topics) {
        final docId = '${sub}_${topic}'.replaceAll(' ', '_').toLowerCase();
        final docRef = _db
            .collection('users')
            .doc(studentId)
            .collection('brain_dna')
            .doc(docId);
        
        batch.set(docRef, {
          'name': topic,
          'subject': sub,
          'mastery_score': 0.1, // Start small
          'retention_factor': 1.0,
          'last_activity': FieldValue.serverTimestamp(),
          'status': 'learning',
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }
}
