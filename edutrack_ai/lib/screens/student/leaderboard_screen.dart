import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Class', 'School', 'All India'];

  @override
  Widget build(BuildContext context) {
    final authUser = context.read<AuthProvider>().user;
    final classId = authUser?.classId ?? '';
    final currentUserId = authUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _selectedTabIndex == 0
            ? context.read<GamificationProvider>().streamLeaderboard(classId)
            : _selectedTabIndex == 1
                ? context.read<GamificationProvider>().streamSchoolLeaderboard(authUser?.schoolId ?? '')
                : context.read<GamificationProvider>().streamGlobalLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading leaderboard: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No leaderboard data available yet.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  const Text('Ranks will update as students earn XP!', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                ],
              ),
            );
          }

          // Assign ranks (handles ties simply by index for now)
          final top3 = users.take(3).toList();
          final rest = users.skip(3).toList();

          UserModel? first = top3.isNotEmpty ? top3[0] : null;
          UserModel? second = top3.length > 1 ? top3[1] : null;
          UserModel? third = top3.length > 2 ? top3[2] : null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildTabs(),
                const SizedBox(height: 32),
                SizedBox(
                  height: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd Place
                      if (second != null)
                        _PodiumItem(
                          rank: 2,
                          name: second.uid == currentUserId ? 'You' : second.name.split(' ').first,
                          xp: '${second.xp} XP',
                          height: 120,
                          color: Colors.blueGrey,
                        ),
                      // 1st Place
                      if (first != null)
                        _PodiumItem(
                          rank: 1,
                          name: first.uid == currentUserId ? 'You' : first.name.split(' ').first,
                          xp: '${first.xp} XP',
                          height: 160,
                          color: Colors.amber,
                        ),
                      // 3rd Place
                      if (third != null)
                        _PodiumItem(
                          rank: 3,
                          name: third.uid == currentUserId ? 'You' : third.name.split(' ').first,
                          xp: '${third.xp} XP',
                          height: 100,
                          color: Colors.deepOrangeAccent,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ...rest.asMap().entries.map((entry) {
                  final index = entry.key + 4; // Ranks start at 4 for the rest
                  final user = entry.value;
                  return _LeaderboardTile(
                    rank: index,
                    name: user.uid == currentUserId ? 'You' : user.name,
                    xp: '${user.xp} XP',
                    isCurrentUser: user.uid == currentUserId,
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: _TabItem(_tabs[index], isSelected: _selectedTabIndex == index),
            ),
          );
        }),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabItem(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final String name;
  final String xp;
  final double height;
  final Color color;

  const _PodiumItem({
    required this.rank,
    required this.name,
    required this.xp,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.2),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(xp, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final String xp;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.xp,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppTheme.primaryLight.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrentUser ? AppTheme.primary.withOpacity(0.5) : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppTheme.borderLight)),
            child: Center(child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary))),
          Text(xp, style: TextStyle(color: isCurrentUser ? AppTheme.primary : AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
