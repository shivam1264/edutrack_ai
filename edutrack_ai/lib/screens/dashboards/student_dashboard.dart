import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../assignments/student_assignments_screen.dart';
import '../quiz/quiz_list_screen.dart';
import '../quiz/battle_lobby_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../homework/homework_chat_screen.dart';
import '../planner/smart_planner_screen.dart';
import '../../providers/gamification_provider.dart';
import '../student/leaderboard_screen.dart';
import '../student/doubt_box_screen.dart';
import '../student/notes_library_screen.dart';
import '../student/timetable_screen.dart';
import '../student/achievements_screen.dart';
import '../student/flashcard_generator_screen.dart';
import '../student/ai_viva_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<AnalyticsProvider>().loadStudentAnalytics(user.uid);
        context.read<GamificationProvider>().updateUserData(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final classId = user?.classId ?? '';

    switch (_currentIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return const StudentAssignmentsScreen();
      case 2:
        return const BattleLobbyScreen();
      case 3:
        return _buildProfileView();
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    final auth = context.watch<AuthProvider>();
    final analytics = context.watch<AnalyticsProvider>();
    final user = auth.user;
    final data = analytics.studentAnalytics;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          floating: false,
          pinned: true,
          stretch: true,
          backgroundColor: AppTheme.primary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                Positioned(
                  top: -20,
                  right: -20,
                  child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.1)),
                ),
                Positioned(
                  bottom: 20,
                  left: -30,
                  child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.05)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${user?.name.split(' ').first ?? 'Student'}!',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '${context.watch<GamificationProvider>().rankName} • Level ${user?.level ?? 1}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                // XP Progress Bar
                                _buildXPBar(context),
                              ],
                            ),
                          ),
                          const NotificationBell(userId: ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (analytics.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
              else ...[
                if (analytics.aiPrediction != null)
                  _buildAIBadge(analytics.aiPrediction).animate().fadeIn().slideX(begin: 0.2),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PremiumCard(
                        opacity: 1,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_graph_rounded, color: AppTheme.primary, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '${(data?['avg_score'] as num? ?? 0).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            const Text('Avg Grade', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PremiumCard(
                        opacity: 1,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            const Icon(Icons.rocket_launch_rounded, color: AppTheme.secondary, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '${data?['submitted_count'] ?? 0}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            const Text('Quests Done', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn().scale(),
                const SizedBox(height: 24),
                const Text('Learning Trajectory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                PremiumCard(opacity: 1, child: _buildQuizTrendCard(data)),
                const SizedBox(height: 24),
                const Text('Skill Proficiency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                PremiumCard(opacity: 1, child: _buildSubjectBarChart(data)),
                const SizedBox(height: 24),
                _buildQuickActions(context),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildXPBar(BuildContext context) {
    final gamify = context.watch<GamificationProvider>();
    final progress = gamify.progressToNextLevel;
    final user = context.watch<AuthProvider>().user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 6,
              width: 180,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 6,
              width: 180 * progress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accent, Colors.white]),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 4)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'XP: ${user?.xp ?? 0} / ${gamify.xpToNextLevel}',
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    final user = context.watch<AuthProvider>().user;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Agent Profile', style: TextStyle(fontWeight: FontWeight.w900)),
            background: Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(user?.name[0].toUpperCase() ?? 'S', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    ),
                    const SizedBox(height: 20),
                    Text(user?.name ?? 'Student Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    Text(user?.email ?? 'email@edutrack.com', style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 20),
              _buildProfileItem(Icons.school_rounded, 'Class', user?.classId ?? 'N/A'),
              _buildProfileItem(Icons.fingerprint_rounded, 'Student ID', user?.uid.substring(0, 8).toUpperCase() ?? 'N/A'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                child: const Text('Logout from Hub'),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBadge(Map<String, dynamic>? prediction) {
    if (prediction == null) return const SizedBox.shrink();
    final risk = prediction['risk_level'] as String? ?? 'low';
    if (risk == 'low') return const SizedBox.shrink();

    final isHigh = risk == 'high';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isHigh
            ? AppTheme.dangerGradient
            : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: (isHigh ? Colors.red : Colors.orange).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(isHigh ? Icons.auto_awesome_outlined : Icons.insights_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh ? 'Urgent: High Performance Risk' : 'AI Performance Forecast',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  'Final grade estimate: ${(prediction['predicted_final_grade'] as num?)?.toStringAsFixed(1) ?? '--'}%',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTrendCard(Map<String, dynamic>? data) {
    final scores = (data?['last_5_scores'] as List<dynamic>? ?? []).map((s) => (s as num).toDouble()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: scores.isEmpty
              ? const Center(child: Text('Build your path by taking a quiz!', style: TextStyle(color: AppTheme.textSecondary)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: AppTheme.primary,
                        barWidth: 5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [AppTheme.primary.withOpacity(0.3), AppTheme.primary.withOpacity(0.0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectBarChart(Map<String, dynamic>? data) {
    final subjectAvg = (data?['subject_avg'] as Map<String, dynamic>? ?? {});
    final entries = subjectAvg.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: entries.isEmpty
              ? const Center(child: Text('Complete subjects to see performance', style: TextStyle(color: AppTheme.textSecondary)))
              : BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= entries.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                entries[value.toInt()].key.substring(0, 3).toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: entries
                        .asMap()
                        .entries
                        .map((e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (e.value.value as num).toDouble(),
                                  gradient: LinearGradient(
                                    colors: e.value.value < 60
                                        ? [AppTheme.danger, AppTheme.danger.withOpacity(0.6)]
                                        : [AppTheme.primary, AppTheme.primaryLight],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';

    final actions = [
      {
        'icon': Icons.auto_awesome_mosaic_rounded,
        'label': 'Assignments',
        'color': AppTheme.primary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen())),
      },
      {
        'icon': Icons.record_voice_over_rounded,
        'label': 'AI Viva',
        'color': Colors.teal,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIVivaScreen())),
      },
      {
        'icon': Icons.quiz_rounded,
        'label': 'Quizzes',
        'color': const Color(0xFFE11D48),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizListScreen(classId: classId))),
      },
      {
        'icon': Icons.bolt_rounded,
        'label': 'Challenge',
        'color': AppTheme.accent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BattleLobbyScreen())),
      },
      {
        'icon': Icons.style_rounded,
        'label': 'Flashcards',
        'color': Colors.deepOrange,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardGeneratorScreen())),
      },
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Attend',
        'color': AppTheme.secondary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAttendanceScreen())),
      },
      {
        'icon': Icons.psychology_rounded,
        'label': 'AI Tutor',
        'color': AppTheme.warning,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkChatScreen())),
      },
      {
        'icon': Icons.stars_rounded,
        'label': 'Study Plan',
        'color': const Color(0xFF8B5CF6),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartPlannerScreen())),
      },
      {
        'icon': Icons.emoji_events_rounded,
        'label': 'Leaderboard',
        'color': const Color(0xFFFF6B35),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
      },
      {
        'icon': Icons.help_center_rounded,
        'label': 'Doubt Box',
        'color': const Color(0xFF7C3AED),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtBoxScreen())),
      },
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Notes',
        'color': const Color(0xFF059669),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesLibraryScreen())),
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Timetable',
        'color': const Color(0xFF0F766E),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen())),
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'label': 'Badges',
        'color': const Color(0xFFD97706),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mission Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: action['onTap'] as VoidCallback,
              child: PremiumCard(
                opacity: 1,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: (action['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: (action['color'] as Color)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 100).ms).scale();
          },
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary.withOpacity(0.5),
      elevation: 0,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.rocket_launch_rounded), label: 'Tasks'),
        BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Battle'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Profile'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Hub?'),
        content: const Text('Are you sure you want to exit your academic mission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
