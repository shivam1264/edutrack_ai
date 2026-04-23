import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

class ClassService {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ClassModel>> getClasses() {
    return _firestore.collection('classes')
        .orderBy('standard')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addClass(String standard, String? section, {String schoolId = 'SCH001'}) async {
    final model = ClassModel(
      id: '',
      standard: standard,
      section: section,
      schoolId: schoolId,
    );
    await _firestore.collection('classes').add(model.toMap());
  }

  Future<void> deleteClass(String id) async {
    await _firestore.collection('classes').doc(id).delete();
  }
}
