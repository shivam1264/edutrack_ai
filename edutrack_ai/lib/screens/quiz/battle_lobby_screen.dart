import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/battle_service.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'live_battle_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BattleLobbyScreen extends StatelessWidget {
  const BattleLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // ── Premium Header ──
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(gradient: AppTheme.meshGradient),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Battle Arena', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('Real-time multiplayer duels', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateRoomDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // ── Active Rooms ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('battle_rooms')
                  .where('status', isEqualTo: 'waiting')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data?.docs ?? [];

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.military_tech_rounded, color: AppTheme.borderLight, size: 100),
                        const SizedBox(height: 16),
                        const Text('No active missions signal.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => _showCreateRoomDialog(context), child: const Text('Create the first lobby!')),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = rooms[index].data() as Map<String, dynamic>;
                    return _BattleRoomCard(data: data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) async {
    final user = context.read<AuthProvider>().user!;
    final quizzes = await QuizService().getQuizzesByClass(user.classId ?? '');

    if (quizzes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No quizzes available to start a battle!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Start Battle Mission', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 16),
            const Text('Choose a subject for the duel:', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final q = quizzes[index];
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.primary, child: Icon(Icons.bolt, color: Colors.white)),
                    title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${q.subject} • ${q.questions.length} Questions'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final roomId = await BattleService().createRoom(
                        hostId: user.uid,
                        hostName: user.name,
                        quizId: q.id,
                        quizTitle: q.title,
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LiveBattleScreen(roomId: roomId, quiz: q)));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleRoomCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BattleRoomCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['quiz_title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Host: ${data['host_name']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Fetch quiz first
              final quiz = await QuizService().getQuiz(data['quiz_id']);
              if (quiz != null) {
                await BattleService().joinRoom(data['id'], user.uid, user.name);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LiveBattleScreen(roomId: data['id'], quiz: quiz)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('JOIN DUEL'),
          ),
        ],
      ),
    );
  }
}
