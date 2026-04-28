import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/screens/parent/parent_ai_chat_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_assignments_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_chat_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_leave_request_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_reports_screen.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class ParentInsightsView extends StatelessWidget {
  const ParentInsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty)
        ? user.parentOf!.first
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'AI Insights & Actions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Focused parent actions for support, reports, and communication.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _actionItem(
                  context,
                  'AI Assistant',
                  'Ask questions about progress and learning.',
                  Icons.psychology_rounded,
                  AppTheme.primary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentAIChatScreen(studentId: childId),
                    ),
                  ),
                ),
                _actionItem(
                  context,
                  'Assignments',
                  'Review pending and completed work.',
                  Icons.edit_note_rounded,
                  AppTheme.secondary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentAssignmentsScreen(),
                    ),
                  ),
                ),
                _actionItem(
                  context,
                  'Reports',
                  'Open academic summaries and detailed reports.',
                  Icons.analytics_rounded,
                  AppTheme.info,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentReportsScreen(),
                    ),
                  ),
                ),
                _actionItem(
                  context,
                  'Leave Request',
                  'Submit absence requests for your child.',
                  Icons.event_busy_rounded,
                  AppTheme.parentColor,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentLeaveRequestScreen(),
                    ),
                  ),
                ),
                _actionItem(
                  context,
                  'Teacher Chat',
                  'Message the class teacher directly.',
                  Icons.forum_rounded,
                  AppTheme.accent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentChatScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PremiumCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI guidance is available throughout the dashboard.',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Use it when you need quick interpretation, not as a replacement for teacher context.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(
    BuildContext context,
    String label,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
