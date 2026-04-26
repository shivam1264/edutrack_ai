import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/study_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/mock_data_service.dart';
import '../../utils/app_theme.dart';

class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Today', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Study Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildTabs(),
              ),
              Expanded(
                child: StreamBuilder<List<StudyTaskModel>>(
                  stream: MockDataService.instance.streamStudyTasks(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tasks = snapshot.data ?? [];
                    final completedCount = tasks.where((t) => t.isCompleted).length;
                    final totalCount = tasks.length;
                    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Today\'s Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                              Text('$completedCount/$totalCount Completed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Stack(
                            children: [
                              Container(height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (tasks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No tasks planned.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                            )
                          else
                            ...tasks.map((task) {
                              return GestureDetector(
                                onTap: () => _toggleTask(task),
                                child: _TaskItem(
                                  task: '${task.subject} - ${task.title}',
                                  time: '${task.durationMinutes} min',
                                  isCompleted: task.isCompleted,
                                ),
                              );
                            }),
                          const SizedBox(height: 100),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () => _showAddTaskDialog(context, userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('+ Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTask(StudyTaskModel task) async {
    await FirebaseFirestore.instance
        .collection('study_tasks')
        .doc(task.id)
        .update({'is_completed': !task.isCompleted});
  }

  void _showAddTaskDialog(BuildContext context, String userId) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task Title')),
            TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
            TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Duration (minutes)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || subjectCtrl.text.isEmpty) return;
              
              await FirebaseFirestore.instance.collection('study_tasks').add({
                'userId': userId,
                'title': titleCtrl.text,
                'subject': subjectCtrl.text,
                'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
                'is_completed': false,
                'type': 'Review',
                'created_at': FieldValue.serverTimestamp(),
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task added to your real study plan! ✅')));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
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
        color: isSelected ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String task;
  final String time;
  final bool isCompleted;

  const _TaskItem({required this.task, required this.time, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppTheme.primary : AppTheme.borderStrong,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(time, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
        ],
      ),
    );
  }
}
