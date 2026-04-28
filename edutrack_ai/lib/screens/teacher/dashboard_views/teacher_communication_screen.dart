import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../doubt_answer_screen.dart';
import '../leave_approval_screen.dart';
import '../teacher_announcements_screen.dart';

import '../teacher_chat_list_screen.dart';

class TeacherCommunicationScreen extends StatelessWidget {
  final String classId;

  const TeacherCommunicationScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Communication', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Stay connected',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildCommAction(
            context,
            'Parent & Student Chat',
            'Communicate with parents and students',
            Icons.chat_bubble_rounded,
            const Color(0xFFF97316),
            0,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherChatListScreen())),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements')
                .where(Filter.or(
                  Filter('class_id', isEqualTo: classId),
                  Filter('target', isEqualTo: 'all'),
                  Filter('target', isEqualTo: 'teachers'),
                ))
                .snapshots(),

            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _buildCommAction(
                context,
                'Announcements',
                'Send updates to students',
                Icons.campaign_rounded,
                const Color(0xFF3B82F6),
                count,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAnnouncementsScreen(classId: classId))),
              );
            }
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('doubts').where('class_id', isEqualTo: classId).where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _buildCommAction(
                context,
                'Student Doubts',
                'View and respond to doubts',
                Icons.help_center_rounded,
                const Color(0xFF8B5CF6),
                count,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtAnswerScreen())),
              );
            }
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('leave_requests').where('class_id', isEqualTo: classId).where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _buildCommAction(
                context,
                'Leave Requests',
                'Manage leave approvals',
                Icons.calendar_today_rounded,
                const Color(0xFF10B981),
                count,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalScreen(classId: classId))),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCommAction(BuildContext context, String title, String subtitle, IconData icon, Color color, int count, VoidCallback onTap) {
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
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
