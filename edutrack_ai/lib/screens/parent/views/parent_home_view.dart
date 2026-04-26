import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../services/attendance_service.dart';
import '../../../services/analytics_service.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
import '../../../widgets/premium_card.dart';
import '../../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../parent_wellness_screen.dart';
import '../parent_academics_screen.dart';
import '../parent_assignments_screen.dart';
import '../parent_attendance_screen.dart';

class ParentHomeView extends StatelessWidget {
  const ParentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<AuthProvider>().user;
    final childId = (parent?.parentOf != null && parent!.parentOf!.isNotEmpty) ? parent.parentOf!.first : null;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, parent),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildChildCard(context, childId),
                const SizedBox(height: 20),
                _buildWellnessCard(context),
                const SizedBox(height: 24),
                _buildSectionHeader('Today at a Glance'),
                const SizedBox(height: 12),
                _buildStatsGlance(childId),
                const SizedBox(height: 24),
                _buildSectionHeader('Quick Access'),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(context, childId),
                const SizedBox(height: 24),
                _buildSectionHeader('Recent Updates'),
                const SizedBox(height: 12),
                _buildUpdatesList(childId),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFFF97316),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Hello, ${user?.name.split(' ').first ?? 'Parent'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        const Text('👋', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const Text('Welcome to Guardian Portal', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, String? childId) {
    return FutureBuilder<DocumentSnapshot>(
      future: childId != null ? FirebaseFirestore.instance.collection('users').doc(childId).get() : null,
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
                radius: 30,
                backgroundColor: Colors.orange.withOpacity(0.1),
                child: Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    if (classId != null) 
                      StreamBuilder<ClassModel>(
                        stream: ClassService().getClassById(classId),
                        builder: (context, classSnap) {
                          final className = classSnap.data?.displayName ?? 'Loading...';
                          return Text('Grade $className • Roll No. $rollNo', style: const TextStyle(color: Colors.grey, fontSize: 13));
                        }
                      )
                    else
                      Text('Grade N/A • Roll No. $rollNo', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const Text('EduTrack Primary Hub', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Switch Child', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
      }
    );
  }

  Widget _buildWellnessCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your child is doing well!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Keep up the encouragement.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              const Text('Risk Level', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Text('Low', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildStatsGlance(String? childId) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        final data = analytics.studentAnalytics;
        final avgScore = data != null ? "${(data['avg_score'] as double).toInt()}%" : "N/A";
        
        return FutureBuilder<Map<String, dynamic>?>(
          future: childId != null ? AnalyticsService.instance.getStudentRank(childId, data?['class_id'] ?? '') : null,
          builder: (context, rankSnap) {
            final rankData = rankSnap.data;
            final rankStr = rankData != null ? "${rankData['rank']} / ${rankData['total']}" : "N/A";

            return FutureBuilder(
              future: childId != null ? AttendanceService().getAttendanceStats(childId) : null,
              builder: (context, attendanceSnap) {
                final attendanceVal = attendanceSnap.hasData ? "${attendanceSnap.data!.percentage.toInt()}%" : "N/A";
                
                final stats = [
                  {'label': 'Attendance', 'val': attendanceVal, 'sub': 'Present', 'icon': Icons.calendar_today_rounded, 'color': Colors.blue},
                  {'label': 'Avg Score', 'val': avgScore, 'sub': 'Academic', 'icon': Icons.star_rounded, 'color': Colors.amber},
                  {'label': 'Class Rank', 'val': rankStr, 'sub': 'Performance', 'icon': Icons.emoji_events_rounded, 'color': Colors.purple},
                ];

                return Row(
                  children: stats.map((s) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                            const SizedBox(height: 8),
                            Text(s['val'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                            Text(s['label'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(s['sub'] as String, style: TextStyle(fontSize: 9, color: s['color'] as Color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, String? childId) {
    final tools = [
      {'label': 'Wellness', 'icon': Icons.favorite_rounded, 'color': Colors.teal, 'screen': ParentWellnessScreen(studentId: childId)},
      {'label': 'Academics', 'icon': Icons.school_rounded, 'color': Colors.indigo, 'screen': ParentAcademicsScreen(studentId: childId)},
      {'label': 'Assignments', 'icon': Icons.assignment_rounded, 'color': Colors.orange, 'screen': ParentAttendanceScreen(studentId: childId)},
      {'label': 'Attendance', 'icon': Icons.event_available_rounded, 'color': Colors.blue, 'screen': ParentAttendanceScreen(studentId: childId)},
      {'label': 'AI Insights', 'icon': Icons.auto_awesome_rounded, 'color': Colors.purple, 'screen': ParentWellnessScreen(studentId: childId)},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tools[i]['screen'] as Widget)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (tools[i]['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(tools[i]['icon'] as IconData, color: tools[i]['color'] as Color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(tools[i]['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdatesList(String? childId) {
    return FutureBuilder<DocumentSnapshot>(
      future: childId != null ? FirebaseFirestore.instance.collection('users').doc(childId).get() : null,
      builder: (context, studentSnap) {
        final classId = (studentSnap.data?.data() as Map<String, dynamic>?)?['class_id'];
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('announcements')
              .where('class_id', isEqualTo: classId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No recent updates.', style: TextStyle(color: Colors.grey, fontSize: 12)));
            }

            // Sort locally to avoid needing a composite index
            final docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
              return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
            });

            final recentDocs = docs.take(5).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentDocs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final doc = recentDocs[i];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Announcement';
                final content = data['content'] ?? '';
                final timestamp = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
                final timeAgo = _getTimeAgo(timestamp);

                return PremiumCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.campaign_rounded, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                );
              }
            );
          }
        );
      }
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
