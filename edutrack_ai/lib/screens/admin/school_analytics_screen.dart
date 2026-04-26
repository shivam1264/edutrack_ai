import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SchoolAnalyticsScreen extends StatelessWidget {
  const SchoolAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: StreamBuilder<List<ClassModel>>(
        stream: ClassService().getClasses(),
        builder: (context, classSnap) {
          final Map<String, String> classMap = { for (var c in classSnap.data ?? []) c.id : c.displayName };
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppTheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppTheme.meshGradient),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('School Analytics', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          Text('Real-time institutional performance hub', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildOverallStats(),
                    const SizedBox(height: 24),
                    const Text('📊 Enrollment & Unit Distribution', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildClassBreakdown(classSnap.data ?? []),
                    const SizedBox(height: 24),
                    const Text('👩‍🏫 Faculty Engagement', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildTeacherStats(classMap),
                    const SizedBox(height: 24),
                    const Text('🎯 AI Doubt Resolution Efficiency', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildDoubtStats(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildOverallStats() {
    return FutureBuilder<Map<String, int>>(
      future: _getOverallStats(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard('👨‍🎓 Total Students', '${data['students'] ?? '--'}', AppTheme.primary),
            _StatCard('👩‍🏫 Active Faculty', '${data['teachers'] ?? '--'}', const Color(0xFF059669)),
            _StatCard('📝 Total Lessons', '${data['lessons'] ?? '--'}', const Color(0xFFD97706)),
            _StatCard('❓ Global Doubts', '${data['doubts'] ?? '--'}', const Color(0xFF7C3AED)),
          ].asMap().entries.map((e) => e.value.animate().fadeIn(delay: (e.key * 100).ms).scale()).toList(),
        );
      },
    );
  }

  Widget _buildClassBreakdown(List<ClassModel> classes) {
    if (classes.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No academic units configured.', style: TextStyle(color: Colors.grey))));
    }
    return Column(
      children: classes.asMap().entries.map((e) {
        final cls = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FutureBuilder<int>(
            future: _getStudentCount(cls.id),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.hub_rounded, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cls.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text('Head: ${cls.classTeacherName ?? "Unassigned"}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$count', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 18)),
                        const Text('Students', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (e.key * 80).ms);
            }
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeacherStats(Map<String, String> classMap) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final teachers = snap.data!.docs;
        return Column(
          children: teachers.asMap().entries.map((e) {
            final d = e.value.data() as Map<String, dynamic>;
            final subjects = (d['subjects'] as List<dynamic>? ?? []).join(', ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                      child: Text((d['name'] ?? 'T')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['name'] ?? 'Faculty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(subjects.isEmpty ? 'General' : subjects, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.trending_up_rounded, color: Colors.green, size: 16),
                  ],
                ),
              ).animate().fadeIn(delay: (e.key * 60).ms),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDoubtStats() {
    return FutureBuilder<Map<String, int>>(
      future: _getDoubtStats(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final total = (data['total'] ?? 0);
        final answered = (data['answered'] ?? 0);
        final rate = total > 0 ? (answered / total * 100).toStringAsFixed(0) : '0';

        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DoubtStat('Total', '$total', Colors.blue),
                  _DoubtStat('Answered', '$answered', Colors.green),
                  _DoubtStat('Efficiency', '$rate%', const Color(0xFF7C3AED)),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: total > 0 ? answered / total : 0,
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text('System resolution rate: $rate%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ).animate().fadeIn().scale();
      },
    );
  }

  Future<Map<String, int>> _getOverallStats() async {
    final futures = await Future.wait([
      FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').count().get(),
      FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').count().get(),
      FirebaseFirestore.instance.collection('lesson_plans').count().get(),
      FirebaseFirestore.instance.collection('doubts').count().get(),
    ]);
    return {
      'students': futures[0].count ?? 0,
      'teachers': futures[1].count ?? 0,
      'lessons': futures[2].count ?? 0,
      'doubts': futures[3].count ?? 0,
    };
  }

  Future<int> _getStudentCount(String classId) async {
    final snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').where('class_id', isEqualTo: classId).count().get();
    return snap.count ?? 0;
  }

  Future<Map<String, int>> _getDoubtStats() async {
    final total = await FirebaseFirestore.instance.collection('doubts').count().get();
    final answered = await FirebaseFirestore.instance.collection('doubts').where('status', whereIn: ['answered', 'ai_answered']).count().get();
    return {
      'total': total.count ?? 0,
      'answered': answered.count ?? 0,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DoubtStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DoubtStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
