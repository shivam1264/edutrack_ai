import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'take_quiz_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizListScreen extends StatefulWidget {
  final String classId;

  const QuizListScreen({super.key, required this.classId});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Academic Battles', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
              centerTitle: true,
            ),
          ),
          StreamBuilder<List<QuizModel>>(
            stream: QuizService().streamQuizzesByClass(widget.classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              final quizzes = snapshot.data ?? [];
              if (quizzes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 80, color: AppTheme.primary.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text('No battles scheduled yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final quiz = quizzes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _QuizCard(quiz: quiz, studentId: userId).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1),
                      );
                    },
                    childCount: quizzes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final String studentId;

  const _QuizCard({required this.quiz, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final isActive = quiz.isActive;
    final isUpcoming = quiz.isUpcoming;
    
    Color badgeColor;
    String statusLabel;
    IconData statusIcon;

    if (isActive) {
      badgeColor = AppTheme.secondary;
      statusLabel = 'LIVE';
      statusIcon = Icons.sensors_rounded;
    } else if (isUpcoming) {
      badgeColor = AppTheme.primary;
      statusLabel = 'UPCOMING';
      statusIcon = Icons.calendar_today_rounded;
    } else {
      badgeColor = AppTheme.textSecondary;
      statusLabel = 'ENDED';
      statusIcon = Icons.history_rounded;
    }

    return GestureDetector(
      onTap: isActive
          ? () async {
              final result = await QuizService().getStudentResult(quizId: quiz.id, studentId: studentId);
              if (!context.mounted) return;
              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('You have already completed this battle.'),
                    backgroundColor: AppTheme.accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: quiz)));
            }
          : null,
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: badgeColor, size: 12),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(Icons.topic_rounded, quiz.subject),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.timer_rounded, '${quiz.durationMins}m'),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.help_center_rounded, '${quiz.questions.length} Qs'),
              ],
            ),
            const Divider(height: 24, color: AppTheme.borderLight),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STARTS AT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(DateFormat('dd MMM, hh:mm a').format(quiz.startTime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ),
                if (isActive)
                  ElevatedButton(
                    onPressed: () {}, // Already handled by parent GestureDetector but visual benefit
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Enter Battle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ],
    );
  }
}
