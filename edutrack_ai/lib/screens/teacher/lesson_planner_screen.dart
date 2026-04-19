import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../utils/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

class LessonPlannerScreen extends StatefulWidget {
  const LessonPlannerScreen({super.key});

  @override
  State<LessonPlannerScreen> createState() => _LessonPlannerScreenState();
}

class _LessonPlannerScreenState extends State<LessonPlannerScreen> {
  final _topicCtrl = TextEditingController();
  String _selectedSubject = 'Mathematics';
  String _selectedDuration = '45 minutes';
  String _selectedGrade = 'Grade 8';
  bool _isGenerating = false;
  String? _generatedPlan;
  List<Map<String, dynamic>> _savedPlans = [];

  final List<String> _subjects = ['Mathematics', 'Science', 'Physics', 'Chemistry',
    'Biology', 'English', 'Hindi', 'History', 'Geography', 'Computer Science'];
  final List<String> _durations = ['30 minutes', '45 minutes', '60 minutes', '90 minutes'];
  final List<String> _grades = ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
  }

  Future<void> _loadSavedPlans() async {
    final user = context.read<AuthProvider>().user;
    final snap = await FirebaseFirestore.instance
        .collection('lesson_plans')
        .where('teacherId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    setState(() {
      _savedPlans = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Future<void> _generatePlan() async {
    if (_topicCtrl.text.trim().isEmpty) return;
    setState(() { _isGenerating = true; _generatedPlan = null; });

    try {
      final res = await http.post(
        Uri.parse(Config.endpoint('/generate-lesson-plan')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': _selectedSubject,
          'topic': _topicCtrl.text.trim(),
          'duration': _selectedDuration,
          'grade': _selectedGrade,
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _generatedPlan = data['plan'] ?? 'Plan generated!');
      } else {
        // Fallback offline plan
        setState(() => _generatedPlan = _offlinePlan());
      }
    } catch (e) {
      setState(() => _generatedPlan = _offlinePlan());
    }

    setState(() => _isGenerating = false);
  }

  String _offlinePlan() {
    return '''📚 LESSON PLAN
Subject: $_selectedSubject | Topic: ${_topicCtrl.text.trim()}
Grade: $_selectedGrade | Duration: $_selectedDuration

🎯 LEARNING OBJECTIVES
1. Students will understand the core concept of ${_topicCtrl.text.trim()}
2. Students will be able to apply the concept in practical scenarios
3. Students will demonstrate understanding through examples

⏱️ LESSON STRUCTURE
• Introduction (5 min): Review previous lesson, introduce today's topic
• Concept Explanation (15 min): Detailed explanation with examples
• Guided Practice (10 min): Solve problems together on board
• Independent Practice (10 min): Student worksheet/activity
• Summary & Assessment (5 min): Q&A and key takeaways

📋 RESOURCES NEEDED
• Whiteboard/Smartboard
• Textbook Chapter (relevant)
• Practice worksheet
• Visual aids / diagrams

✅ ASSESSMENT
• Quick oral quiz at end
• Homework assignment for reinforcement
• Next class review of today's content''';
  }

  Future<void> _savePlan() async {
    if (_generatedPlan == null) return;
    final user = context.read<AuthProvider>().user;
    await FirebaseFirestore.instance.collection('lesson_plans').add({
      'teacherId': user?.uid,
      'teacherName': user?.name,
      'subject': _selectedSubject,
      'topic': _topicCtrl.text.trim(),
      'grade': _selectedGrade,
      'duration': _selectedDuration,
      'plan': _generatedPlan,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _loadSavedPlans();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Plan saved!'), backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF1D4ED8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AI Lesson Planner', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('Generate professional lesson plans in seconds', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                PremiumCard(
                  opacity: 1,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSubject,
                              decoration: InputDecoration(labelText: 'Subject',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedSubject = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGrade,
                              decoration: InputDecoration(labelText: 'Grade',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                              items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => setState(() => _selectedGrade = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _topicCtrl,
                        decoration: InputDecoration(
                          labelText: 'Topic / Chapter',
                          hintText: 'e.g., Quadratic Equations',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.book_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDuration,
                        decoration: InputDecoration(labelText: 'Class Duration',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.timer_rounded)),
                        items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _selectedDuration = v!),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isGenerating
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(_isGenerating ? 'Generating with AI...' : 'Generate Lesson Plan'),
                          onPressed: _isGenerating ? null : _generatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),
                if (_generatedPlan != null) ...[
                  const SizedBox(height: 20),
                  PremiumCard(
                    opacity: 1,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 8),
                            const Text('Generated Plan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.save_rounded, color: Color(0xFF059669)),
                              onPressed: _savePlan,
                              tooltip: 'Save Plan',
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(_generatedPlan!, style: const TextStyle(height: 1.6, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.3),
                ],
                if (_savedPlans.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('📂 Saved Plans', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ..._savedPlans.asMap().entries.map((e) {
                    final plan = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PremiumCard(
                        opacity: 1,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF1D4ED8).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.description_rounded, color: Color(0xFF1D4ED8)),
                          ),
                          title: Text(plan['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${plan['subject']} · ${plan['grade']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new_rounded),
                            onPressed: () => _showPlanDialog(plan),
                          ),
                        ),
                      ).animate().fadeIn(delay: (e.key * 60).ms),
                    );
                  }),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              Text('${plan['subject']} · ${plan['grade']}', style: const TextStyle(color: AppTheme.textSecondary)),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(plan['plan'] ?? '', style: const TextStyle(height: 1.6)),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }
}
