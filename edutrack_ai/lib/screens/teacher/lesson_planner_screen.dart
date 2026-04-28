import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../utils/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LessonPlannerScreen extends StatefulWidget {
  final String? classId;
  const LessonPlannerScreen({super.key, this.classId});

  @override
  State<LessonPlannerScreen> createState() => _LessonPlannerScreenState();
}

class _LessonPlannerScreenState extends State<LessonPlannerScreen> {
  final _topicCtrl = TextEditingController();
  String _selectedSubject = 'Mathematics';
  String _selectedDuration = '45 minutes';
  String _selectedGrade = '8th standard'; // Matches '8th standard' in the list
  bool _isGenerating = false;
  String? _generatedPlan;
  List<Map<String, dynamic>> _savedPlans = [];

  final List<String> _subjects = ['Mathematics', 'Science', 'Physics', 'Chemistry',
    'Biology', 'English', 'Hindi', 'History', 'Geography', 'Computer Science'];
  final List<String> _durations = ['30 minutes', '45 minutes', '60 minutes', '90 minutes'];
  final List<String> _grades = ['1st standard', '2nd standard', '3rd standard', '4th standard', '5th standard', '6th standard', '7th standard', '8th standard', '9th standard', '10th standard', '11th standard', '12th standard'];

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
    
    // Attempt to resolve grade from classId if available
    if (widget.classId != null) {
      FirebaseFirestore.instance.collection('classes').doc(widget.classId).get().then((doc) {
        if (doc.exists && mounted) {
          try {
            final className = doc.data()?['name']?.toString().toLowerCase() ?? '';
            for (var g in _grades) {
              if (className.contains(g.split(' ')[0].toLowerCase())) {
                setState(() => _selectedGrade = g);
                break;
              }
            }
          } catch (e) {
            debugPrint('Grade resolution error: $e');
          }
        }
      });
    }
  }

  Future<void> _loadSavedPlans() async {
    try {
      final user = context.read<AuthProvider>().user;
      final snap = await FirebaseFirestore.instance
          .collection('lesson_plans')
          .where('teacherId', isEqualTo: user?.uid)
          .get();
      
      final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      
      // Sort in-memory to bypass index requirement
      list.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
      });

      setState(() {
        _savedPlans = list.take(10).toList();
      });
    } catch (e) {
      debugPrint('Load plans error: $e');
    }
  }

  Future<void> _generatePlan() async {
    if (_topicCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a topic first!', isError: true);
      return;
    }
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
      ).timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _generatedPlan = data['plan'] ?? 'No plan received.');
        _saveToArchive(data['plan'] ?? '');
      } else {
        _showSnack('AI Server is warming up. Using offline template.', isError: false);
        setState(() => _generatedPlan = _offlinePlan());
      }
    } catch (e) {
      _showSnack('Connectivity issue. Using professional template.', isError: false);
      setState(() => _generatedPlan = _offlinePlan());
    }
    setState(() => _isGenerating = false);
  }

  Future<void> _saveToArchive(String plan) async {
    try {
      final user = context.read<AuthProvider>().user;
      await FirebaseFirestore.instance.collection('lesson_plans').add({
        'teacherId': user?.uid,
        'subject': _selectedSubject,
        'topic': _topicCtrl.text.trim(),
        'grade': _selectedGrade,
        'duration': _selectedDuration,
        'plan': plan,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _loadSavedPlans();
    } catch (e) {
      debugPrint('Archive Error: $e');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _offlinePlan() {
    return '''📚 LESSON PLAN
Subject: $_selectedSubject | Topic: ${_topicCtrl.text.trim()}
Grade: $_selectedGrade | Duration: $_selectedDuration

🎯 LEARNING OBJECTIVES
1. Understand the core principles of today's topic
2. Apply concepts through practical examples
3. Evaluate understanding with peer discussion

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
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Lesson Planner', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      StreamBuilder<DocumentSnapshot>(
                        stream: widget.classId != null 
                          ? FirebaseFirestore.instance.collection('classes').doc(widget.classId).snapshots()
                          : null,
                        builder: (context, snap) {
                          final data = snap.data?.data() as Map<String, dynamic>?;
                          final name = data?['name'] ?? 'Professional Lesson Planner';
                          return Text(
                            widget.classId != null ? 'Active Class: $name' : 'Generate professional lesson plans', 
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                              isExpanded: true,
                              value: _subjects.contains(_selectedSubject) ? _selectedSubject : _subjects[0],
                              decoration: InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _subjects.map((s) => DropdownMenuItem(
                                value: s, 
                                child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedSubject = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _grades.contains(_selectedGrade) ? _selectedGrade : _grades[7],
                              decoration: InputDecoration(
                                labelText: 'Grade',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _grades.map((g) => DropdownMenuItem(
                                value: g, 
                                child: Text(g, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)
                              )).toList(),
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
                        value: _durations.contains(_selectedDuration) ? _selectedDuration : _durations[1],
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
                          label: Text(_isGenerating ? 'AI is Thinking...' : 'Generate Lesson Plan'),
                          onPressed: _isGenerating ? null : _generatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      if (_isGenerating)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'AI Server is waking up... Please wait 30-40s',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
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
                            const Expanded(
                              child: Text(
                                'Generated Plan', 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save_rounded, color: Color(0xFF059669)),
                              onPressed: _savePlan,
                              tooltip: 'Save Plan',
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        MarkdownBody(
                          data: _generatedPlan!,
                          styleSheet: MarkdownStyleSheet(
                            h1: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textPrimary),
                            h2: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimary),
                            p: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textSecondary),
                            listBullet: const TextStyle(color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
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
                  child: MarkdownBody(data: plan['plan'] ?? ''),
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
