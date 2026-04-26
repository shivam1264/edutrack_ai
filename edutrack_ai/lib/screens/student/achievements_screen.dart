import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/app_theme.dart';

// All available badges in the system
const _allBadges = [
  _BadgeDef('quiz_master', 'Quiz Master', Icons.stars, Colors.purple),
  _BadgeDef('streak_star', 'Streak Star', Icons.local_fire_department, Colors.orange),
  _BadgeDef('time_warrior', 'Time Warrior', Icons.shield, Colors.green),
  _BadgeDef('perfect_score', 'Perfect Score', Icons.workspace_premium, Colors.amber),
  _BadgeDef('consistent_learner', 'Consistent Learner', Icons.military_tech, Colors.blue),
  _BadgeDef('help_helper', 'Help Helper', Icons.health_and_safety, Colors.teal),
  _BadgeDef('early_bird', 'Early Bird', Icons.wb_sunny, Colors.red),
  _BadgeDef('science_pro', 'Science Pro', Icons.science, Colors.indigo),
  _BadgeDef('math_wizard', 'Math Wizard', Icons.calculate, Colors.deepPurple),
];

class _BadgeDef {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  const _BadgeDef(this.id, this.name, this.icon, this.color);
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final user = context.watch<AuthProvider>().user;
    final earnedBadges = user?.badges ?? [];
    final earnedCount = earnedBadges.length;
    final totalCount = _allBadges.length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Badges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Badges $earnedCount/$totalCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Text('All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? earnedCount / totalCount : 0.0,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$earnedCount of $totalCount badges earned',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            // Earned section
            if (earnedCount > 0) ...[
              const Text(
                'Earned',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 24,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
                children: _allBadges
                    .where((b) => earnedBadges.contains(b.id))
                    .map((b) => _BadgeItem(name: b.name, isLocked: false, icon: b.icon, color: b.color))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],
            // Locked section
            const Text(
              'Locked',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
              children: _allBadges
                  .where((b) => !earnedBadges.contains(b.id))
                  .map((b) => _BadgeItem(name: b.name, isLocked: true, icon: b.icon, color: Colors.grey))
                  .toList(),
            ),
            const SizedBox(height: 32),
            _buildBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep learning!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                SizedBox(height: 4),
                Text('Complete missions to earn more badges.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 16),
          Icon(Icons.stars, color: Colors.orange, size: 48),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String name;
  final bool isLocked;
  final IconData icon;
  final Color color;

  const _BadgeItem({
    required this.name,
    required this.isLocked,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLocked ? const Color(0xFFF0F0F0) : color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isLocked ? Colors.grey.shade400 : color,
                size: 36,
              ),
            ),
            if (isLocked)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.lock, size: 14, color: Colors.grey),
                ),
              )
            else
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isLocked ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          isLocked ? 'Locked' : 'Earned ✓',
          style: TextStyle(
            color: isLocked ? AppTheme.textHint : Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
