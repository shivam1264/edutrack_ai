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
import '../settings/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../services/attendance_service.dart';
import '../homework/homework_chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../planner/smart_planner_screen.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  String? _selectedChildId;
  final Map<String, String> _childNames = {};
  final Map<String, String> _childClassIds = {};
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
            final data = doc.data();
            _childNames[id] = data?['name'] ?? id;
            _childClassIds[id] = data?['class_id'] ?? '';
          } else {
            _childNames[id] = id;
            _childClassIds[id] = '';
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

  void _triggerWellnessFetch(String childId, Map<String, dynamic>? stats) {
    if (stats != null) {
      final name = _childNames[childId] ?? 'Your Child';
      context.read<AnalyticsProvider>().loadWellnessData(childId, name, stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final analytics = context.watch<AnalyticsProvider>();
    final childData = analytics.studentAnalytics;
    final prediction = analytics.aiPrediction;
    final wellnessData = analytics.wellnessFor(_selectedChildId ?? '');

    // Auto-trigger wellness fetch when student data is ready
    if (!analytics.isLoading && _selectedChildId != null && wellnessData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerWellnessFetch(_selectedChildId!, childData);
      });
    }

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
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white.withOpacity(0.25),
                                    backgroundImage: user?.avatarUrl != null ? CachedNetworkImageProvider(user!.avatarUrl!) : null,
                                    child: user?.avatarUrl == null 
                                      ? Text(
                                          (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'P',
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                        )
                                      : null,
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
                // 1. Prediction Card (Stable)
                _buildRiskCard(prediction, analytics.isLoading).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 24),

                // 2. Wellness Insights (Unified)
                _AIWellnessSection(
                  studentId: _selectedChildId ?? '',
                  isLoading: analytics.isWellnessLoading || analytics.isLoading,
                  data: wellnessData,
                ),
                const SizedBox(height: 24),

                  if (_selectedChildId == null)
                    _buildNoChildLinked()
                  else ...[
                    // ── Critical Alerts ──────────────────────────────────────────
                    _buildCriticalAlerts(_selectedChildId!, _childClassIds[_selectedChildId!] ?? '', childData),
                    const SizedBox(height: 16),

                    // ── Attendance & Today's Status ──────────────────────────────
                    _buildTodayAttendanceStatus(_selectedChildId!),
                    const SizedBox(height: 24),

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
                        FutureBuilder<Map<String, dynamic>?>(
                          future: AnalyticsService().getStudentRank(_selectedChildId!, _childClassIds[_selectedChildId!] ?? ''),
                          builder: (context, rankSnap) {
                            final rankData = rankSnap.data;
                            final rankStr = rankData != null ? '${rankData['rank']}/${rankData['total']}' : '--';
                            return Expanded(
                              child: _ParentStatCard(
                                icon: Icons.emoji_events_rounded,
                                label: 'Class Rank',
                                value: rankStr,
                                color: const Color(0xFFF59E0B),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChildAttendanceCard(studentId: _selectedChildId!),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: 24),

                    // ── Performance Analytics (Graphs) ─────────────────────────
                    _buildPerformanceAnalytics(childData),
                    const SizedBox(height: 16),
                    _buildRecentTestPerformance(_selectedChildId!),
                    const SizedBox(height: 24),

                    // ── AI Study Plan Section ──────────────────────────────────
                    const Text('AI Strategic Roadmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildAIStudyPlanSection(_selectedChildId!),
                    const SizedBox(height: 24),

                    const Text('Recent Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildAssignmentTracker(_selectedChildId!, _childClassIds[_selectedChildId!] ?? ''),
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
                            label: 'Chat AI',
                            color: AppTheme.primary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentChatScreen(studentId: _selectedChildId))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ParentActionButton(
                            icon: Icons.psychology_rounded,
                            label: 'HW Assist',
                            color: AppTheme.secondary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkChatScreen())),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ParentActionButton(
                            icon: Icons.calendar_today_rounded,
                            label: 'Leave',
                            color: AppTheme.parentColor,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestLeaveScreen(
                              studentId: _selectedChildId,
                              classId: _childClassIds[_selectedChildId ?? ''],
                            ))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ParentActionButton(
                            icon: Icons.assessment_rounded,
                            label: 'Report',
                            color: const Color(0xFF0EA5E9),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyReportScreen(studentId: _selectedChildId))),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
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

  Widget _buildRiskCard(Map<String, dynamic>? prediction, bool isLoading) {
    if (isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
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

  Widget _buildCriticalAlerts(String studentId, String classId, Map<String, dynamic>? childData) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        AssignmentService().getAssignmentsByClass(classId),
        AssignmentService().getStudentSubmissions(studentId),
        FirebaseFirestore.instance.collection('attendance').where('student_id', isEqualTo: studentId).get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final assignments = snapshot.data![0] as List<AssignmentModel>;
        final submissions = snapshot.data![1] as List<SubmissionModel>;
        final attendanceDocs = (snapshot.data![2] as QuerySnapshot).docs;

        final subMap = { for (var s in submissions) s.assignmentId : s };
        final pendingOverdue = assignments.where((a) => !subMap.containsKey(a.id) && DateTime.now().isAfter(a.dueDate)).length;
        
        final totalAtt = attendanceDocs.length;
        final presentAtt = attendanceDocs.where((d) => d['status'] == 'present').length;
        final attPercent = totalAtt == 0 ? 100.0 : (presentAtt / totalAtt) * 100;

        final alerts = <Widget>[];

        if (attPercent < 75 && totalAtt > 0) {
          alerts.add(_AlertCard(
            icon: Icons.warning_rounded,
            color: AppTheme.danger,
            title: 'Critical Attendance',
            message: 'Attendance has dropped to ${attPercent.toStringAsFixed(0)}%. Minimum 75% required.',
          ));
        }

        if (pendingOverdue > 0) {
          alerts.add(_AlertCard(
            icon: Icons.assignment_late_rounded,
            color: Colors.orange,
            title: 'Missing Assignments',
            message: 'Your child has $pendingOverdue overdue assignments that need immediate attention.',
          ));
        }

        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(children: alerts);
      },
    );
  }

  Widget _buildTodayAttendanceStatus(String studentId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('student_id', isEqualTo: studentId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final status = docs.isEmpty ? 'Not Marked' : (docs.first['status'] as String).toUpperCase();
        final color = docs.isEmpty ? Colors.grey : (status == 'PRESENT' ? AppTheme.secondary : AppTheme.danger);
        final icon = docs.isEmpty ? Icons.help_outline_rounded : (status == 'PRESENT' ? Icons.check_circle_rounded : Icons.cancel_rounded);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TODAY\'S ATTENDANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: AppTheme.textHint)),
                    Text(status, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
                  ],
                ),
              ),
              Text(DateFormat('EEEE, MMM d').format(now), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textHint)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceAnalytics(Map<String, dynamic>? data) {
    final scores = (data?['last_5_scores'] as List<dynamic>? ?? []).map((s) => (s as num).toDouble()).toList();
    final subjectAvg = (data?['subject_avg'] as Map<String, dynamic>? ?? {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Learning Trajectory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: scores.isEmpty
                    ? const Center(child: Text('No quiz data for trajectory graph.', style: TextStyle(color: AppTheme.textHint)))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                              isCurved: true,
                              color: AppTheme.parentColor,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: AppTheme.parentColor.withOpacity(0.1)),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Text('Subject-wise Mastery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.textHint, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              ...subjectAvg.entries.map((e) {
                final isWeak = (e.value as num) < 60;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                              if (isWeak) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('WEAK', style: TextStyle(color: AppTheme.danger, fontSize: 8, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ],
                          ),
                          Text('${(e.value as num).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isWeak ? AppTheme.danger : AppTheme.parentColor)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: (e.value as num) / 100,
                        progressColor: isWeak ? AppTheme.danger : AppTheme.parentColor,
                        backgroundColor: (isWeak ? AppTheme.danger : AppTheme.parentColor).withOpacity(0.1),
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (subjectAvg.entries.any((e) => (e.value as num) < 60))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: AppTheme.accent, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${subjectAvg.entries.where((e) => (e.value as num) < 60).map((e) => e.key).join(', ')} needs extra attention.',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIStudyPlanSection(String studentId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('study_plans').doc(studentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) {
          return PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('No study plan generated yet. Use the "Study Plan" action to create one.', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                ),
              ],
            ),
          );
        }

        final schedule = data['schedule'] as String;
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.task_rounded, color: AppTheme.secondary, size: 20),
                  const SizedBox(width: 10),
                  const Text('LATEST STRATEGY', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.secondary, fontSize: 12)),
                  const Spacer(),
                  Text(
                    data['updated_at'] != null ? timeago.format((data['updated_at'] as Timestamp).toDate()) : '',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: schedule.length > 300 ? '${schedule.substring(0, 300)}...' : schedule,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SmartPlannerScreen(studentId: studentId))),
                child: const Text('VIEW FULL ROADMAP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTestPerformance(String studentId) {
    return FutureBuilder<List<QuizResultModel>>(
      future: QuizService().getStudentResults(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final results = snapshot.data!;
        if (results.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Test Performance', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.textHint, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            ...results.take(3).map((res) {
              final isWeak = (res.score / res.total) < 0.6;
              return PremiumCard(
                opacity: 1,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isWeak ? AppTheme.danger : AppTheme.secondary).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWeak ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        color: isWeak ? AppTheme.danger : AppTheme.secondary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quiz #${res.quizId.substring(0, 4).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                          Text('Academic Assessment', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${res.score.toStringAsFixed(0)}/${res.total.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isWeak ? AppTheme.danger : AppTheme.secondary),
                        ),
                        if (isWeak)
                          const Text('Needs Review', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.danger)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentTracker(String studentId, String classId) {
    return FutureBuilder<List<AssignmentModel>>(
      future: AssignmentService().getAssignmentsByClass(classId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        final assignments = snapshot.data!;

        return FutureBuilder<List<SubmissionModel>>(
          future: AssignmentService().getStudentSubmissions(studentId),
          builder: (context, subSnap) {
            final submissions = subSnap.data ?? [];
            final Map<String, SubmissionModel> submissionMap = { for (var s in submissions) s.assignmentId : s };

            if (assignments.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No assignments found.', style: TextStyle(color: AppTheme.textHint))));

            return Column(
              children: assignments.take(3).map((a) {
                final sub = submissionMap[a.id];
                final isSubmitted = sub != null;
                final isGraded = sub?.status == AssignmentStatus.graded;
                final isLate = !isSubmitted && DateTime.now().isAfter(a.dueDate);

                return PremiumCard(
                  opacity: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: (isGraded ? Colors.green : (isLate ? Colors.red : Colors.orange)).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          isGraded ? Icons.verified_rounded : (isSubmitted ? Icons.pending_actions_rounded : Icons.assignment_rounded),
                          color: isGraded ? Colors.green : (isLate ? Colors.red : Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                            Text(a.subject, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isGraded ? Colors.green : (isSubmitted ? Colors.blue : (isLate ? Colors.red : Colors.orange))).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isGraded ? 'GRADED' : (isSubmitted ? 'SUBMITTED' : (isLate ? 'LATE' : 'PENDING')),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: (isGraded ? Colors.green : (isSubmitted ? Colors.blue : (isLate ? Colors.red : Colors.orange))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM d').format(a.dueDate), style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Parent Portal?'),
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
        final isLow = percentage < 75 && total > 0;

        return Column(
          children: [
            PremiumCard(
              opacity: 1,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, color: isLow ? AppTheme.danger : AppTheme.secondary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isLow ? AppTheme.danger : AppTheme.textPrimary),
                  ),
                  const Text('Attendance', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (isLow)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 12),
                      SizedBox(width: 4),
                      Text('Low Attendance Alert ⚠️', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ).animate().shake(),
          ],
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
class _AIWellnessSection extends StatelessWidget {
  final String studentId;
  final bool isLoading;
  final Map<String, dynamic>? data;

  const _AIWellnessSection({
    required this.studentId,
    required this.isLoading,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && data == null) {
      return PremiumCard(
        opacity: 0.5,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Syncing Wellness Database...', style: TextStyle(color: AppTheme.primary.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final report = data?['report'] ?? 'Select a student to view insights.';
    final burnout = data?['burnout'] as Map<String, dynamic>?;
    final risk = burnout?['risk_level'] ?? 'Low';
    final message = burnout?['message'] ?? 'Healthy status maintained.';
    final isHigh = risk == 'High' || risk == 'Medium';

    return Column(
      children: [
        // ── Burnout Alert Card ───────────────────────────────────────
        Container(
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
                  const Spacer(),
                  if (data != null) const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
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
        ),
        const SizedBox(height: 24),

        // ── Wellness Insights Card ────────────────────────────────────
        PremiumCard(
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
              Text(report, style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
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

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _AlertCard({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: color)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1).fadeIn();
  }
}
