import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String standard;
  final String? section;
  final String schoolId;

  ClassModel({
    required this.id,
    required this.standard,
    this.section,
    required this.schoolId,
  });

  String get displayName => section != null && section!.isNotEmpty 
      ? '$standard - $section' 
      : standard;

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      standard: map['standard'] ?? '',
      section: map['section'],
      schoolId: map['school_id'] ?? 'SCH001',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'standard': standard,
      'section': section,
      'school_id': schoolId,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}

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
