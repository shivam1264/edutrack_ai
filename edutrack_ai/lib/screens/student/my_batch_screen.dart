import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'student_teacher_chat_screen.dart';

class MyBatchScreen extends StatelessWidget {
  const MyBatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';
    
    if (classId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Batch')),
        body: const Center(child: Text('No class assigned yet.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('My Batch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBatchHeader(classId),
            const SizedBox(height: 32),
            const Text('BATCH TEACHERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.textHint)),
            const SizedBox(height: 16),
            _buildTeachersList(classId),
            const SizedBox(height: 32),
            const Text('CLASSMATES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.textHint)),
            const SizedBox(height: 16),
            _buildClassmatesList(classId, user?.uid ?? ''),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchHeader(String classId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').doc(classId).snapshots(),
      builder: (context, snapshot) {
        final classData = snapshot.data?.data() as Map<String, dynamic>?;
        String className = classId;
        if (classData != null) {
          final standard = classData['standard'] ?? '';
          final section = classData['section'] ?? '';
          className = section.isNotEmpty ? '$standard - $section' : standard;
        }

        return PremiumCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch $className', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(_academicYearLabel(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTeachersList(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('assigned_classes', arrayContains: classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final teachers = snapshot.data?.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>)).toList() ?? [];

        if (teachers.isEmpty) {
          return const Center(child: Text('No teachers assigned to this class.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)));
        }

        return Column(
          children: teachers.map((teacher) {
            final subjectStr = (teacher.subjects ?? []).join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(teacher.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subjectStr.isNotEmpty ? subjectStr : 'General Subjects', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentTeacherChatScreen(
                            teacherId: teacher.uid,
                            teacherName: teacher.name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildClassmatesList(String classId, String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('class_id', isEqualTo: classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final classmates = snapshot.data?.docs
            .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
            .where((s) => s.uid != currentUserId)
            .toList() ?? [];

        if (classmates.isEmpty) {
          return const Center(child: Text('No classmates found.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)));
        }

        return PremiumCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: classmates.map((student) => ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.secondary.withOpacity(0.1),
                child: Text(student.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              ),
              title: Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Online', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  String _academicYearLabel() {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final endYear = (startYear + 1).toString().substring(2);
    return 'Academic Year $startYear-$endYear';
  }
}
