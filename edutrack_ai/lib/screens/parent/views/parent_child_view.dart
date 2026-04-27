import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../widgets/premium_card.dart';
import '../../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../parent_academics_screen.dart';
import '../parent_wellness_screen.dart';
import '../parent_chat_screen.dart';

class ParentChildView extends StatelessWidget {
  const ParentChildView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '';

    if (childId.isEmpty) return const Scaffold(body: Center(child: Text('No student linked')));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(childId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final studentData = snapshot.data!.data() as Map<String, dynamic>;
        final name = studentData['name'] ?? 'Unknown';
        final rollNo = studentData['roll_no'] ?? 'N/A';
        final classId = studentData['class_id'] ?? '';
        final avatarUrl = studentData['avatarUrl'];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.w900)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
          ),
          body: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                _buildProfileHeader(name, rollNo, classId, avatarUrl),
                const TabBar(
                  labelColor: Color(0xFFF97316),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFFF97316),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Academics'),
                    Tab(text: 'Wellness'),
                    Tab(text: 'Activity'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOverviewTab(studentData, childId),
                      _buildAcademicsTab(childId),
                      _buildWellnessTab(childId),
                      _buildActivityTab(childId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildProfileHeader(String name, String rollNo, String classId, String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text('Grade $classId • Roll No. $rollNo', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const Text('EduTrack Primary Hub', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data, String studentId) {
    final name = data['name'] ?? 'Student';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile('Date of Birth', data['dob'] ?? 'N/A'),
              const SizedBox(width: 24),
              _infoTile('Blood Group', data['blood_group'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 20),
          _infoTile('School', 'EduTrack Primary Hub'),
          const SizedBox(height: 32),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').doc(data['class_id']).snapshots(),
            builder: (context, classSnap) {
              final classData = classSnap.data?.data() as Map<String, dynamic>?;
              final teacherName = classData?['teacher_name'] ?? 'Not Assigned';
              
              return PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFF97316), child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class Teacher', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFF97316)), 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentChatScreen(studentId: studentId))),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text('Quick Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Consumer<AnalyticsProvider>(
            builder: (context, analytics, _) {
              final stats = analytics.studentAnalytics;
              final avgScore = stats != null ? "${(stats['avg_score'] as num).toInt()}%" : "N/A";
              return Row(
                children: [
                  _statBox(avgScore, 'Avg Score', Colors.green),
                  const SizedBox(width: 12),
                  _statBox('N/A', 'Class Rank', Colors.blue),
                  const SizedBox(width: 12),
                  _statBox('B+', 'Overall Grade', Colors.purple),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    Text("$name's Strength", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<AnalyticsProvider>(
                  builder: (context, analytics, _) {
                    return Text(
                      analytics.aiPrediction?['performance_insight'] ?? "Working hard to improve academic standards.", 
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5)
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAcademicsTab(String studentId) {
    return ParentAcademicsScreen(studentId: studentId, isEmbedded: true);
  }

  Widget _buildWellnessTab(String studentId) {
    return ParentWellnessScreen(studentId: studentId, isEmbedded: true);
  }


  Widget _buildActivityTab(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quiz_results')
          .where('student_id', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No recent activity'));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['quiz_title'] ?? 'Quiz Result';
            final score = data['score'] ?? 0;
            final total = data['total'] ?? 0;
            final date = (data['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now();

            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.quiz_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd MMM, yyyy').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('$score/$total', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _statBox(String val, String label, Color color) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
