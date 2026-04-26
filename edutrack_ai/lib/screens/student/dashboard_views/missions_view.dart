import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/gamification_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/screens/assignments/student_assignments_screen.dart';
import 'package:edutrack_ai/screens/quiz/quiz_list_screen.dart';
import 'package:edutrack_ai/screens/quiz/battle_lobby_screen.dart';
import 'package:edutrack_ai/screens/student/notes_library_screen.dart';
import 'package:edutrack_ai/screens/student/doubt_box_screen.dart';
import 'package:edutrack_ai/screens/student/timetable_screen.dart';
import 'package:edutrack_ai/screens/student/leaderboard_screen.dart';
import 'package:edutrack_ai/screens/student/achievements_screen.dart';
import 'package:edutrack_ai/screens/student/ai_viva_screen.dart';
import 'package:edutrack_ai/screens/student/ai_mindmap_screen.dart';
import 'package:edutrack_ai/screens/student/flashcard_generator_screen.dart';
import 'package:edutrack_ai/screens/planner/smart_planner_screen.dart';
import 'package:edutrack_ai/screens/homework/homework_chat_screen.dart';
import 'package:edutrack_ai/screens/student/my_batch_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MissionsView extends StatefulWidget {
  const MissionsView({super.key});

  @override
  State<MissionsView> createState() => _MissionsViewState();
}

class _MissionsViewState extends State<MissionsView> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'AI Power', 'Practice', 'Learn', 'Class'];

  void _navigate(BuildContext context, String label) {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';
    Widget? screen;

    switch (label) {
      case 'AI Tutor':
        screen = const HomeworkChatScreen();
        break;
      case 'AI Flashcards':
        screen = const FlashcardGeneratorScreen();
        break;
      case 'AI Mind Maps':
        screen = const AIMindMapScreen();
        break;
      case 'AI Battle':
        screen = const BattleLobbyScreen();
        break;
      case 'AI Viva':
        screen = const AIVivaScreen();
        break;
      case 'Assignments':
        screen = const StudentAssignmentsScreen();
        break;
      case 'Quizzes':
        screen = QuizListScreen(classId: classId);
        break;
      case 'Notes':
        screen = const NotesLibraryScreen();
        break;
      case 'Doubt Box':
        screen = const DoubtBoxScreen();
        break;
      case 'Leaderboard':
        screen = const LeaderboardScreen();
        break;
      case 'My Badges':
        screen = const AchievementsScreen();
        break;
      case 'Timetable':
        screen = const TimetableScreen();
        break;
      case 'My Batch':
        screen = const MyBatchScreen();
        break;
      case 'Study Plan':
        screen = const SmartPlannerScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label coming soon!'), backgroundColor: AppTheme.primary),
        );
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  @override
  Widget build(BuildContext context) {
    final gamify = context.watch<GamificationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(gamify),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabs(),
                  const SizedBox(height: 32),
                  _buildSection('AI POWERED TOOLS', [
                    _ActionItem('AI Tutor', Icons.psychology, const Color(0xFF6366F1), 'AI Power'),
                    _ActionItem('AI Flashcards', Icons.style, const Color(0xFFF59E0B), 'AI Power'),
                    _ActionItem('AI Mind Maps', Icons.account_tree, const Color(0xFF8B5CF6), 'AI Power'),
                    _ActionItem('AI Viva', Icons.record_voice_over, const Color(0xFF10B981), 'AI Power'),
                  ]),
                  const SizedBox(height: 32),
                  _buildSection('CHALLENGE & PRACTICE', [
                    _ActionItem('AI Battle', Icons.sports_esports, const Color(0xFFEF4444), 'Practice'),
                    _ActionItem('Quizzes', Icons.quiz_rounded, const Color(0xFFEC4899), 'Practice'),
                    _ActionItem('Doubt Box', Icons.question_answer, const Color(0xFF06B6D4), 'Practice'),
                    _ActionItem('Leaderboard', Icons.emoji_events, const Color(0xFFFBBF24), 'Practice'),
                  ]),
                  const SizedBox(height: 32),
                  _buildSection('MY ACADEMICS', [
                    _ActionItem('Assignments', Icons.assignment, const Color(0xFF3B82F6), 'Learn'),
                    _ActionItem('Notes', Icons.menu_book, const Color(0xFF14B8A6), 'Learn'),
                    _ActionItem('Timetable', Icons.schedule, const Color(0xFF6366F1), 'Class'),
                    _ActionItem('My Batch', Icons.groups_rounded, const Color(0xFF8B5CF6), 'Class'),
                  ]),
                  const SizedBox(height: 32),
                  _buildSection('PERSONAL GROWTH', [
                    _ActionItem('My Badges', Icons.workspace_premium, const Color(0xFFFFD700), 'Learn'),
                    _ActionItem('Study Plan', Icons.auto_graph, const Color(0xFFF43F5E), 'Learn'),
                  ]),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(GamificationProvider gamify) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.meshGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Icon(Icons.rocket_launch_rounded, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Daily Missions', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            'Level ${gamify.user?.level ?? 1} • ${gamify.user?.xp ?? 0} XP earned',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? AppTheme.softShadow(AppTheme.primary) : [],
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection(String title, List<_ActionItem> items) {
    final filteredItems = items.where((item) {
      if (_selectedTabIndex == 0) return true;
      return item.category == _tabs[_selectedTabIndex];
    }).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return GestureDetector(
              onTap: () => _navigate(context, item.label),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: item.color.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10, bottom: -10,
                      child: Icon(item.icon, size: 60, color: item.color.withOpacity(0.05)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.label,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: (index * 50).ms, curve: Curves.easeOutBack),
            );
          },
        ),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String category;

  _ActionItem(this.label, this.icon, this.color, this.category);
}
