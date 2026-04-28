import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/screens/student/doubt_box_screen.dart';
import 'package:edutrack_ai/screens/parent/request_leave_screen.dart';
import 'package:edutrack_ai/services/leave_service.dart';

class CommunicationView extends StatefulWidget {
  const CommunicationView({super.key});

  @override
  State<CommunicationView> createState() => _CommunicationViewState();
}

class _CommunicationViewState extends State<CommunicationView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final classId = user?.classId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Communication Center', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Announcements', icon: Icon(Icons.campaign_rounded, size: 20)),
            Tab(text: 'Doubts', icon: Icon(Icons.help_center_rounded, size: 20)),
            Tab(text: 'Leaves', icon: Icon(Icons.calendar_today_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncements(classId),
          _buildDoubts(user?.uid ?? ''),
          _buildLeaves(user?.uid ?? '', classId),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(String classId) {
    if (classId.isEmpty) return const Center(child: Text('No class assigned.'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where(Filter.or(
            Filter('class_id', isEqualTo: classId),
            Filter('target', isEqualTo: 'all'),
          ))
          .snapshots(),

      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState('No announcements from teachers yet.', Icons.campaign_outlined);

        // In-memory sorting
        final sortedDocs = docs.toList();
        sortedDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final d = sortedDocs[index].data() as Map<String, dynamic>;
            final time = d['created_at'] as Timestamp?;
            final dateStr = time != null ? DateFormat('dd MMM, hh:mm a').format(time.toDate()) : 'Recently';

            return PremiumCard(
              opacity: 1,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.campaign_rounded, color: Colors.blue, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['teacher_name'] ?? d['title'] ?? 'Announcement', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            Text(dateStr, style: const TextStyle(color: AppTheme.textHint, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(d['message'] ?? d['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),

                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoubts(String userId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtBoxScreen())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ask a New Doubt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doubts')
                .where('studentId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return _buildEmptyState('You haven\'t asked any doubts yet.', Icons.help_outline_rounded);

              final sortedDocs = docs.toList();
              sortedDocs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) {
                  final d = sortedDocs[index].data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'pending';
                  final isAnswered = status == 'answered';

                  return PremiumCard(
                    opacity: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isAnswered ? Colors.green : Colors.orange).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(color: isAnswered ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const Spacer(),
                            Text(d['subject'] ?? 'General', style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(d['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (isAnswered && d['answer'] != null) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(d['answer'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Answered by ${d['answeredBy'] ?? 'Teacher'}', style: const TextStyle(fontSize: 10, color: AppTheme.textHint, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaves(String userId, String classId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestLeaveScreen(studentId: userId, classId: classId))),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Request Leave'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<LeaveRequestModel>>(
            stream: LeaveService().streamParentLeaves(userId), // Using parent leaves as it filters by studentId too if implemented correctly
            builder: (context, snapshot) {
              // Wait, LeaveService streamParentLeaves uses parent_id. 
              // Let's use a raw query if needed or ensure it works for students too.
              // For student, we usually filter by student_id.
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('leave_requests').where('student_id', isEqualTo: userId).snapshots(),
                builder: (context, snap) {
                   if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                   final docs = snap.data!.docs;
                   if (docs.isEmpty) return _buildEmptyState('No leave requests submitted.', Icons.calendar_month_outlined);

                   final sortedDocs = docs.toList();
                   sortedDocs.sort((a, b) {
                     final aTime = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                     final bTime = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                     return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                   });

                   return ListView.builder(
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     itemCount: sortedDocs.length,
                     itemBuilder: (context, index) {
                        final d = sortedDocs[index].data() as Map<String, dynamic>;
                        final status = d['status'] ?? 'pending';
                        final start = (d['start_date'] as Timestamp).toDate();
                        final end = (d['end_date'] as Timestamp).toDate();
                        final range = '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';

                        Color statusColor = Colors.orange;
                        if (status == 'approved') statusColor = Colors.green;
                        if (status == 'rejected') statusColor = Colors.red;

                        return PremiumCard(
                          opacity: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                  const Spacer(),
                                  Text(range, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(d['reason'] ?? 'No reason provided', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Type: ${d['type'] ?? 'Personal'}', style: const TextStyle(fontSize: 10, color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                     },
                   );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
