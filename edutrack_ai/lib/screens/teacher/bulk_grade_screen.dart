import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/assignment_model.dart'; // To use AssignmentStatus enum

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
    // Querying main assignments collection
    final snap = await FirebaseFirestore.instance
        .collection('assignments')
        .where('class_id', isEqualTo: classId)
        .where('teacher_id', isEqualTo: user?.uid)
        .orderBy('created_at', descending: true)
        .limit(20)
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
        .where('class_id', isEqualTo: classId)
        .where('role', isEqualTo: 'student')
        .get();
    
    setState(() {
      _students = studentSnap.docs;
      _gradeControllers.clear();
      for (var s in _students) {
        _gradeControllers[s.id] = TextEditingController();
      }
    });

    // FIX: Optimized query targeting the central 'submissions' collection
    final submissionSnap = await FirebaseFirestore.instance
        .collection('submissions')
        .where('assignment_id', isEqualTo: _selectedAssignmentId)
        .get();

    if (mounted) {
      setState(() {
        for (var doc in submissionSnap.docs) {
          final data = doc.data();
          final studentId = data['student_id'] as String?;
          final marks = data['marks'];
          if (studentId != null && marks != null) {
            _gradeControllers[studentId]?.text = marks.toString();
          }
        }
      });
    }
  }

  Future<void> _saveBulkGrades() async {
    if (_selectedAssignmentId == null) return;
    setState(() => _isSaving = true);
    
    final batch = FirebaseFirestore.instance.batch();
    
    try {
      for (var student in _students) {
        final marksText = _gradeControllers[student.id]?.text.trim();
        if (marksText != null && marksText.isNotEmpty) {
          final double marks = double.tryParse(marksText) ?? 0.0;
          
          // Check if submission already exists in the central registry
          final subQuery = await FirebaseFirestore.instance
              .collection('submissions')
              .where('assignment_id', isEqualTo: _selectedAssignmentId)
              .where('student_id', isEqualTo: student.id)
              .limit(1)
              .get();

          if (subQuery.docs.isNotEmpty) {
            // Update existing entry
            batch.update(subQuery.docs.first.reference, {
              'marks': marks,
              'status': 'graded',
              'graded_at': FieldValue.serverTimestamp(),
            });
          } else {
            // Force create a record (e.g. for students who didn't submit)
            final newSubRef = FirebaseFirestore.instance.collection('submissions').doc();
            batch.set(newSubRef, {
              'assignment_id': _selectedAssignmentId,
              'student_id': student.id,
              'content': '[Manual Entry - No Student Submission]',
              'marks': marks,
              'status': 'graded',
              'submitted_at': FieldValue.serverTimestamp(),
              'graded_at': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Target Sync Complete: All grades deployed. 🚀'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      setState(() => _isSaving = false);
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
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch_rounded),
                onPressed: _isSaving ? null : _saveBulkGrades,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                   Positioned(
                      top: -10, right: -10,
                      child: Icon(Icons.grading_rounded, color: Colors.white.withOpacity(0.05), size: 200),
                   ),
                   Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Bulk Grading', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          Text('Simultaneous class assessment protocol', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                   ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('ACTIVE ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.textHint, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                if (_assignments.isEmpty)
                  _buildNoAssignments()
                else
                  DropdownButtonFormField<String>(
                    value: _selectedAssignmentId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.hub_rounded, color: AppTheme.primary),
                    ),
                    items: _assignments.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['title'] ?? 'Class Assignment', style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedAssignmentId = val);
                      final classId = context.read<AuthProvider>().user?.classId ?? '';
                      _loadStudentsAndGrades(classId);
                    },
                  ),
                const SizedBox(height: 24),
                const Text('STUDENT ROSTER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.textHint, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                if (_students.isNotEmpty)
                  Column(
                    children: _students.asMap().entries.map((entry) {
                      final i = entry.key;
                      final student = entry.value;
                      final data = student.data() as Map<String, dynamic>;
                      return PremiumCard(
                        opacity: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: Text((data['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(data['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w700))),
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: _gradeControllers[student.id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                                decoration: InputDecoration(
                                  hintText: '/100',
                                  filled: true,
                                  fillColor: AppTheme.bgLight,
                                  contentPadding: const EdgeInsets.all(10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1);
                    }).toList(),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAssignments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Text('No deployments found. Please create an assignment first.', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
    );
  }
}
