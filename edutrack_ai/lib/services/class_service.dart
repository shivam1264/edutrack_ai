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

  Stream<ClassModel> getClassById(String id) {
    return _firestore.collection('classes').doc(id).snapshots().map((doc) {
      if (!doc.exists) throw 'Class not found';
      return ClassModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<ClassModel?> getClassByIdFuture(String id) async {
    final doc = await _firestore.collection('classes').doc(id).get();
    if (!doc.exists) return null;
    return ClassModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> addClass(String standard, String? section, {
    String schoolId = 'SCH001',
    String? classTeacherId,
    String? classTeacherName,
  }) async {
    // Check for existing class with same standard and section
    final query = await _firestore.collection('classes')
        .where('standard', isEqualTo: standard)
        .where('section', isEqualTo: section ?? '')
        .get();

    if (query.docs.isNotEmpty) {
      throw 'A class with this name and section already exists.';
    }

    final model = ClassModel(
      id: '',
      standard: standard,
      section: section,
      schoolId: schoolId,
      classTeacherId: classTeacherId,
      classTeacherName: classTeacherName,
    );
    await _firestore.collection('classes').add(model.toMap());
  }

  Future<void> updateClass(String id, Map<String, dynamic> data) async {
    await _firestore.collection('classes').doc(id).update(data);
  }

  Future<void> deleteClass(String id) async {
    await _firestore.collection('classes').doc(id).delete();
  }
}
