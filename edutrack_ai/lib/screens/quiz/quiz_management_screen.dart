import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizManagementScreen extends StatefulWidget {
  final String classId;
  const QuizManagementScreen({super.key, required this.classId});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  final QuizService _service = QuizService();

  Future<void> _confirmDelete(QuizModel q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz Assessment?'),
        content: Text('Are you sure you want to remove "${q.title}"? All student grades for this quiz will be permanently erased.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete Permanently', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteQuiz(q.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment purged successfully.')));
      }
    }
  }

  Future<void> _editQuizConfig(QuizModel q) async {
    int duration = q.durationMins;
    DateTime end = q.endTime;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Update Quiz Protocol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: duration,
                decoration: const InputDecoration(labelText: 'Duration (mins)'),
                items: [10, 15, 20, 30, 45, 60, 90, 120].map((d) => DropdownMenuItem(value: d, child: Text('$d mins'))).toList(),
                onChanged: (v) => setLocalState(() => duration = v!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Expiry:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(DateFormat('HH:mm (dd/MM)').format(end)),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: end,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
                      if (time == null) return;
                      setLocalState(() => end = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _service.updateQuiz(q.id, {
                  'duration_mins': duration,
                  'end_time': Timestamp.fromDate(end),
                });
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
              child: const Text('Update Protocol'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Quiz Assessment Control', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: StreamBuilder<List<QuizModel>>(
        stream: _service.streamQuizzesByClass(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final q = items[index];
              return PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.bolt_rounded, color: AppTheme.accent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('${q.durationMins} mins • ${q.subject}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_suggest_rounded, color: AppTheme.accent, size: 22),
                          onPressed: () => _editQuizConfig(q),
                          tooltip: 'Edit Protocol',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
                          onPressed: () => _confirmDelete(q),
                          tooltip: 'Delete Quiz',
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_outlined, size: 60, color: AppTheme.borderLight),
          const SizedBox(height: 16),
          Text('No quizzes active in this class.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
