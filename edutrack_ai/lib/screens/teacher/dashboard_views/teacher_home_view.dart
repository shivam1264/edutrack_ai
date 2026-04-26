import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/screens/attendance/teacher_attendance_screen.dart';
import 'package:edutrack_ai/screens/assignments/create_assignment_screen.dart';
import 'package:edutrack_ai/screens/quiz/create_quiz_screen.dart';
import 'package:edutrack_ai/screens/teacher/upload_notes_screen.dart';
import 'package:edutrack_ai/screens/teacher/teacher_announcements_screen.dart';
import 'package:edutrack_ai/screens/teacher/bulk_grade_screen.dart';

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
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTodayOverview(classData, context),
                const SizedBox(height: 24),
                _buildClassPerformanceChart(classData),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentActivity(classData),
                const SizedBox(height: 100), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF059669),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user?.avatarUrl != null ? CachedNetworkImageProvider(user!.avatarUrl!) : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'T',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning, ${user?.name.split(' ').first ?? 'Teacher'}! 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Class: $currentClassName • Science Teacher',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Badge(
                    label: Text('3'),
                    child: Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview(Map<String, dynamic>? data, BuildContext context) {
    final students = (data?['students'] as List?)?.length ?? 0;
    final avg = (data?['class_avg'] as num? ?? 0).toStringAsFixed(0);
    final pendingTasks = data?['pending_tasks'] ?? 0;
    final announcements = data?['announcements_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today at a Glance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Text(
              DateFormat('MMMM dd, yyyy').format(DateTime.now()),
              style: TextStyle(fontSize: 14, color: AppTheme.secondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('$avg%', 'Attendance', Icons.bar_chart_rounded, Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(classId: selectedClassId ?? '', className: currentClassName)));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('$students', 'Students', Icons.people_outline_rounded, Colors.blue, () {
              // Navigation to students tab or list
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('$pendingTasks', 'Pending Tasks', Icons.assignment_outlined, Colors.orange, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => BulkGradeScreen(classId: selectedClassId ?? '')));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('$announcements', 'Announcements', Icons.campaign_outlined, Colors.red, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAnnouncementsScreen(classId: selectedClassId ?? '')));
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassPerformanceChart(Map<String, dynamic>? data) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Class Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Row(
                  children: [
                    Text('This Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                        if (value.toInt() < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 70),
                      const FlSpot(1, 60),
                      const FlSpot(2, 65),
                      const FlSpot(3, 80),
                      const FlSpot(4, 75),
                      const FlSpot(5, 85),
                    ],
                    isCurved: true,
                    color: AppTheme.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.secondary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Text(
              'Edit',
              style: TextStyle(fontSize: 14, color: AppTheme.secondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildActionButton(context, Icons.how_to_reg_rounded, 'Mark\nAttendance', Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(classId: selectedClassId ?? '', className: currentClassName)));
              }),
              const SizedBox(width: 16),
              _buildActionButton(context, Icons.assignment_add, 'New\nAssignment', Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen(classId: selectedClassId ?? '')));
              }),
              const SizedBox(width: 16),
              _buildActionButton(context, Icons.quiz_outlined, 'New\nQuiz', Colors.red, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizScreen(classId: selectedClassId ?? '')));
              }),
              const SizedBox(width: 16),
              _buildActionButton(context, Icons.upload_file_rounded, 'Upload\nNotes', Colors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UploadNotesScreen(classId: selectedClassId ?? '')));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic>? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('submissions')
              .where('class_id', isEqualTo: selectedClassId)
              .limit(10) // Fetch slightly more to sort in memory
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 10, color: Colors.red)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No recent activity', style: TextStyle(color: Colors.grey, fontSize: 12)));
            }

            // Sort in memory to avoid needing a composite index
            final docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['submitted_at'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['submitted_at'] as Timestamp?;
              return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
            });

            return Column(
              children: docs.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final studentId = data['student_id'] as String? ?? 'Unknown';
                final timestamp = (data['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now();
                final timeAgo = _getTimeAgo(timestamp);
                
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                  builder: (context, userSnap) {
                    final userData = userSnap.data?.data() as Map<String, dynamic>?;
                    final studentName = userData?['name'] ?? (studentId.length > 8 ? 'Student ${studentId.substring(0, 8)}...' : 'Student $studentId');
                    
                    return _buildActivityItem(
                      'New Submission',
                      'By $studentName',
                      timeAgo,
                      Icons.assignment_turned_in_rounded,
                      Colors.green,
                    );
                  }
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w600)),
        ],
      ),
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
