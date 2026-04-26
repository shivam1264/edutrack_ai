import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'take_quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  final String classId;

  const QuizListScreen({super.key, required this.classId});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Quiz Zone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<List<QuizModel>>(
              stream: QuizService().streamQuizzesByClass(widget.classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load quizzes'));
                }

                final quizzes = snapshot.data ?? [];

                final filteredQuizzes = quizzes.where((q) {
                  if (_selectedTabIndex == 0) return true;
                  if (_selectedTabIndex == 1) return q.isUpcoming || q.isActive; // Upcoming/Live
                  if (_selectedTabIndex == 2) return !q.isActive && !q.isUpcoming; // Completed
                  return true;
                }).toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      if (filteredQuizzes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No quizzes found.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                        )
                      else
                        ...filteredQuizzes.map((quiz) {
                          String timeLabel = 'Starts in';
                          String timeValue = '';
                          Color statusColor = AppTheme.primary;
                          
                          if (quiz.isActive) {
                            timeLabel = 'Status';
                            timeValue = 'LIVE';
                            statusColor = Colors.red;
                          } else if (quiz.isUpcoming) {
                            timeLabel = 'Starts at';
                            timeValue = DateFormat('hh:mm a').format(quiz.startTime);
                            statusColor = Colors.orange;
                          } else {
                            timeLabel = 'Status';
                            timeValue = 'ENDED';
                            statusColor = Colors.grey;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: quiz.isActive ? () async {
                                final result = await QuizService().getStudentResult(quizId: quiz.id, studentId: userId);
                                if (!context.mounted) return;
                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('You have already completed this quiz.'), backgroundColor: AppTheme.accent),
                                  );
                                  return;
                                }
                                Navigator.push(context, MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: quiz)));
                              } : null,
                              child: _QuizCard(
                                subject: quiz.subject,
                                title: quiz.title,
                                date: DateFormat('MMM dd, yyyy').format(quiz.startTime),
                                timeLabel: timeLabel,
                                timeValue: timeValue,
                                icon: _getIconForSubject(quiz.subject),
                                color: _getColorForSubject(quiz.subject),
                                statusColor: statusColor,
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      _buildChallengeBanner(),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            return GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: _TabItem(_tabs[index], isSelected: _selectedTabIndex == index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildChallengeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Challenge yourself!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Take a quiz and improve your score.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Start Quiz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Icon(Icons.track_changes, color: Colors.red, size: 60),
        ],
      ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Icons.calculate;
      case 'science': return Icons.science;
      case 'english': return Icons.book;
      case 'history': return Icons.history_edu;
      case 'computer': return Icons.computer;
      default: return Icons.quiz;
    }
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Colors.blue;
      case 'science': return Colors.green;
      case 'english': return Colors.orange;
      case 'history': return Colors.purple;
      case 'computer': return Colors.teal;
      default: return AppTheme.primary;
    }
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabItem(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String subject;
  final String title;
  final String date;
  final String timeLabel;
  final String timeValue;
  final IconData icon;
  final Color color;
  final Color statusColor;

  const _QuizCard({
    required this.subject,
    required this.title,
    required this.date,
    required this.timeLabel,
    required this.timeValue,
    required this.icon,
    required this.color,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeLabel, style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
              Text(timeValue, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
