import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../services/battle_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class LiveBattleScreen extends StatefulWidget {
  final String roomId;
  final QuizModel quiz;

  const LiveBattleScreen({super.key, required this.roomId, required this.quiz});

  @override
  State<LiveBattleScreen> createState() => _LiveBattleScreenState();
}

class _LiveBattleScreenState extends State<LiveBattleScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _finished = false;
  final BattleService _battleService = BattleService();

  void _answerQuestion(int optionIndex) {
    if (_finished) return;

    final q = widget.quiz.questions[_currentIndex];
    if (optionIndex == q.correctOption) {
      _score += q.marks.toInt();
    }

    _battleService.updateScore(widget.roomId, context.read<AuthProvider>().user!.uid, _score);

    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark space theme
      body: SafeArea(
        child: StreamBuilder(
          stream: _battleService.streamRoom(widget.roomId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final players = data['players'] as List;
            final otherPlayer = players.firstWhere((p) => p['id'] != user.uid, orElse: () => null);
            final myData = players.firstWhere((p) => p['id'] == user.uid);

            return Column(
              children: [
                // ── Scoreboard ──
                _buildScoreboard(myData, otherPlayer),
                
                const SizedBox(height: 20),

                // ── Quiz Area ──
                if (!_finished)
                  Expanded(child: _buildQuizView())
                else
                  Expanded(child: _buildWaitingOrResult(data, myData, otherPlayer)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreboard(dynamic me, dynamic other) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerScore(me['name'], me['score'], AppTheme.primary, true),
          const Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 24)),
          _buildPlayerScore(other?['name'] ?? 'Waiting...', other?['score'] ?? 0, AppTheme.accent, false),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, Color color, bool isMe) {
    return Column(
      children: [
        Text(name, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('$score', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900)),
        if (isMe) Container(height: 4, width: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildQuizView() {
    final q = widget.quiz.questions[_currentIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUESTION ${_currentIndex + 1}/${widget.quiz.questions.length}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 12),
          Text(q.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 40),
          ...q.options.asMap().entries.map((e) => _buildOption(e.key, e.value)),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildOption(int index, String text) {
    return GestureDetector(
      onTap: () => _answerQuestion(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(String.fromCharCode(65 + index), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingOrResult(Map<String, dynamic> room, dynamic me, dynamic other) {
    if (other != null && other['score'] == null) {
       // logic for waiting for other player to finish could go here
    }

    // For simplicity, if I finished, show results
    final myScore = me['score'] as int;
    final otherScore = other?['score'] as int ?? 0;
    final won = myScore > otherScore;
    final draw = myScore == otherScore;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(won ? Icons.emoji_events_rounded : (draw ? Icons.handshake_rounded : Icons.sentiment_very_dissatisfied), 
               color: won ? Colors.amber : (draw ? Colors.blue : Colors.red), size: 100),
          const SizedBox(height: 24),
          Text(won ? 'VICTORY!' : (draw ? 'STALEMATE' : 'DEFEATED'), 
               style: TextStyle(color: won ? Colors.amber : (draw ? Colors.blue : Colors.red), fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('You earned ${won ? 500 : 50} XP', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              if (won) context.read<GamificationProvider>().addXp(context.read<AuthProvider>().user!.uid, 500);
              else context.read<GamificationProvider>().addXp(context.read<AuthProvider>().user!.uid, 50);
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('RETURN TO BASE'),
          ),
        ],
      ).animate().scale(),
    );
  }
}
