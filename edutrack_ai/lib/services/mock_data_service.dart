import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';
import '../models/study_plan_model.dart';
import '../models/doubt_model.dart';
import '../models/knowledge_node.dart';

class MockDataService {
  static final MockDataService instance = MockDataService._internal();
  factory MockDataService() => instance;
  MockDataService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Stream Notes (Personal + Class Resources) ───────────────────
  Stream<List<NoteModel>> streamNotes(String userId, {String? classId}) {
    // We want to see notes created by the student OR notes assigned to their class by a teacher
    return _db
        .collection('notes')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NoteModel.fromMap(doc.id, doc.data()))
            .where((n) => n.studentId == userId || n.classId == classId)
            .toList());
  }

  // ─── Stream Study Tasks ──────────────────────────────────
  Stream<List<StudyTaskModel>> streamStudyTasks(String userId) {
    return _db
        .collection('study_tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => StudyTaskModel.fromMap(doc.id, doc.data())).toList());
  }

  // ─── Stream Doubts ────────────────────────────────────
  Stream<List<DoubtModel>> streamDoubts(String userId) {
    return _db
        .collection('doubts')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DoubtModel.fromMap(doc.id, doc.data()))
            .where((d) => d.studentId == userId)
            .toList());
  }

  // ─── Stream Knowledge Nodes ───────────────────
  Stream<List<KnowledgeNode>> streamKnowledgeNodes(String userId) {
    return _db
        .collection('knowledge_nodes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => KnowledgeNode.fromMap(doc.id, doc.data())).toList());
  }
}
