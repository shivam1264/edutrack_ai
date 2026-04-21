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
import '../parent/monthly_report_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/config.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  String? _selectedChildId;
  final Map<String, String> _childNames = {};
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().user;
      final kids = user?.parentOf ?? [];
      
      if (kids.isNotEmpty) {
        // Fetch names for all kids
        for (var id in kids) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
          if (doc.exists) {
            _childNames[id] = doc.data()?['name'] ?? id;
          } else {
            _childNames[id] = id;
          }
        }
        
        if (mounted) {
          setState(() {
            _selectedChildId = kids.first;
            _isLoadingNames = false;
          });
          _loadChildData(kids.first);
        }
      } else {
        if (mounted) setState(() => _isLoadingNames = false);
      }
    });
  }

  void _loadChildData(String childId) {
    context.read<AnalyticsProvider>().loadStudentAnalytics(childId);
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
            expandedHeight: 200,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFFD97706),
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
                  Container(decoration: const BoxDecoration(gradient: AppTheme.parentGradient)),
                  Positioned(
                    top: -40, right: -40,
                    child: Container(width: 200, height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06))),
                  ),
                  Positioned(
                    bottom: -30, left: -20,
                    child: Container(width: 140, height: 140,
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
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                child: Text(
                                  (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'P',
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
                                    'Hello, ${user?.name.split(' ').first ?? 'Parent'}! 👨‍👩‍👧',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                                  ),
                                  const SizedBox(height: 4),
                                  if ((user?.parentOf?.length ?? 0) > 1)
                                    _buildChildSwitcher(user!.parentOf!)
                                  else
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text('Guardian Portal', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        ),
                                        if (childData?['name'] != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                                            ),
                                            child: Text('Monitoring: ${childData!['name']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                          ),
                                        ],
                                      ],
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (analytics.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
                else ...[
                  _buildRiskCard(prediction).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 24),

                  const SizedBox(height: 12),
                  _AIBurnoutDetectorCard(studentName: childData?['name'] ?? 'Your Child'),
                  const SizedBox(height: 24),

                  _AIProgressReportCard(
                    studentName: childData?['name'] ?? 'Your Child',
                    stats: childData ?? {},
                  ),
                  const SizedBox(height: 24),

                  if (_selectedChildId == null)
                    _buildNoChildLinked()
                  else ...[
                    // ── Quick Stats Row ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ParentStatCard(
                            icon: Icons.stars_rounded,
                            label: 'Avg Score',
                            value: '${(childData?['avg_score'] as num? ?? 0).toStringAsFixed(1)}%',
                            color: AppTheme.parentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChildAttendanceCard(studentId: _selectedChildId!),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: 24),

                    const Text('Recent Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildRecentNotifications(_selectedChildId!),
                    const SizedBox(height: 24),

                    const Text('Child Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildChildProfile(_selectedChildId!),
                    const SizedBox(height: 24),
                  ],

                  // ── Action Buttons ────────────────────────────────────
                  const Text('Parent Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ParentActionButton(
                          icon: Icons.forum_rounded,
                          label: 'AI Assistant',
                          color: AppTheme.primary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentChatScreen(studentId: _selectedChildId))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ParentActionButton(
                          icon: Icons.calendar_today_rounded,
                          label: 'Leave Apply',
                          color: AppTheme.parentColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestLeaveScreen(studentId: _selectedChildId))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ParentActionButton(
                          icon: Icons.assessment_rounded,
                          label: 'AI Report',
                          color: const Color(0xFF0EA5E9),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyReportScreen(studentId: _selectedChildId))),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
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
    if (_selectedChildId == null) return;
    
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
                  studentId: _selectedChildId!,
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

  Widget _buildChildSwitcher(List<String> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children.map((id) {
          final isSelected = _selectedChildId == id;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedChildId = id);
              _loadChildData(id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                    size: 14,
                    color: isSelected ? const Color(0xFFD97706) : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _childNames[id] ?? id.substring(0, 8).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFD97706) : Colors.white,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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

class _AIBurnoutDetectorCard extends StatefulWidget {
  final String studentName;
  const _AIBurnoutDetectorCard({required this.studentName});

  @override
  State<_AIBurnoutDetectorCard> createState() => _AIBurnoutDetectorCardState();
}

class _AIBurnoutDetectorCardState extends State<_AIBurnoutDetectorCard> {
  Map<String, dynamic>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBurnoutData();
  }

  Future<void> _fetchBurnoutData() async {
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/detect-burnout')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_name': widget.studentName,
          'study_hours_per_day': 7, 
          'late_night_active': true,
          'grades_dropping': false,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _result = jsonDecode(response.body);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_result == null || _result!['error'] != null) return const SizedBox.shrink();

    final risk = _result!['risk_level'] ?? 'Low';
    final message = _result!['message'] ?? '';
    final isHigh = risk == 'High' || risk == 'Medium';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHigh ? AppTheme.danger.withOpacity(0.08) : AppTheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHigh ? AppTheme.danger.withOpacity(0.3) : AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isHigh ? Icons.favorite_border_rounded : Icons.favorite_rounded, color: isHigh ? AppTheme.danger : AppTheme.secondary, size: 24),
              const SizedBox(width: 10),
              Text('STUDENT BURNOUT ALERT', style: TextStyle(fontWeight: FontWeight.w900, color: isHigh ? AppTheme.danger : AppTheme.secondary, letterSpacing: 1.0, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: isHigh ? AppTheme.danger : AppTheme.secondary, borderRadius: BorderRadius.circular(8)),
            child: Text('Risk Level: $risk', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(fontSize: 14, height: 1.5, color: isHigh ? AppTheme.danger : AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Parent Stat Card ───────────────────────────────────────────────────────
class _ParentStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ParentStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Parent Action Button ───────────────────────────────────────────────────
class _ParentActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ParentActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
