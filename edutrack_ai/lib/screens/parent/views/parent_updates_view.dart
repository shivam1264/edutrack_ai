import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class ParentUpdatesView extends StatelessWidget {
  const ParentUpdatesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Updates', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Notices'),
                Tab(text: 'Messages'),
                Tab(text: 'Alerts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUpdatesList(null),
                  _buildUpdatesList('Notice'),
                  _buildUpdatesList('Message'),
                  _buildUpdatesList('Alert'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesList(String? filterType) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '';

        if (childId.isEmpty) return const Center(child: Text('No student linked'));

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(childId).get(),
          builder: (context, studentSnap) {
            if (!studentSnap.hasData) return const Center(child: CircularProgressIndicator());
            
            final classId = (studentSnap.data?.data() as Map<String, dynamic>?)?['class_id'] ?? '';

            return StreamBuilder<QuerySnapshot>(
              stream: filterType == null 
                  ? FirebaseFirestore.instance.collection('announcements')
                      .where(Filter.or(
                        Filter('class_id', isEqualTo: classId),
                        Filter('target', isEqualTo: 'all'),
                      ))
                      .snapshots()
                  : FirebaseFirestore.instance.collection('announcements')
                      .where(Filter.or(
                        Filter('class_id', isEqualTo: classId),
                        Filter('target', isEqualTo: 'all'),
                      ))
                      .where('type', isEqualTo: filterType)
                      .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final announcements = snapshot.data!.docs;
                
                if (announcements.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No ${filterType ?? ""} updates found.', style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ));
                }

                // Sort locally
                final sortedDocs = announcements.toList();
                sortedDocs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                  return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  itemCount: sortedDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final doc = sortedDocs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? data['teacher_name'] ?? 'Update';
                    final content = data['content'] ?? data['message'] ?? '';

                    final timestamp = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final timeAgo = _getTimeAgo(timestamp);
                    final type = data['type'] ?? 'Notice';

                    IconData icon = Icons.campaign_rounded;
                    Color color = Colors.orange;

                    if (type == 'Alert') {
                      icon = Icons.warning_amber_rounded;
                      color = Colors.red;
                    } else if (type == 'Message') {
                      icon = Icons.chat_bubble_rounded;
                      color = Colors.green;
                    }

                    return PremiumCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text(content, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
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
