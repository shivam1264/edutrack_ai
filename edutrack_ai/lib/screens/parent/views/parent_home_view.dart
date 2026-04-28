import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/services/attendance_service.dart';
import 'package:edutrack_ai/services/analytics_service.dart';
import 'package:edutrack_ai/services/class_service.dart';
import 'package:edutrack_ai/models/class_model.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edutrack_ai/screens/parent/parent_wellness_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_academics_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_assignments_screen.dart';
import 'package:edutrack_ai/screens/parent/parent_attendance_screen.dart';
import 'package:edutrack_ai/screens/parent/views/parent_profile_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_updates_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_child_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_insights_view.dart';

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
        final firstChildId = linkedChildren.first;
        context.read<AnalyticsProvider>().loadStudentAnalytics(firstChildId);
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
                _buildWellnessCard(context, childId),
                const SizedBox(height: 24),
                _buildSectionHeader('Today at a Glance', onTap: () {
                  if (childId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAcademicsScreen(studentId: childId)));
                  }
                }),
                const SizedBox(height: 12),
                _buildStatsGlance(childId),
                const SizedBox(height: 24),
                _buildSectionHeader('Quick Access'),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(context, childId),
                const SizedBox(height: 24),
                _buildSectionHeader('Recent Updates', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentUpdatesView()));
                }),
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
                    Text('Welcome to Guardian Portal', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentProfileView())),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) 
                        ? NetworkImage(user!.avatarUrl!) 
                        : null,
                    child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty) 
                        ? const Icon(Icons.person_rounded, color: Colors.white, size: 20) 
                        : null,
                  ),
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
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    if (classId != null) 
                      StreamBuilder<ClassModel>(
                        stream: ClassService().getClassById(classId),
                        builder: (context, classSnap) {
                          final className = classSnap.data?.displayName ?? 'Loading...';
                          return Text('Grade $className • Roll No. $rollNo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13));
                        }
                      )
                    else
                      Text('Grade N/A • Roll No. $rollNo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const Text('EduTrack Primary Hub', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showChildPicker(context),
                child: const Text('Switch Child', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
      }
    );
  }

  Widget _buildWellnessCard(BuildContext context, String? childId) {
    final wellnessData = context.watch<AnalyticsProvider>().wellnessFor(childId ?? '');
    final riskLevel = wellnessData?['risk_level'] ?? 'Low';
    final wellnessMsg = riskLevel == 'Low' ? 'Your child is doing well!' : (riskLevel == 'High' ? 'Attention may be required' : 'Monitor progress closely');
    final wellnessSub = riskLevel == 'Low' ? 'Keep up the encouragement.' : 'Review recent activity.';
    final riskColor = riskLevel == 'High' ? Colors.red : (riskLevel == 'Medium' ? Colors.orange : Colors.green);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentWellnessScreen(studentId: childId))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [riskColor.withOpacity(0.8), riskColor],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wellnessMsg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(wellnessSub, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                Text('Risk Level', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(riskLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }


  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        if (onTap != null) TextButton(onPressed: onTap, child: const Text('View All', style: TextStyle(fontSize: 12))),
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
                            Text(s['val'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            Text(s['label'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
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
      {'label': 'Academics', 'icon': Icons.school_rounded, 'color': Colors.indigo, 'screen': ParentAcademicsScreen(studentId: childId)},
      {'label': 'Attendance', 'icon': Icons.event_available_rounded, 'color': Colors.blue, 'screen': ParentAttendanceScreen(studentId: childId)},
      {'label': 'Assignments', 'icon': Icons.assignment_rounded, 'color': Colors.orange, 'screen': const ParentAssignmentsScreen()},
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
              return const Center(child: Text('No recent updates.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)));
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
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            Text(content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(timeAgo, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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

  void _showChildPicker(BuildContext context) {
    final parent = context.read<AuthProvider>().user;
    final childIds = parent?.parentOf ?? [];
    if (childIds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one child is linked with this account.')),
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
                  leading: const Icon(Icons.person_rounded, color: Color(0xFFF97316)),
                  title: Text(name),
                  subtitle: Text(data?['roll_no'] == null ? id : 'Roll No. ${data!['roll_no']}'),
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
