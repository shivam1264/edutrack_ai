import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const AdminStudentDetailScreen({super.key, required this.studentData, required this.studentId});

  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.studentId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? widget.studentData;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildAppBar(context, data, innerBoxIsScrolled),
              ],
              body: TabBarView(
                children: [
                  _buildOverviewTab(data),
                  _buildAttendanceTab(),
                  _buildPerformanceTab(),
                  _buildDetailsTab(data),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editProfileDialog(data),
            backgroundColor: const Color(0xFF0F172A),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            label: const Text('Update Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
    );
  }

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> data, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      forceElevated: innerBoxIsScrolled,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Text(data['name']?[0].toUpperCase() ?? 'S', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Unknown Student', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Class ${data['class_id'] ?? "N/A"} • Roll No. ${data['roll_no'] ?? "N/A"}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                        Text('UID: ${widget.studentId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.3))),
                          child: Text(data['status']?.toUpperCase() ?? 'ACTIVE', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0F172A),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Attendance'),
              Tab(text: 'Results'),
              Tab(text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF0F172A),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Attendance'),
          Tab(text: 'Results'),
          Tab(text: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('attendance').where('student_id', isEqualTo: widget.studentId).snapshots(),
          builder: (context, snapshot) {
            final attendDocs = snapshot.data?.docs ?? [];
            final total = attendDocs.length;
            final present = attendDocs.where((d) => (d.data() as Map)['status'] == 'present').length;
            final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('quiz_results').where('student_id', isEqualTo: widget.studentId).snapshots(),
              builder: (context, quizSnapshot) {
                final quizDocs = quizSnapshot.data?.docs ?? [];
                double totalQuizScore = 0;
                int quizCount = 0;
                Map<String, List<double>> subjectScores = {};

                for (var doc in quizDocs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final score = (d['score'] as num?)?.toDouble() ?? 0;
                  final total = (d['total'] as num?)?.toDouble() ?? 1;
                  final percentage = (score / total) * 100;
                  totalQuizScore += percentage;
                  quizCount++;

                  final sub = d['subject'] ?? 'General';
                  subjectScores.putIfAbsent(sub, () => []).add(percentage);
                }

                final avgScore = quizCount > 0 ? (totalQuizScore / quizCount).toStringAsFixed(1) : '0.0';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatCard(label: 'Attendance', value: '$rate%', color: Colors.blue),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Avg Score', value: '$avgScore%', color: Colors.green),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Rank', value: data['rank']?.toString() ?? 'N/A', color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Academic Performance', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 16),
                      _buildPerformanceBars(subjectScores),
                      const SizedBox(height: 32),
                      PremiumCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                                SizedBox(width: 8),
                                Text('AI Behavioral Insight', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.purple, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('${data['name']} shows high engagement in technical subjects. Attendance consistency is improving. Recommended to focus on language-based assignments.', 
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
  }

  Widget _buildAttendanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').where('student_id', isEqualTo: widget.studentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No attendance history found.'));

        // Sort in-memory to avoid composite index requirement
        final sortedDocs = docs.toList()..sort((a, b) {
          final aDate = (a.data() as Map)['date'] as Timestamp?;
          final bDate = (b.data() as Map)['date'] as Timestamp?;
          return (bDate ?? Timestamp.now()).compareTo(aDate ?? Timestamp.now());
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final data = sortedDocs[index].data() as Map<String, dynamic>;
            final isPresent = data['status'] == 'present';
            return Card(
              elevation: 0, color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isPresent ? Colors.green : Colors.red),
                title: Text(data['date'] ?? 'Unknown Date', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Marked by ${data['marked_by'] ?? "System"}'),
                trailing: Text(isPresent ? 'PRESENT' : 'ABSENT', style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quiz_results').where('student_id', isEqualTo: widget.studentId).snapshots(),
      builder: (context, snapshot) {
        final results = snapshot.data?.docs ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No exam results recorded yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final res = results[index].data() as Map<String, dynamic>;
            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: const Color(0xFFE2E8F0))
                    ),
                    child: const Icon(Icons.assignment_rounded, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(res['examName'] ?? 'Unit Test', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text(res['subject'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('${res['score'] ?? 0}/${res['total'] ?? 100}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERSONAL INFORMATION', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildInfoRow('Full Name', data['name'] ?? 'N/A', Icons.person_outline_rounded),
          _buildInfoRow('Email Address', data['email'] ?? 'N/A', Icons.email_outlined),
          _buildInfoRow('Phone Number', data['phone'] ?? 'Not Linked', Icons.phone_android_rounded),
          _buildInfoRow('Date of Birth', data['dob'] ?? 'Not Specified', Icons.calendar_today_rounded),
          _buildInfoRow('Gender', data['gender'] ?? 'Not Specified', Icons.transgender_rounded),
          
          const SizedBox(height: 32),
          const Text('ACADEMIC BINDING', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildInfoRow('Roll Number', data['roll_no'] ?? 'Unassigned', Icons.tag_rounded),
          _buildInfoRow('Class ID', data['class_id'] ?? 'Unassigned', Icons.hub_rounded),
          _buildInfoRow('Father\'s Name', data['father_name'] ?? 'N/A', Icons.family_restroom_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfileDialog(Map<String, dynamic> data) {
    final phoneCtrl = TextEditingController(text: data['phone']);
    final dobCtrl = TextEditingController(text: data['dob']);
    final genderCtrl = TextEditingController(text: data['gender']);
    final fatherCtrl = TextEditingController(text: data['father_name']);
    final rollCtrl = TextEditingController(text: data['roll_no']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Update Personal Info', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 12),
              TextField(controller: dobCtrl, decoration: const InputDecoration(labelText: 'Date of Birth (DD/MM/YYYY)', prefixIcon: Icon(Icons.calendar_month))),
              const SizedBox(height: 12),
              TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.transgender))),
              const SizedBox(height: 12),
              TextField(controller: fatherCtrl, decoration: const InputDecoration(labelText: 'Father\'s Name', prefixIcon: Icon(Icons.family_restroom))),
              const SizedBox(height: 12),
              TextField(controller: rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number', prefixIcon: Icon(Icons.tag))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(widget.studentId).update({
                'phone': phoneCtrl.text.trim(),
                'dob': dobCtrl.text.trim(),
                'gender': genderCtrl.text.trim(),
                'father_name': fatherCtrl.text.trim(),
                'roll_no': rollCtrl.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBars(Map<String, List<double>> subjectScores) {
    if (subjectScores.isEmpty) {
      return const Text('No quiz data available for breakdown.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic));
    }

    final subjectAvg = subjectScores.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));

    return Column(
      children: subjectAvg.entries.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                Text('${s.value.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: s.value / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
