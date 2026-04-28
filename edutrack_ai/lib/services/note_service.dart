import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Stream Notes for Class ──────────────────────────────────────────────────
  Stream<List<NoteModel>> streamNotesByClass(String classId) {
    return _db
        .collection('notes')
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => NoteModel.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ─── Delete Note ─────────────────────────────────────────────────────────────
  Future<void> deleteNote(String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }

  // ─── Update Note ─────────────────────────────────────────────────────────────
  Future<void> updateNote(String noteId, Map<String, dynamic> updates) async {
    await _db.collection('notes').doc(noteId).update(updates);
  }
}
