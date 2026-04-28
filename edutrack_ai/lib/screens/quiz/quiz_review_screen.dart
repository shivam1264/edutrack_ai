import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizReviewScreen extends StatelessWidget {
  final QuizModel quiz;
  final QuizResultModel result;

  const QuizReviewScreen({super.key, required this.quiz, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Quiz Review', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          _buildScoreSummary(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quiz.questions.length,
              itemBuilder: (context, index) {
                final question = quiz.questions[index];
                final studentAnswer = result.answers[index];
                final isCorrect = question.type == QuestionType.mcq 
                    ? studentAnswer == question.correctOption
                    : false;

                return _QuestionReviewCard(
                  index: index,
                  question: question,
                  studentAnswer: studentAnswer,
                  isCorrect: isCorrect,
                ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummary() {
    final percentage = result.percentage;
    final color = percentage >= 70 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppTheme.borderLight,
                  color: color,
                  strokeWidth: 8,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Score Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(
                  '${result.score.toStringAsFixed(1)} / ${result.total.toStringAsFixed(1)} Marks',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  percentage >= 70 ? 'Excellent Performance! 🏆' : (percentage >= 50 ? 'Good Effort! 👍' : 'Keep Learning! 📚'),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final dynamic studentAnswer;
  final bool isCorrect;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.studentAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q ${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (isCorrect)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              else
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (question.type == QuestionType.mcq)
            ...question.options.asMap().entries.map((e) {
              final isSelected = studentAnswer == e.key;
              final isCorrectOption = question.correctOption == e.key;

              Color borderColor = AppTheme.borderLight;
              Color bgColor = Colors.white;
              Widget? icon;

              if (isCorrectOption) {
                borderColor = Colors.green;
                bgColor = Colors.green.withOpacity(0.05);
                icon = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16);
              } else if (isSelected && !isCorrectOption) {
                borderColor = Colors.red;
                bgColor = Colors.red.withOpacity(0.05);
                icon = const Icon(Icons.cancel_rounded, color: Colors.red, size: 16);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: (isCorrectOption || isSelected) ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + e.key) + '.',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isCorrectOption ? Colors.green : (isSelected ? Colors.red : AppTheme.textHint),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: isCorrectOption ? Colors.green : (isSelected ? Colors.red : AppTheme.textPrimary),
                          fontWeight: (isCorrectOption || isSelected) ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (icon != null) icon,
                  ],
                ),
              );
            })
          else ...[
            const Text(
              'Your Answer:',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              studentAnswer?.toString() ?? '[No Answer]',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
