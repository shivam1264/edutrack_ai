import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminTeacherDetailScreen extends StatefulWidget {
  final Map<String, dynamic> teacherData;
  final String teacherId;

  const AdminTeacherDetailScreen({super.key, required this.teacherData, required this.teacherId});

  @override
  State<AdminTeacherDetailScreen> createState() => _AdminTeacherDetailScreenState();
}

class _AdminTeacherDetailScreenState extends State<AdminTeacherDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.teacherId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? widget.teacherData;
        final subjects = List<String>.from(data['subjects'] ?? []);
        final classes = List<String>.from(data['assigned_classes'] ?? []);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, data),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('Academic Portfolio', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    _buildSection('Specialized Subjects', subjects, Icons.book_rounded, Colors.blue),
                    const SizedBox(height: 16),
                    _buildSection('Assigned Classes', classes, Icons.hub_rounded, Colors.purple),
                    const SizedBox(height: 32),
                    Text('Performance Snapshot', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    _buildEngagementStats(),
                    const SizedBox(height: 32),
                    Text('Professional Profile', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    _buildInfoTile('Email Address', data['email'] ?? 'N/A', Icons.email_outlined),
                    _buildInfoTile('Phone Number', data['phone'] ?? 'Not Linked', Icons.phone_android_rounded),
                    _buildInfoTile('Qualification', data['qualification'] ?? 'Not Specified', Icons.school_outlined),
                    _buildInfoTile('Date of Joining', data['doj'] ?? 'N/A', Icons.calendar_month_rounded),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editTeacherProfileDialog(data),
            backgroundColor: const Color(0xFF0F172A),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            label: const Text('Edit Teacher Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
    );
  }

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.05),
                    child: Text(data['name']?[0].toUpperCase() ?? 'T', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Faculty Member', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Senior Instructor • ${data['status']?.toUpperCase() ?? "ACTIVE"}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
              child: Text(item, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
          if (items.isEmpty) const Text('No assignments yet', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    return FutureBuilder<List<AggregateQuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('notes').where('teacherId', isEqualTo: widget.teacherId).count().get(),
        FirebaseFirestore.instance.collection('doubts').where('answeredBy', isEqualTo: widget.teacherData['name'] ?? '').count().get(),
        FirebaseFirestore.instance.collection('assignments').where('teacher_id', isEqualTo: widget.teacherId).count().get(),
      ]),
      builder: (context, snapshot) {
        final notesCount = snapshot.data?[0].count ?? 0;
        final doubtsCount = snapshot.data?[1].count ?? 0;
        final assignCount = snapshot.data?[2].count ?? 0;

        return Row(
          children: [
            _StatBox('Notes Shared', notesCount.toString(), Colors.orange),
            const SizedBox(width: 12),
            _StatBox('Doubts Solved', doubtsCount.toString(), Colors.green),
            const SizedBox(width: 12),
            _StatBox('Assignments', assignCount.toString(), Colors.blue),
          ],
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editTeacherProfileDialog(Map<String, dynamic> data) {
    final phoneCtrl = TextEditingController(text: data['phone']);
    final qualCtrl = TextEditingController(text: data['qualification']);
    final dojCtrl = TextEditingController(text: data['doj']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Update Faculty Record', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextField(controller: qualCtrl, decoration: const InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school))),
            const SizedBox(height: 12),
            TextField(controller: dojCtrl, decoration: const InputDecoration(labelText: 'Date of Joining', prefixIcon: Icon(Icons.calendar_today))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).update({
                'phone': phoneCtrl.text.trim(),
                'qualification': qualCtrl.text.trim(),
                'doj': dojCtrl.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Faculty Info'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
