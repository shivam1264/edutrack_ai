import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/notification_bell.dart';
import '../../services/analytics_service.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../parent/parent_chat_screen.dart';
import '../parent/request_leave_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/config.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.parentOf != null) {
        context.read<AnalyticsProvider>().loadStudentAnalytics(user!.parentOf!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final analytics = context.watch<AnalyticsProvider>();
    final childData = analytics.studentAnalytics;
    final prediction = analytics.aiPrediction;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF6366F1),
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
                    top: -10,
                    right: -10,
                    child: Icon(Icons.family_restroom_rounded, color: Colors.white.withOpacity(0.1), size: 180),
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
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'P',
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
                                    'Hi, ${user?.name.split(' ').first ?? 'Parent'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    "Your child's progress is our priority",
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
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
                  _buildRiskCard(prediction).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 24),

                  _AIProgressReportCard(
                    studentName: childData?['name'] ?? 'Your Child',
                    stats: childData ?? {},
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _ChildAttendanceCard(studentId: user!.parentOf!),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PremiumCard(
                          opacity: 1,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              const Icon(Icons.stars_rounded, color: AppTheme.accent, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                '${(childData?['avg_score'] as num? ?? 0).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              const Text('Avg Score', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).scale(),

                  const SizedBox(height: 24),

                  const Text('Recent Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  _buildRecentNotifications(user.parentOf!),
                  const SizedBox(height: 24),

                  const Text('Child Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  _buildChildProfile(user.parentOf!),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentChatScreen())),
                          icon: const Icon(Icons.forum_rounded),
                          label: const Text('Chat with AI Parent Assistant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestLeaveScreen())),
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: const Text('AI Leave Application'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildLinked() {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.person_off_rounded, size: 60, color: AppTheme.textSecondary),
          const SizedBox(height: 20),
          const Text(
            'No child profile is linked to your account. Please contact school administration to establish the connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(Map<String, dynamic>? prediction) {
    final risk = prediction?['risk_level'] as String? ?? 'low';
    final isWarning = risk != 'low';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isWarning 
          ? (risk == 'high' ? AppTheme.dangerGradient : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]))
          : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: (isWarning ? Colors.orange : Colors.green).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(isWarning ? Icons.auto_awesome_rounded : Icons.verified_user_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWarning ? 'AI Learning Safeguard' : 'Academic Health Check',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWarning 
                        ? 'AI detects a potential performance dip. We recommend reviewing the study plan.'
                        : 'Your child is performing exceptionally well. Keep up the encouragement!',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isWarning) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showStudyPlanDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: (risk == 'high' ? AppTheme.danger : Colors.orange),
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Generate Rescue Study Plan', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStudyPlanDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Personalized Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: context.read<AnalyticsService>().getStudyPlan(
                  studentId: user?.parentOf ?? '',
                  weakSubjects: ['Mathematics', 'Science'],
                  upcomingDeadlines: [],
                  studyHoursPerDay: 4,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Failed to sync with AI. Try again soon.', style: TextStyle(color: AppTheme.textSecondary)));
                  }
                  final plan = snapshot.data!['plan'] as String;
                  return SingleChildScrollView(
                    child: Text(plan, style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textPrimary)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotifications(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('target_id', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        final notifs = snapshot.data?.docs ?? [];
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notifs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No recent updates found.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))))
              else
                ...notifs.map((doc) => _NotifItem(
                  icon: Icons.rocket_launch_rounded,
                  color: AppTheme.primary,
                  title: doc['title'] ?? 'Academic Update',
                  subtitle: doc['message'] ?? '',
                  time: 'Recently',
                )).toList().animate(interval: 100.ms).fadeIn(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildProfile(String studentId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Full Name', value: data?['name'] ?? 'Loading...'),
              _InfoRow(label: 'Assigned Class', value: data?['class_id'] ?? 'Not Assigned'),
              _InfoRow(label: 'Academic ID', value: studentId.length > 8 ? studentId.substring(0, 8).toUpperCase() : studentId),
              _InfoRow(label: 'School Unit', value: 'EduTrack Primary Hub'),
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
        title: const Text('Exit Parent Hub?'),
        content: const Text('Are you sure you want to exit your monitoring session?'),
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

class _ChildAttendanceCard extends StatelessWidget {
  final String studentId;
  const _ChildAttendanceCard({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('student_id', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final present = docs.where((d) => d['status'] == 'present').length;
        final percentage = total == 0 ? 0.0 : (present / total) * 100;

        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(Icons.event_available_rounded, color: AppTheme.secondary, size: 28),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const Text('Attendance', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }
}
class _AIProgressReportCard extends StatefulWidget {
  final String studentName;
  final Map<String, dynamic> stats;

  const _AIProgressReportCard({required this.studentName, required this.stats});

  @override
  State<_AIProgressReportCard> createState() => _AIProgressReportCardState();
}

class _AIProgressReportCardState extends State<_AIProgressReportCard> {
  String _report = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/parent-report')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': widget.studentName,
          'stats': widget.stats,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _report = jsonDecode(response.body)['report'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _report = 'Neural system connection disrupted. Please try again later.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 10),
              Text('AI WELLNESS INSIGHTS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.5, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else
            Text(_report, style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
