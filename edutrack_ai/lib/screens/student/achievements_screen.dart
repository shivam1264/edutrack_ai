import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final xp = user?.xp ?? 0;
    final level = (xp / 100).floor() + 1;

    final allBadges = _getAllBadges();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFD97706),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -20, right: -20,
                      child: Icon(Icons.workspace_premium_rounded, color: Colors.white.withOpacity(0.1), size: 200)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Achievements', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Level $level · $xp XP', style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final badge = allBadges[i];
                  final unlocked = _isBadgeUnlocked(badge, xp, user);
                  return _BadgeCard(badge: badge, unlocked: unlocked)
                      .animate().fadeIn(delay: (i * 80).ms).scale(begin: const Offset(0.9, 0.9));
                },
                childCount: allBadges.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isBadgeUnlocked(Map<String, dynamic> badge, int xp, user) {
    final requirement = badge['requirement'] as String;
    final threshold = badge['threshold'] as int;
    switch (requirement) {
      case 'xp':
        return xp >= threshold;
      case 'level':
        return (xp / 100).floor() + 1 >= threshold;
      default:
        return false;
    }
  }

  List<Map<String, dynamic>> _getAllBadges() {
    return [
      {'emoji': '🌟', 'title': 'First Star', 'desc': 'Earn your first 10 XP', 'requirement': 'xp', 'threshold': 10},
      {'emoji': '📚', 'title': 'Scholar', 'desc': 'Reach 100 XP', 'requirement': 'xp', 'threshold': 100},
      {'emoji': '🎯', 'title': 'Sharpshooter', 'desc': 'Reach Level 3', 'requirement': 'level', 'threshold': 3},
      {'emoji': '🚀', 'title': 'Rising Star', 'desc': 'Reach 250 XP', 'requirement': 'xp', 'threshold': 250},
      {'emoji': '🧠', 'title': 'Mastermind', 'desc': 'Reach Level 5', 'requirement': 'level', 'threshold': 5},
      {'emoji': '💎', 'title': 'Diamond Mind', 'desc': 'Reach 500 XP', 'requirement': 'xp', 'threshold': 500},
      {'emoji': '🏆', 'title': 'Champion', 'desc': 'Reach Level 10', 'requirement': 'level', 'threshold': 10},
      {'emoji': '👑', 'title': 'Legend', 'desc': 'Reach 1000 XP', 'requirement': 'xp', 'threshold': 1000},
    ];
  }
}

class _BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;
  final bool unlocked;

  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: unlocked ? const Color(0xFFD97706).withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: unlocked ? Border.all(color: const Color(0xFFD97706), width: 2) : null,
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter: unlocked ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]),
                  child: Text(badge['emoji'] as String, style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge['title'] as String, style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16,
                      color: unlocked ? AppTheme.textPrimary : Colors.grey)),
                  Text(badge['desc'] as String, style: TextStyle(
                      fontSize: 12, color: unlocked ? AppTheme.textSecondary : Colors.grey)),
                ],
              ),
            ),
            if (unlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Unlocked!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              )
            else
              Icon(Icons.lock_rounded, color: Colors.grey.withOpacity(0.5), size: 28),
          ],
        ),
      ),
    );
  }
}
