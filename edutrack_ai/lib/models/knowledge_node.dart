import 'package:cloud_firestore/cloud_firestore.dart';

class KnowledgeNode {
  final String id;
  final String name;
  final String subject;
  final double masteryScore; // 0.0 to 1.0
  final double retentionFactor; // Calculated based on forgetting curve
  final DateTime lastActivity;
  final String status; // 'mastered', 'learning', 'struggling', 'fading'

  KnowledgeNode({
    required this.id,
    required this.name,
    required this.subject,
    required this.masteryScore,
    required this.retentionFactor,
    required this.lastActivity,
    required this.status,
  });

  factory KnowledgeNode.fromMap(String id, Map<String, dynamic> map) {
    return KnowledgeNode(
      id: id,
      name: map['name'] ?? 'Topic',
      subject: map['subject'] ?? 'General',
      masteryScore: (map['mastery_score'] ?? 0.0).toDouble(),
      retentionFactor: (map['retention_factor'] ?? 1.0).toDouble(),
      lastActivity: (map['last_activity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'learning',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'mastery_score': masteryScore,
      'retention_factor': retentionFactor,
      'last_activity': Timestamp.fromDate(lastActivity),
      'status': status,
    };
  }
}
