import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherPerformanceScreen extends StatelessWidget {
  const TeacherPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFFC026D3),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC026D3), Color(0xFFE879F9)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Teacher Performance', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('Activity and engagement metrics', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
              final teachers = snap.data!.docs;

              if (teachers.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No teachers found', style: TextStyle(color: Colors.grey)))));
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc = teachers[i];
                      return _TeacherPerformanceCard(teacherId: doc.id, data: doc.data() as Map<String, dynamic>)
                          .animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1);
                    },
                    childCount: teachers.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TeacherPerformanceCard extends StatelessWidget {
  final String teacherId;
  final Map<String, dynamic> data;

  const _TeacherPerformanceCard({required this.teacherId, required this.data});

  Future<Map<String, int>> _getStats() async {
    final futures = await Future.wait([
      FirebaseFirestore.instance.collection('doubts').where('answeredBy', isEqualTo: data['name'] ?? '').count().get(),
      FirebaseFirestore.instance.collection('notes').where('teacherId', isEqualTo: teacherId).count().get(),
      FirebaseFirestore.instance.collection('assignments').where('teacherId', isEqualTo: teacherId).count().get(),
      FirebaseFirestore.instance.collection('lesson_plans').where('teacherId', isEqualTo: teacherId).count().get(),
    ]);

    return {
      'doubts': futures[0].count ?? 0,
      'notes': futures[1].count ?? 0,
      'assignments': futures[2].count ?? 0,
      'plans': futures[3].count ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFC026D3).withOpacity(0.1),
                  child: Text((data['name'] ?? 'T')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFC026D3), fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Teacher', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                      Text('${data['email'] ?? ''} | Class ${data['classId'] ?? 'NA'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, int>>(
              future: _getStats(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()));
                final stats = snap.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(stats['assignments'].toString(), 'Assignments', Icons.auto_awesome_mosaic_rounded, AppTheme.primary),
                    _StatCol(stats['doubts'].toString(), 'Doubts', Icons.help_center_rounded, const Color(0xFF7C3AED)),
                    _StatCol(stats['notes'].toString(), 'Notes', Icons.menu_book_rounded, const Color(0xFF059669)),
                    _StatCol(stats['plans'].toString(), 'AI Plans', Icons.psychology_rounded, const Color(0xFF1D4ED8)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCol(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
