import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final classId = user?.classId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B35),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: Icon(Icons.emoji_events_rounded,
                          color: Colors.white.withOpacity(0.1), size: 180),
                    ),
                    const Align(
                      alignment: Alignment(0, 0.3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 44),
                          SizedBox(height: 8),
                          Text('Leaderboard', style: TextStyle(
                            color: Colors.white, fontSize: 28,
                            fontWeight: FontWeight.w900, letterSpacing: 1,
                          )),
                          Text('Top Performers', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: const [
                Tab(text: '🏆 XP Rankings'),
                Tab(text: '⭐ Quiz Stars'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildXPLeaderboard(classId),
                _buildQuizLeaderboard(classId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPLeaderboard(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('classId', isEqualTo: classId)
          .where('role', isEqualTo: 'student')
          .orderBy('xp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No classmates yet!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _LeaderCard(rank: i + 1, name: d['name'] ?? 'Student',
                value: '${d['xp'] ?? 0} XP', subtitle: 'Level ${((d['xp'] ?? 0) / 100).floor() + 1}',
                isTop3: i < 3).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.3);
          },
        );
      },
    );
  }

  Widget _buildQuizLeaderboard(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_results')
          .where('classId', isEqualTo: classId)
          .orderBy('score', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text('Take quizzes to appear here!', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _LeaderCard(rank: i + 1, name: d['studentName'] ?? 'Student',
                value: '${d['score']}%', subtitle: d['quizTitle'] ?? 'Quiz',
                isTop3: i < 3).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.3);
          },
        );
      },
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final int rank;
  final String name;
  final String value;
  final String subtitle;
  final bool isTop3;

  const _LeaderCard({
    required this.rank,
    required this.name,
    required this.value,
    required this.subtitle,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isTop3 ? colors[rank - 1].withOpacity(0.15) : AppTheme.bgLight,
                shape: BoxShape.circle,
                border: isTop3 ? Border.all(color: colors[rank - 1], width: 2) : null,
              ),
              child: Center(
                child: isTop3
                    ? Text(medals[rank - 1], style: const TextStyle(fontSize: 20))
                    : Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isTop3
                    ? LinearGradient(colors: [colors[rank - 1], colors[rank - 1].withOpacity(0.7)])
                    : LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
