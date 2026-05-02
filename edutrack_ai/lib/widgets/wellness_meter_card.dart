import 'package:flutter/material.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/services/ai_service.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class WellnessMeterCard extends StatefulWidget {
  final String studentName;
  final List<double> recentScores;
  final double accuracy;
  final double completionRate;
  final int usageFreq;
  final double studyHours;
  final String mood;
  final int helpRequests;

  const WellnessMeterCard({
    super.key,
    required this.studentName,
    this.recentScores = const [60, 65, 70],
    this.accuracy = 85.0,
    this.completionRate = 90.0,
    this.usageFreq = 7,
    this.studyHours = 4.0,
    this.mood = 'Good',
    this.helpRequests = 2,
  });

  @override
  State<WellnessMeterCard> createState() => _WellnessMeterCardState();
}

class _WellnessMeterCardState extends State<WellnessMeterCard> {
  bool _loading = false;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AIService().analyzePressure({
        'student_name': widget.studentName,
        'quiz_scores': widget.recentScores,
        'accuracy': widget.accuracy,
        'completion_rate': widget.completionRate,
        'app_usage_freq': widget.usageFreq,
        'study_hours_per_day': widget.studyHours,
        'daily_mood': widget.mood,
        'help_requests_count': widget.helpRequests,
      });

      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Wellness engine unavailable';
          _loading = false;
        });
      }
    }
  }

  Color _getLevelColor(String? level) {
    switch (level) {
      case 'High': return Colors.redAccent;
      case 'Medium': return Colors.orangeAccent;
      case 'Low': return Colors.greenAccent;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PremiumCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Analyzing Academic Wellness...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return PremiumCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
      );
    }

    final level = _data?['pressure_level'] ?? 'Low';
    final score = (_data?['pressure_score'] ?? 0).toDouble();
    final color = _getLevelColor(level);
    final reasons = List<String>.from(_data?['reasons'] ?? []);

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Wellness Meter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'AI LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        level.toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                    const Text(
                      'PRESSURE LEVEL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textHint,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0.05, 1.0),
                        minHeight: 12,
                        backgroundColor: AppTheme.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('STABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textHint)),
                        Text('${score.toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                        const Text('CRITICAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: reasons.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildSupportBox(
            'STUDENT SUPPORT',
            _data?['student_support_msg'] ?? 'You are doing great, keep it up!',
            Icons.lightbulb_outline_rounded,
            AppTheme.secondary,
          ),
          if (level != 'Low') ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                // Navigate to AI Chat or open a motivation dialog
                // For now, we simulate the motivation chat activation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI Buddy activated! "Hey! Let\'s take a 5-minute break together. You\'ve been working hard."'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Talk to AI Buddy',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSupportBox(
            'ADAPTIVE RECOMMENDATION',
            _data?['study_recommendation'] ?? 'Focus on small daily goals.',
            Icons.auto_awesome_outlined,
            AppTheme.primary,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Update Wellness Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportBox(String title, String content, IconData icon, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
