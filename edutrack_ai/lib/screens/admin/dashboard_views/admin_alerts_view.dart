import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../announcement_screen.dart';
import 'package:intl/intl.dart';

class AdminAlertsView extends StatelessWidget {
  const AdminAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: const Text('Security & Alerts', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            floating: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_alert_rounded), 
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen())),
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // ─── AI Risk Section ──────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('AI CRITICAL RISKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ai_predictions')
                .where('risk_level', isEqualTo: 'high')
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              final risks = snapshot.data?.docs ?? [];
              if (risks.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('No critical student risks detected.', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = risks[index].data() as Map<String, dynamic>;
                    return _buildRiskAlert(context, data, index);
                  },
                  childCount: risks.length,
                ),
              );
            }
          ),

          // ─── System Announcements ─────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('SYSTEM BROADCASTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.blue)),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            // Removed orderBy to ensure all documents show up even if createdAt is missing/pending
            stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
              
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No active announcements', style: TextStyle(color: Color(0xFF475569)))),
                  ),
                );
              }

              // In-memory sorting for maximum resilience
              final sortedDocs = docs.toList();
              sortedDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = (aData['createdAt'] ?? aData['created_at']) as Timestamp?;
                final bTime = (bData['createdAt'] ?? bData['created_at']) as Timestamp?;
                return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
              });

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = sortedDocs[index].data() as Map<String, dynamic>;
                    return _buildSystemAlert(context, data, index);
                  },
                  childCount: sortedDocs.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildRiskAlert(BuildContext context, Map<String, dynamic> data, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CRITICAL ACADEMIC RISK', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 10)),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(data['student_id']).get(),
                    builder: (context, snap) {
                      final name = (snap.data?.data() as Map?)?['name'] ?? 'Loading Student...';
                      return Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15));
                    }
                  ),
                  Text(data['risk_reason'] ?? 'Declining performance pattern detected.', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {}, 
              child: const Text('Review', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
  }

  Widget _buildSystemAlert(BuildContext context, Map<String, dynamic> data, int index) {
    final isCritical = data['priority'] == 'High' || data['priority'] == 'Critical';
    final DateTime? date = ((data['createdAt'] ?? data['created_at']) as Timestamp?)?.toDate();
    final dateStr = date != null ? DateFormat('d MMM, HH:mm').format(date) : 'Recently';
    
    // Support for both 'content' and 'message' fields
    final content = data['content'] ?? data['message'] ?? 'No content';
    final title = data['title'] ?? 'Teacher Alert';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isCritical ? Colors.red : Colors.blue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCritical ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                color: isCritical ? Colors.red : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (data['category'] ?? 'General').toUpperCase(),
                        style: TextStyle(color: isCritical ? Colors.red : Colors.blue, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
                      ),
                      Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(content, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textSecondary)),
                  if (data['teacher_name'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('From: ${data['teacher_name']}', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
  }
}
