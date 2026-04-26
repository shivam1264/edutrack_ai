import 'package:flutter/material.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/screens/attendance/teacher_attendance_screen.dart';
import 'package:edutrack_ai/screens/attendance/attendance_history_screen.dart';
import 'package:edutrack_ai/screens/assignments/teacher_assignments_screen.dart';
import 'package:edutrack_ai/screens/quiz/teacher_quizzes_screen.dart';
import 'package:edutrack_ai/screens/teacher/bulk_grade_screen.dart';
import 'package:edutrack_ai/screens/teacher/upload_notes_screen.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_ai_assistant_screen.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_communication_screen.dart';
import 'package:edutrack_ai/screens/assignments/assignment_audit_screen.dart';
import 'package:edutrack_ai/screens/student/notes_library_screen.dart';

class TeacherClassroomView extends StatelessWidget {
  final String? selectedClassId;
  final String currentClassName;

  const TeacherClassroomView({
    super.key,
    required this.selectedClassId,
    required this.currentClassName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Classroom Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your classroom activities and students',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildSection('Academic Tools', [
              _buildActionItem('Assignments', 'View and manage assignments', Icons.assignment_rounded, Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAssignmentsScreen(classId: selectedClassId ?? '')));
              }),
              _buildActionItem('Quizzes', 'Create and grade quizzes', Icons.quiz_rounded, Colors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherQuizzesScreen(classId: selectedClassId ?? '')));
              }),
              _buildActionItem('Study Materials', 'Upload and share notes', Icons.note_add_rounded, Colors.indigo, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => UploadNotesScreen(classId: selectedClassId ?? '')));
              }),
              _buildActionItem('AI Assistant', 'Get help with teaching', Icons.auto_awesome_rounded, Colors.purple, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAIAssistantScreen(classId: selectedClassId ?? '')));
              }),
            ]),
            const SizedBox(height: 24),
            _buildSection('Attendance & Communication', [
              _buildActionItem('Mark Attendance', 'Take today\'s attendance', Icons.how_to_reg_rounded, Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(classId: selectedClassId ?? '', className: currentClassName)));
              }),
              _buildActionItem('History', 'View attendance logs', Icons.history_rounded, Colors.teal, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceHistoryScreen(initialClassId: selectedClassId ?? '')));
              }),
              _buildActionItem('Chat', 'Talk to students and parents', Icons.chat_bubble_outline_rounded, Colors.blueAccent, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherCommunicationScreen(classId: selectedClassId ?? '')));
              }),
            ]),
            const SizedBox(height: 24),
            _buildSection('Evaluation', [
              _buildActionItem('Grade Submissions', 'Review and grade submissions', Icons.grading_rounded, Colors.orange, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => AssignmentAuditScreen(classId: selectedClassId ?? '')));
              }),
              _buildActionItem('Bulk Grading', 'Grade multiple submissions', Icons.auto_awesome_motion_rounded, Colors.purple, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkGradeScreen()));
              }),
            ]),
            const SizedBox(height: 24),
            _buildSection('Resources', [
              _buildActionItem('Resource Library', 'View and share resources', Icons.folder_shared_rounded, Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotesLibraryScreen(classId: selectedClassId)));
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
      ),
    );
  }
}
