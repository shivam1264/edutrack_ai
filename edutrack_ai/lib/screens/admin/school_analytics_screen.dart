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
                          Text('Institution-wide performance overview', style: TextStyle(color: Colors.white70)),
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
                    const SizedBox(height: 20),
                    const Text('📊 Class Performance', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildClassBreakdown(classSnap.data ?? []),
                    const SizedBox(height: 20),
                    const Text('👨‍🏫 Teacher Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildTeacherStats(classMap),
                    const SizedBox(height: 20),
                    const Text('🎯 Doubt Resolution', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    _buildDoubtStats(),
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
            _StatCard('👨‍🎓 Students', '${data['students'] ?? '--'}', AppTheme.primary),
            _StatCard('👩‍🏫 Teachers', '${data['teachers'] ?? '--'}', const Color(0xFF059669)),
            _StatCard('📝 Assignments', '${data['assignments'] ?? '--'}', const Color(0xFFD97706)),
            _StatCard('❓ Doubts', '${data['doubts'] ?? '--'}', const Color(0xFF7C3AED)),
          ].asMap().entries.map((e) => e.value.animate().fadeIn(delay: (e.key * 100).ms).scale()).toList(),
        );
      },
    );
  }

  Widget _buildClassBreakdown(List<ClassModel> classes) {
    if (classes.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No classes configured yet', style: TextStyle(color: Colors.grey))));
    }
    return Column(
      children: classes.asMap().entries.map((e) {
        final cls = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.class_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const Text('Active Academic Stream', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Live', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 12)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (e.key * 80).ms),
        );
      }).toList(),
    );
  }

  Widget _buildTeacherStats(Map<String, String> classMap) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final teachers = snap.data!.docs;
        return Column(
          children: teachers.asMap().entries.map((e) {
            final d = e.value.data() as Map<String, dynamic>;
            final assigned = d['assigned_classes'] as List<dynamic>? ?? (d['class_id'] != null ? [d['class_id']] : []);
            final classNames = assigned.map((id) => classMap[id] ?? id).join(', ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                    child: Text((d['name'] ?? 'T')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                  ),
                  title: Text(d['name'] ?? 'Teacher', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(classNames.isEmpty ? 'No Classes' : classNames, 
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Active', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
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
        final pending = (data['pending'] ?? 0);
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
                  _DoubtStat('Pending', '$pending', Colors.orange),
                  _DoubtStat('Rate', '$rate%', const Color(0xFF7C3AED)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? answered / total : 0,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text('$rate% doubts resolved', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
      FirebaseFirestore.instance.collection('assignments').count().get(),
      FirebaseFirestore.instance.collection('doubts').count().get(),
    ]);
    return {
      'students': futures[0].count ?? 0,
      'teachers': futures[1].count ?? 0,
      'assignments': futures[2].count ?? 0,
      'doubts': futures[3].count ?? 0,
    };
  }

  Future<Map<String, int>> _getDoubtStats() async {
    final total = await FirebaseFirestore.instance.collection('doubts').count().get();
    final answered = await FirebaseFirestore.instance.collection('doubts')
        .where('status', whereIn: ['answered', 'ai_answered']).count().get();
    final pending = await FirebaseFirestore.instance.collection('doubts')
        .where('status', isEqualTo: 'pending').count().get();
    return {
      'total': total.count ?? 0,
      'answered': answered.count ?? 0,
      'pending': pending.count ?? 0,
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
