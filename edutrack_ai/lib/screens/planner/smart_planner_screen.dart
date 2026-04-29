import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/study_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';
import '../../providers/analytics_provider.dart';

class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  int _selectedTabIndex = 0;
  bool _isGenerating = false;
  final List<String> _tabs = ['Today', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Study Plan'),
        actions: [
          if (_isGenerating)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
              onPressed: () => _generateAIPlan(context),
              tooltip: 'Generate AI Study Plan',
            ),
        ],
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
                  stream: FirebaseFirestore.instance
                      .collection('study_tasks')
                      .where('userId', isEqualTo: userId)
                      .snapshots()
                      .map((snap) => snap.docs
                          .map((doc) => StudyTaskModel.fromMap(doc.id, doc.data()))
                          .toList()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tasks = _filterTasks(snapshot.data ?? []);
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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showAddTaskDialog(context, userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('+ Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTopicPlanningDialog(context, userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 18),
                        SizedBox(width: 8),
                        Text('AI Topic Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
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

  List<StudyTaskModel> _filterTasks(List<StudyTaskModel> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekEnd = todayStart.add(const Duration(days: 7));
    final monthEnd = DateTime(now.year, now.month + 1, now.day);

    final filtered = tasks.where((task) {
      if (_selectedTabIndex == 0) {
        return !task.createdAt.isBefore(todayStart) && task.createdAt.isBefore(tomorrowStart);
      }
      if (_selectedTabIndex == 1) {
        return !task.createdAt.isBefore(todayStart) && task.createdAt.isBefore(weekEnd);
      }
      return !task.createdAt.isBefore(todayStart) && task.createdAt.isBefore(monthEnd);
    }).toList();

    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return filtered;
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

  Future<void> _generateAIPlan(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) return;

    setState(() => _isGenerating = true);
    
    try {
      final analytics = context.read<AnalyticsProvider>();
      final studentData = analytics.studentAnalytics;
      
      final tasks = await AIService().generateStudyPlan(userId, studentData: studentData);
      
      if (tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not generate plan. Please try again later.'))
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final task in tasks) {
        final docRef = FirebaseFirestore.instance.collection('study_tasks').doc();
        batch.set(docRef, {
          'userId': userId,
          'title': task['title'] ?? 'Study Session',
          'subject': task['subject'] ?? 'General',
          'duration_minutes': task['duration_minutes'] ?? 30,
          'is_completed': false,
          'type': task['type'] ?? 'AI Suggested',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Study Plan generated and added! 🚀'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showTopicPlanningDialog(BuildContext context, String userId) {
    final topicCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primary),
            SizedBox(width: 12),
            Text('AI Topic Strategy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a topic, and AI will create a 4-step study strategy for you.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: topicCtrl,
              decoration: InputDecoration(
                labelText: 'Topic Name',
                hintText: 'e.g. Quantum Physics, Periodic Table',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectCtrl,
              decoration: InputDecoration(
                labelText: 'Subject (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (topicCtrl.text.isEmpty) return;
              Navigator.pop(context);
              _generateTopicPlan(topicCtrl.text, subjectCtrl.text.isEmpty ? 'General' : subjectCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Generate Strategy'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTopicPlan(String topic, String subject) async {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    setState(() => _isGenerating = true);

    try {
      final tasks = await AIService().generateTopicTasks(topic: topic, subject: subject);

      if (tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate strategy. Please try again.')));
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final task in tasks) {
        final docRef = FirebaseFirestore.instance.collection('study_tasks').doc();
        batch.set(docRef, {
          'userId': userId,
          'title': task['title'] ?? 'Study Session',
          'subject': task['subject'] ?? subject,
          'duration_minutes': task['duration_minutes'] ?? 30,
          'is_completed': false,
          'type': task['type'] ?? 'AI Strategy',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Study Strategy for $topic added! 🚀')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
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
