import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/screens/assignments/assignment_audit_screen.dart';
import 'package:edutrack_ai/screens/assignments/create_assignment_screen.dart';
import 'package:edutrack_ai/screens/attendance/teacher_attendance_screen.dart';
import 'package:edutrack_ai/screens/quiz/create_quiz_screen.dart';
import 'package:edutrack_ai/screens/teacher/bulk_grade_screen.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_students_view.dart';
import 'package:edutrack_ai/screens/teacher/resource_management_screen.dart';
import 'package:edutrack_ai/screens/teacher/teacher_announcements_screen.dart';
import 'package:edutrack_ai/screens/teacher/upload_notes_screen.dart';
import 'package:edutrack_ai/services/analytics_service.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class TeacherHomeView extends StatelessWidget {
  final String? selectedClassId;
  final String currentClassName;

  const TeacherHomeView({
    super.key,
    required this.selectedClassId,
    required this.currentClassName,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final analytics = context.watch<AnalyticsProvider>();
    final classData = analytics.classAnalytics;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildHeader(context, user),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTodayOverview(classData, context),
                const SizedBox(height: 24),
                _buildClassPerformanceChart(classData),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentActivity(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final subjectText =
        user?.subjects != null && user!.subjects!.isNotEmpty
        ? user.subjects!.join(', ')
        : 'Teacher';

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE6F4F1),
            backgroundImage: user?.avatarUrl != null
                ? CachedNetworkImageProvider(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher Dashboard',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good morning, ${user?.name.split(' ').first ?? 'Teacher'}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentClassName | $subjectText',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('uid', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview(Map<String, dynamic>? data, BuildContext context) {
    final students = (data?['students'] as List?)?.length ?? 0;
    final pendingTasks = data?['pending_tasks'] ?? 0;
    final announcements = data?['announcements_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today at a Glance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Class health and activity overview.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FutureBuilder<double>(
                future: AnalyticsService.instance.getClassAttendance(
                  selectedClassId ?? '',
                ),
                builder: (context, snapshot) {
                  final attendance = snapshot.data ?? 0.0;
                  return _buildStatCard(
                    '${attendance.toStringAsFixed(0)}%',
                    'Attendance',
                    Icons.how_to_reg_rounded,
                    AppTheme.secondary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherAttendanceScreen(
                            classId: selectedClassId ?? '',
                            className: currentClassName,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '$students',
                'Students',
                Icons.people_outline_rounded,
                AppTheme.info,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TeacherStudentsView(selectedClassId: selectedClassId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '$pendingTasks',
                'Pending',
                Icons.assignment_late_outlined,
                AppTheme.warning,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BulkGradeScreen(classId: selectedClassId ?? ''),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '$announcements',
                'Updates',
                Icons.campaign_outlined,
                AppTheme.accent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherAnnouncementsScreen(
                        classId: selectedClassId ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassPerformanceChart(Map<String, dynamic>? data) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Recent seven-day trend.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: FutureBuilder<List<double>>(
              future: AnalyticsService.instance.getClassPerformanceTrend(
                selectedClassId ?? '',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final trend = snapshot.data ?? [];
                if (trend.isEmpty) {
                  return const Center(
                    child: Text(
                      'No performance data yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            final date = now.subtract(
                              Duration(days: 6 - value.toInt()),
                            );
                            return Text(
                              DateFormat('E').format(date),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: trend
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        color: AppTheme.secondary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.secondary.withOpacity(0.12),
                        ),
                      ),
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

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'label': 'Attendance',
        'icon': Icons.how_to_reg_rounded,
        'color': AppTheme.secondary,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherAttendanceScreen(
              classId: selectedClassId ?? '',
              className: currentClassName,
            ),
          ),
        ),
      },
      {
        'label': 'Assignment',
        'icon': Icons.assignment_add,
        'color': AppTheme.primary,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateAssignmentScreen(
              classId: selectedClassId ?? '',
            ),
          ),
        ),
      },
      {
        'label': 'Quiz',
        'icon': Icons.quiz_outlined,
        'color': AppTheme.warning,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateQuizScreen(classId: selectedClassId ?? ''),
          ),
        ),
      },
      {
        'label': 'Notes',
        'icon': Icons.upload_file_rounded,
        'color': AppTheme.info,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadNotesScreen(classId: selectedClassId ?? ''),
          ),
        ),
      },
      {
        'label': 'Resources',
        'icon': Icons.inventory_2_rounded,
        'color': AppTheme.accent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResourceManagementScreen(
              classId: selectedClassId ?? '',
            ),
          ),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Common teaching workflows for this class.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PremiumCard(
                  onTap: action['onTap'] as VoidCallback,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 92,
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (action['color'] as Color).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            color: action['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          action['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Latest class submissions and responses.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssignmentAuditScreen(classId: selectedClassId ?? ''),
                ),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('submissions')
              .where('class_id', isEqualTo: selectedClassId)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const PremiumCard(
                child: Text(
                  'Recent activity could not be loaded.',
                  style: TextStyle(color: AppTheme.danger),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const PremiumCard(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }

            final docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              final aTime =
                  (a.data() as Map<String, dynamic>)['submitted_at'] as Timestamp?;
              final bTime =
                  (b.data() as Map<String, dynamic>)['submitted_at'] as Timestamp?;
              return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
            });

            return Column(
              children: docs.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final studentId = data['student_id'] as String? ?? 'Unknown';
                final timestamp =
                    (data['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now();
                final timeAgo = _getTimeAgo(timestamp);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentId)
                      .get(),
                  builder: (context, userSnap) {
                    final userData = userSnap.data?.data() as Map<String, dynamic>?;
                    final studentName = userData?['name'] ?? 'Student';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'New Submission',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By $studentName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
