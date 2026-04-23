import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIRiskReportScreen extends StatelessWidget {
  const AIRiskReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('AI Risk Monitor', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                            child: const Text('PROACTIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Identifying the Top 10 students requiring academic intervention.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ai_predictions')
                  .where('risk_level', whereIn: ['high', 'medium'])
                  .orderBy('risk_level', descending: false) // 'high' usually comes first if filtered correctly or just use secondary sort
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 64, color: Colors.green.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text('All students are currently within safe academic thresholds.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final studentId = data['student_id'] ?? '';
                      final risk = data['risk_level'] ?? 'medium';
                      final score = (data['performance_score'] as num? ?? 0.0);
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                        builder: (context, userSnap) {
                          final userData = userSnap.data?.data() as Map<String, dynamic>?;
                          final name = userData?['name'] ?? 'Loading Student...';
                          final classId = userData?['class_id'] ?? 'Unknown Class';

                          return PremiumCard(
                            opacity: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (risk == 'high' ? Colors.red : Colors.orange).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    risk == 'high' ? Icons.gpp_maybe_rounded : Icons.warning_amber_rounded,
                                    color: risk == 'high' ? Colors.red : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                                      Text('Class: $classId', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(score * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: risk == 'high' ? Colors.red : Colors.orange),
                                    ),
                                    Text(
                                      risk.toUpperCase(),
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: risk == 'high' ? Colors.red : Colors.orange),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
                        },
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
