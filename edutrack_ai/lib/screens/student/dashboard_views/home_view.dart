import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/gamification_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/widgets/brain_dna_visualizer.dart';
import 'package:edutrack_ai/models/knowledge_node.dart';
import 'package:edutrack_ai/services/brain_dna_service.dart';
import 'package:edutrack_ai/screens/assignments/student_assignments_screen.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/progress_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final gamify = context.watch<GamificationProvider>();
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, user, gamify),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _buildOverview(gamify),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Learning DNA Visualizer', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressView()));
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: StreamBuilder<List<KnowledgeNode>>(
                      stream: BrainDNAService.instance.getBrainDNA(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final nodes = snapshot.data ?? [];
                        if (nodes.isEmpty) {
                          return _buildEmptyDNA();
                        }
                        return Center(
                          child: BrainDNAVisualizer(nodes: nodes, size: 250),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Your Mastery', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressView()));
                  }),
                  const SizedBox(height: 16),
                  _buildLearningDNA(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Pending Missions', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen()));
                  }),
                  const SizedBox(height: 16),
                  _buildContinueLearning(context, user?.classId ?? ''),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDNA() {
    return PremiumCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 48, color: AppTheme.primary.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text(
              'Start your first mission to build your Learning DNA!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, GamificationProvider gamify) {
    final progress = gamify.progressToNextLevel;
    
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        decoration: const BoxDecoration(
          color: AppTheme.primaryDark,
          gradient: AppTheme.studentGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Home Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.name.split(' ').first ?? 'Student'}!',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to continue your learning mission?',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person_outline, color: AppTheme.primary)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // XP Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level ${gamify.user?.level ?? 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('${gamify.user?.xp ?? 0} / ${gamify.xpToNextLevel} XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildOverview(GamificationProvider gamify) {
    final userId = gamify.user?.uid ?? '';
    final classId = gamify.user?.classId ?? '';

    return Row(
      children: [
        Consumer<AnalyticsProvider>(
          builder: (context, analytics, _) {
            final avg = (analytics.studentAnalytics?['avg_score'] as num?)?.toDouble();
            return _StatCard(label: 'Avg. Score', value: avg == null ? 'N/A' : '${avg.toStringAsFixed(0)}%', icon: Icons.track_changes_rounded, color: const Color(0xFF6366F1));
          },
        ),
        const SizedBox(width: 12),
        // 2. Tasks from assignments
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('assignments').where('class_id', isEqualTo: classId).snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return _StatCard(label: 'Tasks', value: '$count', icon: Icons.calendar_today_rounded, color: const Color(0xFF10B981));
          },
        ),
        const SizedBox(width: 12),
        // 3. Day Streak from gamification (real)
        _StatCard(label: 'Day Streak', value: '${gamify.user?.streak ?? 0}', icon: Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        TextButton(
          onPressed: onTap,
          child: const Text('View Report', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildContinueLearning(BuildContext context, String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('class_id', isEqualTo: classId)
          .limit(2)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("You're all caught up! 🎉", style: TextStyle(color: Color(0xFF64748B)));

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? 'Assignment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Text(data['subject'] ?? 'Subject', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildLearningDNA(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final data = analytics.studentAnalytics;
    final avg = (data?['avg_score'] as num?)?.toDouble() ?? 0.0;
    final completion = (data?['course_completion'] as num?)?.toDouble() ?? 0.0;
    
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Performance Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Dynamic report based on your latest activities.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.auto_graph_rounded, color: AppTheme.accent),
            ],
          ),
          const SizedBox(height: 24),
          // Overall Mastery (Quiz Scores)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quiz Average', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${avg.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: avg / 100,
              minHeight: 10,
              backgroundColor: AppTheme.bgLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          // Course Completion (Assignments)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Assignments Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${completion.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 10,
              backgroundColor: AppTheme.bgLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.1))),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B))),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
