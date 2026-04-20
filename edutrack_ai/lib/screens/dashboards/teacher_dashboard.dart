import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../attendance/teacher_attendance_screen.dart';
import '../assignments/create_assignment_screen.dart';
import '../admin/reports_screen.dart';
import '../assignments/assignment_audit_screen.dart';
import '../teacher/leave_approval_screen.dart';
import '../quiz/create_quiz_screen.dart';
import '../teacher/doubt_answer_screen.dart';
import '../teacher/upload_notes_screen.dart';
import '../teacher/lesson_planner_screen.dart';
import '../teacher/bulk_grade_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.classId != null) {
        context.read<AnalyticsProvider>().loadClassAnalytics(user!.classId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final analytics = context.watch<AnalyticsProvider>();
    final user = auth.user;
    final classData = analytics.classAnalytics;

    final top5 = (classData?['top5'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final bottom5 = (classData?['bottom5'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF059669),
            elevation: 0,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
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
                  Container(decoration: const BoxDecoration(gradient: AppTheme.teacherGradient)),
                  Positioned(
                    top: -40, right: -40,
                    child: Container(width: 200, height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                                  (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'T',
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
                                    'Welcome, ${user?.name.split(' ').first ?? 'Teacher'}!',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Class Lead • Educator', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
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
                  // Stats Area
                  Row(
                    children: [
                      Expanded(
                        child: PremiumCard(
                          opacity: 1,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              const Icon(Icons.bolt_rounded, color: AppTheme.borderLight, size: 100),
                              const SizedBox(height: 8),
                              Text(
                                '${(classData?['class_avg'] as num? ?? 0).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              const Text('Class Avg', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                              const Icon(Icons.people_alt_rounded, color: AppTheme.primary, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                '${(classData?['students'] as List?)?.length ?? 0}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              const Text('Students', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().scale(),

                  const SizedBox(height: 24),

                  // Leaderboard sections
                  _buildLeaderboardSection('Academic Stars 🏆', top5, isTop: true),
                  const SizedBox(height: 20),
                  _buildLeaderboardSection('Attention Needed ⚠️', bottom5, isTop: false),
                  
                  const SizedBox(height: 32),

                  // Actions
                  const Text('Quick Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _buildTeacherActions(context),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(String title, List<Map<String, dynamic>> students, {required bool isTop}) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isTop ? AppTheme.secondary : AppTheme.danger)),
          const SizedBox(height: 16),
          if (students.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No data available', style: TextStyle(color: AppTheme.textSecondary))))
          else
            ...students.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final score = (s['avg_score'] as num? ?? 0).toStringAsFixed(1);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: (isTop ? AppTheme.secondary : AppTheme.danger).withOpacity(0.1),
                      child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isTop ? AppTheme.secondary : AppTheme.danger)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                    Text('$score%', style: TextStyle(fontWeight: FontWeight.w800, color: double.parse(score) >= 60 ? AppTheme.primary : AppTheme.danger)),
                  ],
                ),
              );
            }).toList().animate(interval: 100.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildTeacherActions(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';

    final actions = [
      {
        'icon': Icons.how_to_reg_rounded,
        'label': 'Attendance',
        'color': AppTheme.secondary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(classId: classId, className: 'Class Attendance'))),
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'Assignments',
        'color': AppTheme.primary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen(classId: classId))),
      },
      {
        'icon': Icons.bolt_rounded,
        'label': 'New Quiz',
        'color': AppTheme.accent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizScreen(classId: classId))),
      },
      {
        'icon': Icons.insights_rounded,
        'label': 'Analysis',
        'color': const Color(0xFF8B5CF6),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Leaves',
        'color': Colors.teal,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalScreen(classId: classId))),
      },
      {
        'icon': Icons.help_center_rounded,
        'label': 'Doubts',
        'color': const Color(0xFF7C3AED),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtAnswerScreen())),
      },
      {
        'icon': Icons.upload_file_rounded,
        'label': 'Upload Notes',
        'color': const Color(0xFF059669),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen())),
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'AI Lesson Plan',
        'color': const Color(0xFF1D4ED8),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonPlannerScreen())),
      },
      {
        'icon': Icons.grading_rounded,
        'label': 'Bulk Grading',
        'color': const Color(0xFFD946EF),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkGradeScreen())),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action['onTap'] as VoidCallback,
          child: PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action['label'] as String,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: action['color'] as Color),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Session?'),
        content: const Text('Are you sure you want to exit the teacher hub?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
