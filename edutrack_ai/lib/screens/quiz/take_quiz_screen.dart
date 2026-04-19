import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../providers/gamification_provider.dart';

class TakeQuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const TakeQuizScreen({super.key, required this.quiz});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  int _currentIndex = 0;
  final List<dynamic> _answers = [];
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _submitted = false;
  QuizResultModel? _result;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.quiz.durationMins * 60;
    _answers.addAll(
        List.filled(widget.quiz.questions.length, null));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitQuiz();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerDisplay {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds > 300) return AppTheme.secondary;
    if (_remainingSeconds > 60) return AppTheme.accent;
    return AppTheme.danger;
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting || _submitted) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      _result = await QuizService().submitQuiz(
        quiz: widget.quiz,
        studentId: uid,
        answers: _answers,
      );
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });

      // Award XP based on performance
      if (_result != null && mounted) {
        final xpEarned = 20 + ((_result!.percentage / 100) * 80).round();
        context.read<GamificationProvider>().addXp(uid, xpEarned);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error submitting: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted && _result != null) {
      return _buildResultScreen();
    }

    final question = widget.quiz.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.quiz.questions.length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Timer
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, color: _timerColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  _timerDisplay,
                  style: TextStyle(
                    color: _timerColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question counter
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Q ${_currentIndex + 1} of ${widget.quiz.questions.length}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${question.marks.toStringAsFixed(0)} mark${question.marks > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Question text
                  Text(
                    question.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options / Input
                  if (question.type == QuestionType.mcq)
                    ...question.options.asMap().entries.map((e) {
                      final isSelected = _answers[_currentIndex] == e.key;
                      return _MCQOption(
                        text: e.value,
                        index: e.key,
                        isSelected: isSelected,
                        onTap: () {
                          setState(
                              () => _answers[_currentIndex] = e.key);
                        },
                      );
                    })
                  else
                    TextFormField(
                      maxLines: 5,
                      initialValue: _answers[_currentIndex] as String?,
                      decoration: const InputDecoration(
                        hintText: 'Write your answer here...',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (val) => _answers[_currentIndex] = val,
                    ),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentIndex--),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_currentIndex <
                                widget.quiz.questions.length - 1) {
                              setState(() => _currentIndex++);
                            } else {
                              _showSubmitConfirmation();
                            }
                          },
                    icon: _currentIndex <
                            widget.quiz.questions.length - 1
                        ? const Icon(Icons.arrow_forward_rounded)
                        : const Icon(Icons.check_rounded),
                    label: Text(_currentIndex <
                            widget.quiz.questions.length - 1
                        ? 'Next'
                        : 'Submit Quiz'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = _result!.percentage;
    final color = percentage >= 70
        ? AppTheme.secondary
        : percentage >= 50
            ? AppTheme.accent
            : AppTheme.danger;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                percentage >= 60
                    ? Icons.emoji_events_rounded
                    : Icons.sentiment_dissatisfied_rounded,
                size: 80,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                percentage >= 70
                    ? '🎉 Excellent!'
                    : percentage >= 50
                        ? '👍 Good effort!'
                        : '📚 Keep practicing!',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${_result!.score.toStringAsFixed(1)} / ${_result!.total.toStringAsFixed(1)} marks',
                style: TextStyle(
                  fontSize: 18,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitConfirmation() {
    final unanswered = _answers.where((a) => a == null).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Quiz?'),
        content: Text(
          unanswered > 0
              ? '$unanswered question${unanswered > 1 ? 's' : ''} unanswered. Are you sure you want to submit?'
              : 'All questions answered. Ready to submit?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitQuiz();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _MCQOption extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _MCQOption({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _labels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
