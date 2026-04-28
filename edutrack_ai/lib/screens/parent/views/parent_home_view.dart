import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:edutrack_ai/models/class_model.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/screens/parent/parent_academics_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_assignments_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_attendance_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_wellness_screen.dart';
import 'package:edutrack_ai/screens/parent/views/parent_profile_view.dart';
import 'package:edutrack_ai/services/analytics_service.dart';
import 'package:edutrack_ai/services/attendance_service.dart';
import 'package:edutrack_ai/services/class_service.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class ParentHomeView extends StatefulWidget {
  const ParentHomeView({super.key});

  @override
  State<ParentHomeView> createState() => _ParentHomeViewState();
}

class _ParentHomeViewState extends State<ParentHomeView> {
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parent = context.read<AuthProvider>().user;
      final linkedChildren = parent?.parentOf ?? [];
      if (linkedChildren.isNotEmpty) {
        context.read<AnalyticsProvider>().loadStudentAnalytics(linkedChildren.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<AuthProvider>().user;
    final linkedChildren = parent?.parentOf ?? [];
    final childId = linkedChildren.contains(_selectedChildId)
        ? _selectedChildId
        : (linkedChildren.isNotEmpty ? linkedChildren.first : null);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildHeader(context, parent),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildChildCard(context, childId),
                const SizedBox(height: 20),
                _buildWellnessCard(context, childId),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  'Today at a Glance',
                  'Attendance, performance, and class standing.',
                  onTap: () {
                    if (childId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentAcademicsScreen(studentId: childId),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildStatsGlance(childId),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  'Quick Access',
                  'Common parent actions for this student.',
                ),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(context, childId),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent Dashboard',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hello, ${user?.name.split(' ').first ?? 'Parent'}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track your child\'s progress with a calmer, clearer overview.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ParentProfileView()),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.parentLight,
              backgroundImage:
                  (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppTheme.parentColor,
                      size: 22,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, String? childId) {
    return FutureBuilder<DocumentSnapshot>(
      future: childId != null
          ? FirebaseFirestore.instance.collection('users').doc(childId).get()
          : null,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? 'Select Child';
        final rollNo = data?['roll_no'] ?? 'N/A';
        final classId = data?['class_id'];

        return PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.parentLight,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.parentColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (classId != null)
                      StreamBuilder<ClassModel>(
                        stream: ClassService().getClassById(classId),
                        builder: (context, classSnap) {
                          final className =
                              classSnap.data?.displayName ?? 'Loading...';
                          return Text(
                            'Grade $className | Roll No. $rollNo',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        'Grade N/A | Roll No. $rollNo',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showChildPicker(context),
                child: const Text(
                  'Switch',
                  style: TextStyle(
                    color: AppTheme.parentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWellnessCard(BuildContext context, String? childId) {
    final wellnessData = context.watch<AnalyticsProvider>().wellnessFor(
      childId ?? '',
    );
    final riskLevel = wellnessData?['risk_level'] ?? 'Low';
    final wellnessMsg = riskLevel == 'Low'
        ? 'Your child is doing well.'
        : (riskLevel == 'High'
              ? 'Attention may be required.'
              : 'Monitor progress closely.');
    final wellnessSub = riskLevel == 'Low'
        ? 'Keep encouragement and routine steady.'
        : 'Review recent activity and recommendations.';
    final riskColor = riskLevel == 'High'
        ? AppTheme.danger
        : (riskLevel == 'Medium' ? AppTheme.warning : AppTheme.success);

    return PremiumCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ParentWellnessScreen(studentId: childId)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: riskColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wellness & AI Insights',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wellnessMsg,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wellnessSub,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              riskLevel,
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null) TextButton(onPressed: onTap, child: const Text('View')),
      ],
    );
  }

  Widget _buildStatsGlance(String? childId) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        final data = analytics.studentAnalytics;
        final avgScore = data != null
            ? '${(data['avg_score'] as double).toInt()}%'
            : 'N/A';

        return FutureBuilder<Map<String, dynamic>?>(
          future: childId != null
              ? AnalyticsService.instance.getStudentRank(
                  childId,
                  data?['class_id'] ?? '',
                )
              : null,
          builder: (context, rankSnap) {
            final rankData = rankSnap.data;
            final rankStr = rankData != null
                ? '${rankData['rank']} / ${rankData['total']}'
                : 'N/A';

            return FutureBuilder(
              future: childId != null
                  ? AttendanceService().getAttendanceStats(childId)
                  : null,
              builder: (context, attendanceSnap) {
                final attendanceVal = attendanceSnap.hasData
                    ? '${attendanceSnap.data!.percentage.toInt()}%'
                    : 'N/A';

                final stats = [
                  {
                    'label': 'Attendance',
                    'val': attendanceVal,
                    'sub': 'Present',
                    'icon': Icons.calendar_today_rounded,
                    'color': AppTheme.info,
                  },
                  {
                    'label': 'Average',
                    'val': avgScore,
                    'sub': 'Academic',
                    'icon': Icons.star_rounded,
                    'color': AppTheme.warning,
                  },
                  {
                    'label': 'Class Rank',
                    'val': rankStr,
                    'sub': 'Performance',
                    'icon': Icons.emoji_events_rounded,
                    'color': AppTheme.accent,
                  },
                ];

                return Row(
                  children: stats.asMap().entries.map((entry) {
                    final isLast = entry.key == stats.length - 1;
                    final s = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 12),
                        child: PremiumCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                s['icon'] as IconData,
                                color: s['color'] as Color,
                                size: 18,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s['val'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s['label'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                s['sub'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: s['color'] as Color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, String? childId) {
    final tools = [
      {
        'label': 'Academics',
        'icon': Icons.school_rounded,
        'color': AppTheme.primary,
        'screen': ParentAcademicsScreen(studentId: childId),
      },
      {
        'label': 'Attendance',
        'icon': Icons.event_available_rounded,
        'color': AppTheme.info,
        'screen': ParentAttendanceScreen(studentId: childId),
      },
      {
        'label': 'Assignments',
        'icon': Icons.assignment_rounded,
        'color': AppTheme.parentColor,
        'screen': const ParentAssignmentsScreen(),
      },
      {
        'label': 'AI Insights',
        'icon': Icons.auto_awesome_rounded,
        'color': AppTheme.accent,
        'screen': ParentWellnessScreen(studentId: childId),
      },
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => tools[i]['screen'] as Widget),
          ),
          child: SizedBox(
            width: 88,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (tools[i]['color'] as Color).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    tools[i]['icon'] as IconData,
                    color: tools[i]['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tools[i]['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChildPicker(BuildContext context) {
    final parent = context.read<AuthProvider>().user;
    final childIds = parent?.parentOf ?? [];
    if (childIds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only one child is linked with this account.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: childIds.map((id) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(id).get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final name = data?['name'] ?? 'Student';
                return ListTile(
                  leading: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.parentColor,
                  ),
                  title: Text(name),
                  subtitle: Text(
                    data?['roll_no'] == null ? id : 'Roll No. ${data!['roll_no']}',
                  ),
                  onTap: () {
                    setState(() => _selectedChildId = id);
                    context.read<AnalyticsProvider>().loadStudentAnalytics(id);
                    Navigator.pop(context);
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
