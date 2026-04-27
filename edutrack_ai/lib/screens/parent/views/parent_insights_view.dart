import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edutrack_ai/screens/parent/parent_leave_request_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_chat_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_ai_chat_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_fee_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_reports_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_assignments_screen.dart';
import 'package:edutrack_ai/screens/parent/views/parent_updates_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_child_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_profile_view.dart';

class ParentInsightsView extends StatelessWidget {
  const ParentInsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Parent Actions', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _actionItem(context, 'Chat with AI', Icons.psychology_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAIChatScreen(studentId: childId)))),
                _actionItem(context, 'HW Assist', Icons.edit_note_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentAssignmentsScreen()))),
                _actionItem(context, 'Report', Icons.analytics_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentReportsScreen()))),
                _actionItem(context, 'Leave Request', Icons.event_busy_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentLeaveRequestScreen()))),
                _actionItem(context, 'Fee Payment', Icons.payments_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentFeeScreen()))),
                _actionItem(context, 'Teacher Chat', Icons.forum_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentChatScreen()))),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Need help?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Our AI assistant is here to help you 24/7.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAIChatScreen(studentId: childId))),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Chat Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.support_agent_rounded, color: Colors.white54, size: 80),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
