import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BulkGradeScreen extends StatefulWidget {
  const BulkGradeScreen({super.key});

  @override
  State<BulkGradeScreen> createState() => _BulkGradeScreenState();
}

class _BulkGradeScreenState extends State<BulkGradeScreen> {
  String? _selectedAssignmentId;
  List<QueryDocumentSnapshot> _assignments = [];
  List<QueryDocumentSnapshot> _students = [];
  final Map<String, TextEditingController> _gradeControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';
    final snap = await FirebaseFirestore.instance
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .where('teacherId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    
    setState(() {
      _assignments = snap.docs;
      if (_assignments.isNotEmpty) {
        _selectedAssignmentId = _assignments.first.id;
        _loadStudentsAndGrades(classId);
      }
    });
  }

  Future<void> _loadStudentsAndGrades(String classId) async {
    if (_selectedAssignmentId == null) return;
    
    // Get all students in the class
    final studentSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('classId', isEqualTo: classId)
        .where('role', isEqualTo: 'student')
        .get();
    
    setState(() {
      _students = studentSnap.docs;
      for (var s in _students) {
        _gradeControllers[s.id] = TextEditingController();
      }
    });

    // Populate existing grades
    final submissionSnap = await FirebaseFirestore.instance
        .collection('assignments')
        .doc(_selectedAssignmentId)
        .collection('submissions')
        .get();

    setState(() {
      for (var doc in submissionSnap.docs) {
        final data = doc.data();
        if (data['studentId'] != null && data['grade'] != null) {
          _gradeControllers[data['studentId']]?.text = data['grade'].toString();
        }
      }
    });
  }

  Future<void> _saveBulkGrades() async {
    if (_selectedAssignmentId == null) return;
    setState(() => _isSaving = true);
    
    final batch = FirebaseFirestore.instance.batch();
    
    for (var student in _students) {
      final grade = _gradeControllers[student.id]?.text.trim();
      if (grade != null && grade.isNotEmpty) {
        final submissionRef = FirebaseFirestore.instance
            .collection('assignments')
            .doc(_selectedAssignmentId)
            .collection('submissions')
            .doc(student.id);
            
        final submissionDoc = await submissionRef.get();
        if (submissionDoc.exists) {
          batch.update(submissionRef, {
            'grade': grade,
            'status': 'graded',
            'gradedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // If student hasn't submitted but teacher is giving grade anyway (e.g. absent/0)
          batch.set(submissionRef, {
            'studentId': student.id,
            'studentName': (student.data() as Map)['name'] ?? 'Unknown',
            'grade': grade,
            'status': 'graded',
            'submittedAt': FieldValue.serverTimestamp(),
            'gradedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
    
    await batch.commit();
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ All grades saved successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var ctrl in _gradeControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFFD946EF),
            actions: [
              IconButton(
                icon: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                onPressed: _isSaving ? null : _saveBulkGrades,
                tooltip: 'Save All Grades',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD946EF), Color(0xFFEC4899)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -10, right: -10,
                      child: Icon(Icons.grading_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Bulk Grading', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          Text('Grade entire class efficiently', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Assignment', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (_assignments.isEmpty)
                    const Text('No assignments found. Please create one first.', style: TextStyle(color: Colors.red))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedAssignmentId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.assignment_rounded),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _assignments.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['title'] ?? 'Assignment', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedAssignmentId = val);
                        final classId = context.read<AuthProvider>().user?.classId ?? '';
                        _loadStudentsAndGrades(classId);
                      },
                    ),
                  const SizedBox(height: 24),
                  
                  if (_students.isNotEmpty)
                    PremiumCard(
                      opacity: 1,
                      padding: const EdgeInsets.all(0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _students.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final student = _students[i];
                          final data = student.data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: Text((data['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(data['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w700)),
                            trailing: SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _gradeControllers[student.id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '/100',
                                  filled: true,
                                  fillColor: AppTheme.bgLight,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: (i * 50).ms);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
