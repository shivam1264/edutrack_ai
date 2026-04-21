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
import '../../services/brain_dna_service.dart';
import '../../models/knowledge_node.dart';
import '../../widgets/brain_dna_visualizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

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
    final user = auth.user;

    final List<Widget> tabs = [
      _buildInsightsTab(),
      _buildClassroomTab(),
      _buildAILabsTab(),
      _buildConnectTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF059669),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Insights'),
            BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Classroom'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Labs'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Connect'),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    final user = context.watch<AuthProvider>().user;
    final analytics = context.watch<AnalyticsProvider>();
    final classData = analytics.classAnalytics;
    final top5 = (classData?['top5'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final bottom5 = (classData?['bottom5'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar('Academic Insights', 'Track class progress'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (analytics.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Class Avg', '${(classData?['class_avg'] as num? ?? 0).toStringAsFixed(1)}%', Icons.bolt_rounded, AppTheme.borderLight),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard('Students', '${(classData?['students'] as List?)?.length ?? 0}', Icons.people_alt_rounded, AppTheme.primary),
                    ),
                  ],
                ).animate().fadeIn().scale(),
                const SizedBox(height: 24),

                // ── Class Knowledge DNA Heatmap ─────────────────────────
                _buildClassDNAHeatmap(user?.classId ?? ''),
                const SizedBox(height: 24),

                _buildLeaderboardSection('Academic Stars 🏆', top5, isTop: true),
                const SizedBox(height: 20),
                _buildLeaderboardSection('Attention Needed ⚠️', bottom5, isTop: false),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildClassroomTab() {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar('Classroom', 'Manage daily activities'),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
               _buildGridActions([
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
                    'icon': Icons.grading_rounded,
                    'label': 'Bulk Grading',
                    'color': const Color(0xFFD946EF),
                    'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkGradeScreen())),
                  },
               ]),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAILabsTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar('AI Assistant', 'Smart educational tools'),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
               _buildGridActions([
                  {
                    'icon': Icons.auto_awesome_rounded,
                    'label': 'AI Lesson Plan',
                    'color': const Color(0xFF1D4ED8),
                    'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonPlannerScreen())),
                  },
                  {
                    'icon': Icons.upload_file_rounded,
                    'label': 'Upload Notes',
                    'color': const Color(0xFF059669),
                    'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen())),
                  },
                  {
                    'icon': Icons.insights_rounded,
                    'label': 'Smart Analysis',
                    'color': const Color(0xFF8B5CF6),
                    'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  },
               ]),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectTab() {
    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar('Connect', 'Student support & requests'),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
               _buildGridActions([
                  {
                    'icon': Icons.help_center_rounded,
                    'label': 'Student Doubts',
                    'color': const Color(0xFF7C3AED),
                    'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtAnswerScreen())),
                  },
                  {
                    'icon': Icons.calendar_today_rounded,
                    'label': 'Leave Approvals',
                    'color': Colors.teal,
                    'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalScreen(classId: classId))),
                  },
               ]),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(String title, String subtitle) {
    final user = context.watch<AuthProvider>().user;
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF059669),
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
        background: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: AppTheme.teacherGradient)),
            Positioned(
              top: -40, right: -40,
              child: Container(width: 180, height: 180,
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
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5))),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(user?.name[0].toUpperCase() ?? 'T', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          Row(
                            children: [
                              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                              if (user?.classId != null) ...[
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  width: 4, height: 4,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Academic Hub: ${user!.classId}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGridActions(List<Map<String, dynamic>> actions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action['onTap'] as VoidCallback,
          child: PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData, color: action['color'] as Color, size: 32),
                const SizedBox(height: 12),
                Text(
                  action['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: action['color'] as Color),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).scale(begin: const Offset(0.9, 0.9));
      },
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

  Widget _buildClassDNAHeatmap(String classId) {
    return FutureBuilder<QuerySnapshot>(
      // Aggregating from a sample of students for the visual heatmap
      future: FirebaseFirestore.instance
          .collectionGroup('brain_dna')
          .where('class_id', isEqualTo: classId) // Optional: If we added class_id to DNA nodes
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        // Since collectionGroup might be complex, we'll show a high-level subject overview for teacher
        final stats = context.read<AnalyticsProvider>().classAnalytics?['subject_avg'] as Map<String, dynamic>? ?? {};
        
        // Convert subject stats to Nodes for the visualizer
        List<KnowledgeNode> classNodes = stats.entries.map((e) => KnowledgeNode(
          id: e.key,
          name: e.key,
          subject: 'Class Overview',
          masteryScore: (e.value as num).toDouble() / 100,
          retentionFactor: 1.0,
          lastActivity: DateTime.now(),
          status: (e.value as num) > 75 ? 'mastered' : 'learning',
        )).toList();

        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, color: AppTheme.secondary, size: 20),
                  SizedBox(width: 10),
                  Text('CLASS BRAIN DNA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.secondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Visual heatmap of collective subject mastery and retention.', style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
              const SizedBox(height: 20),
              if (classNodes.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Waiting for student pulse data...', style: TextStyle(color: AppTheme.textHint, fontSize: 12))))
              else
                Center(
                  child: BrainDNAVisualizer(nodes: classNodes, size: 240),
                ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DNAKey(color: Color(0xFF10B981), label: 'Mastered'),
                  SizedBox(width: 16),
                  _DNAKey(color: Color(0xFFF59E0B), label: 'Struggling'),
                  SizedBox(width: 16),
                  _DNAKey(color: Colors.grey, label: 'Fading'),
                ],
              ),
            ],
          ),
        );
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

class _DNAKey extends StatelessWidget {
  final Color color;
  final String label;
  const _DNAKey({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
