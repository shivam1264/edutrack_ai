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
import '../student/ai_mindmap_screen.dart';
import '../../services/brain_dna_service.dart';
import '../../models/knowledge_node.dart';
import '../../widgets/brain_dna_visualizer.dart';

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

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final greetEmoji = hour < 12 ? '☀️' : hour < 17 ? '👋' : '🌙';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          stretch: true,
          backgroundColor: AppTheme.primaryDark,
          elevation: 0,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => _showLogoutDialog(context),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(gradient: AppTheme.studentGradient),
                ),
                // Decorative circles
                Positioned(
                  top: -40, right: -40,
                  child: Container(width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05))),
                ),
                Positioned(
                  bottom: -20, left: -20,
                  child: Container(width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              child: Text(
                                (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting, ${user?.name.split(' ').first ?? 'Student'}! $greetEmoji',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${context.watch<GamificationProvider>().rankName} · Lv.${user?.level ?? 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (analytics.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
              else ...[
                // AI Badge
                if (analytics.aiPrediction != null)
                  _buildAIBadge(analytics.aiPrediction).animate().fadeIn().slideX(begin: 0.2),
                if (analytics.aiPrediction != null) const SizedBox(height: 16),

                // ── Deep Knowledge DNA (Unique Feature) ──────────────────
                _buildBrainDNA(user?.uid ?? ''),
                const SizedBox(height: 24),

                // ── Today's Summary Row ─────────────────────────────────
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.auto_graph_rounded,
                      label: 'Avg Grade',
                      value: '${(data?['avg_score'] as num? ?? 0).toStringAsFixed(1)}%',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatPill(
                      icon: Icons.task_alt_rounded,
                      label: 'Done',
                      value: '${data?['submitted_count'] ?? 0}',
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    _StatPill(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '${user?.xp ?? 0}xp',
                      color: const Color(0xFFF97316),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),

                // ── Performance Charts ──────────────────────────────────
                Row(
                  children: [
                    const Text('Learning Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const Spacer(),
                    Text('Last 5 quizzes', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildQuizTrendCard(data),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const Text('Subject Scores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const Spacer(),
                    Text('By subject', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildSubjectBarChart(data),
                ),
                const SizedBox(height: 24),

                // ── Mission Hub ─────────────────────────────────────────
                _buildQuickActions(context),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBrainDNA(String studentId) {
    return StreamBuilder<List<KnowledgeNode>>(
      stream: BrainDNAService.instance.getBrainDNA(studentId),
      builder: (context, snapshot) {
        final nodes = snapshot.data ?? [];
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KNOWLEDGE DNA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary, fontSize: 12)),
                      Text('Real-time Mastery Tracking', style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text('${nodes.length} Nodes Active', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (nodes.isEmpty)
                _buildDNAPlaceholder(studentId)
              else
                Center(
                  child: BrainDNAVisualizer(nodes: nodes, size: 280),
                ),
              const SizedBox(height: 16),
              const Text(
                'Nodes glow brighter as you master concepts. Faded nodes indicate study items that may be forgotten soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDNAPlaceholder(String studentId) {
    return Column(
      children: [
        const Icon(Icons.biotech_rounded, size: 50, color: AppTheme.borderLight),
        const SizedBox(height: 10),
        const Text('Initializing your Brain DNA...', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => BrainDNAService.instance.initializeDNA(studentId, ['Mathematics', 'Science', 'English']),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24)),
          child: const Text('Start DNA Mapping'),
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
              ? _buildEmptyChart(
                  icon: Icons.show_chart_rounded,
                  color: AppTheme.primary,
                  title: 'No Quiz Data Yet',
                  subtitle: 'Take your first quiz to see your\nlearning trajectory graph here!',
                )
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
              ? _buildEmptyChart(
                  icon: Icons.bar_chart_rounded,
                  color: AppTheme.secondary,
                  title: 'No Subject Data Yet',
                  subtitle: 'Complete assignments & quizzes to\nsee your per-subject performance!',
                )
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

  Widget _buildEmptyChart({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.04), color.withOpacity(0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textHint, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
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
        'icon': Icons.account_tree_rounded,
        'label': 'Mind Maps',
        'color': Colors.purple,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIMindMapScreen())),
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
        Row(
          children: [
            const Text('Mission Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
            const Spacer(),
            Text('${actions.length} features', style: TextStyle(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final color = action['color'] as Color;
            return GestureDetector(
              onTap: action['onTap'] as VoidCallback,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: color.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(action['icon'] as IconData, color: color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.2),
                  ),
                ],
              ),
            ).animate().scale(delay: (index * 40).ms, curve: Curves.easeOutBack);
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: AppTheme.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: 'Battle',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
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

// ─── Reusable Stat Pill Widget ──────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}
