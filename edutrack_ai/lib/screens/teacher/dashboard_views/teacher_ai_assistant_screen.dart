import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../lesson_planner_screen.dart';
import '../upload_notes_screen.dart';
import '../smart_analysis_screen.dart';

class TeacherAIAssistantScreen extends StatelessWidget {
  final String classId;

  const TeacherAIAssistantScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Smart tools for teachers',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildAIAction(
            context,
            'AI Lesson Plan',
            'Generate lesson plans in seconds',
            Icons.auto_awesome_rounded,
            const Color(0xFF8B5CF6),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPlannerScreen(classId: classId))),
          ),
          const SizedBox(height: 16),
          _buildAIAction(
            context,
            'Smart Analysis',
            'Analyze student performance',
            Icons.insights_rounded,
            const Color(0xFFD946EF),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => SmartAnalysisScreen(classId: classId))),
          ),
          const SizedBox(height: 16),
          _buildAIAction(
            context,
            'Upload Notes',
            'Upload and organize notes',
            Icons.upload_file_rounded,
            const Color(0xFF059669),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadNotesScreen(classId: classId))),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAction(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
