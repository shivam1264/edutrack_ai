import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';
import '../../services/ai_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final String classId;

  const CreateQuizScreen({super.key, required this.classId});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String _subject = 'Mathematics';
  int _durationMins = 30;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  final List<_QuestionDraft> _questions = [];
  bool _isSaving = false;

  final List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _initSubjects();
  }

  void _initSubjects() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _subjects.addAll(user.subjects ?? []);
      if (_subjects.isNotEmpty) {
        _subject = _subjects.first;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addMCQQuestion() {
    setState(() {
      _questions.add(_QuestionDraft(type: QuestionType.mcq));
    });
  }

  void _addShortQuestion() {
    setState(() {
      _questions.add(_QuestionDraft(type: QuestionType.shortAnswer));
    });
  }

  Future<void> _aiGenerateQuestions() async {
    final topicCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '5');
    String difficulty = 'Medium';
    String type = 'MCQ';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('AI Magic Generator', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Generate high-quality questions using EduTrack AI.', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: topicCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    hintText: 'e.g. Thermodynamics, Algebra',
                    prefixIcon: Icon(Icons.topic_rounded, color: AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: difficulty,
                        decoration: const InputDecoration(labelText: 'Difficulty'),
                        items: ['Easy', 'Medium', 'Hard'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setLocalState(() => difficulty = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: countCtrl, 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(labelText: 'Count', prefixIcon: Icon(Icons.numbers_rounded)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Question Type', prefixIcon: Icon(Icons.list_alt_rounded)),
                  items: ['MCQ', 'True/False', 'Short Answer'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setLocalState(() => type = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), 
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Generate ✨', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result != true || topicCtrl.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      // Use direct AIService for reliability
      final generated = await AIService().generateQuiz(
        topic: topicCtrl.text.trim(),
        subject: _subject,
        count: int.tryParse(countCtrl.text) ?? 5,
        difficulty: difficulty,
        type: type,
      );

      setState(() {
        for (var q in generated) {
          final qType = (q['type'] == 'short') ? QuestionType.shortAnswer : QuestionType.mcq;
          final draft = _QuestionDraft(type: qType);
          draft.text = q['text'] ?? '';
          if (qType == QuestionType.mcq) {
            final optionsList = q['options'] as List?;
            if (optionsList != null) {
              for (int i = 0; i < optionsList.length; i++) {
                if (i < 4) draft.options[i] = optionsList[i].toString();
              }
            }
            draft.correctOption = (q['correctOption'] as num?)?.toInt() ?? 0;
          }
          draft.marks = (q['marks'] as num? ?? 1.0).toDouble();
          _questions.add(draft);
        }
      });
      _showSnack('AI successfully generated ${generated.length} questions! ✨');
    } catch (e) {
      _showSnack('AI Generation failed: $e', isError: true);
    }
    setState(() => _isSaving = false);
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      _showSnack('Add at least one question!', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      final questions = _questions.map((q) => q.toQuizQuestion()).toList();

      await QuizService().createQuiz(
        classId: widget.classId,
        teacherId: uid,
        title: _titleCtrl.text.trim(),
        subject: _subject,
        durationMins: _durationMins,
        startTime: _startTime,
        endTime: _endTime,
        questions: questions,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quiz Broadcasted! Students notified. ⚡'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
    setState(() => _isSaving = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10, right: -10,
                    child: Icon(Icons.bolt_rounded, color: Colors.white.withOpacity(0.1), size: 160),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create Quiz', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        StreamBuilder<ClassModel>(
                          stream: ClassService().getClassById(widget.classId),
                          builder: (context, classSnap) {
                            final className = classSnap.data?.displayName ?? '';
                            return Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                const Text('Configure academic assessment', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                if (className.isNotEmpty) ...[
                                  Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                                  Text('Target: $className', 
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                                  ),
                                ],
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_isSaving)
                const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              else
                IconButton(onPressed: _createQuiz, icon: const Icon(Icons.check_circle_rounded), tooltip: 'Create Quiz'),
            ],
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumCard(
                      opacity: 1,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.settings_outlined, size: 14, color: AppTheme.textHint),
                              SizedBox(width: 8),
                              Text('QUIZ CONFIGURATION', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Quiz Title',
                              prefixIcon: Icon(Icons.quiz_rounded, color: AppTheme.secondary),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Title required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _subject,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject', 
                                    prefixIcon: Icon(Icons.subject_rounded, color: AppTheme.secondary, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) => setState(() => _subject = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _durationMins,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Time', 
                                    prefixIcon: Icon(Icons.timer_rounded, color: AppTheme.secondary, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: [10, 15, 20, 30, 45, 60, 90, 120].map((d) => DropdownMenuItem(value: d, child: Text('$d m', style: const TextStyle(fontSize: 12)))).toList(),
                                  onChanged: (v) => setState(() => _durationMins = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _TimeSelector(label: 'Start Schedule', value: _startTime, onChanged: (dt) => setState(() => _startTime = dt)),
                          const SizedBox(height: 12),
                          _TimeSelector(label: 'Expiry Time', value: _endTime, onChanged: (dt) => setState(() => _endTime = dt)),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Text('Question Bank', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                        const Spacer(),
                        InkWell(
                          onTap: _isSaving ? null : _aiGenerateQuestions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.meshGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppTheme.secondary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text('AI GEN ✨', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ..._questions.asMap().entries.map((e) {
                      return _QuestionEditor(
                        key: ValueKey(e.key),
                        index: e.key,
                        draft: e.value,
                        onRemove: () => setState(() => _questions.removeAt(e.key)),
                      ).animate().fadeIn().slideX(begin: 0.1);
                    }),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addMCQQuestion,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                            label: const Text('Add MCQ'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.secondary),
                              foregroundColor: AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addShortQuestion,
                            icon: const Icon(Icons.short_text_rounded, size: 16),
                            label: const Text('Add Short'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.textHint),
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _createQuiz,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: Text(_isSaving ? 'Broadcasting...' : 'Launch Quiz Assessment', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: AppTheme.secondary.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).scale(),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _TimeSelector({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppTheme.secondary, size: 16),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd MMM, hh:mm a').format(value), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  QuestionType type;
  String text = '';
  final List<String> options = ['', '', '', ''];
  int correctOption = 0;
  double marks = 1;
  _QuestionDraft({required this.type});

  QuizQuestion toQuizQuestion() {
    return QuizQuestion(
      text: text,
      type: type,
      options: type == QuestionType.mcq ? List.from(options) : [],
      correctOption: type == QuestionType.mcq ? correctOption : null,
      marks: marks,
    );
  }
}

class _QuestionEditor extends StatefulWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  const _QuestionEditor({super.key, required this.index, required this.draft, required this.onRemove});

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('MISSION ${widget.index + 1}', style: const TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const Spacer(),
              SizedBox(
                width: 65,
                child: TextFormField(
                  initialValue: widget.draft.marks.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Score', isDense: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) widget.draft.marks = parsed;
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.draft.text,
            decoration: const InputDecoration(hintText: 'Describe the question challenge...', isDense: true),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            onChanged: (v) => widget.draft.text = v,
          ),
          if (widget.draft.type == QuestionType.mcq) ...[
            const SizedBox(height: 16),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: widget.draft.correctOption,
                      onChanged: (v) => setState(() => widget.draft.correctOption = v!),
                      activeColor: AppTheme.secondary,
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.draft.options[i],
                        decoration: InputDecoration(hintText: 'Choice ${['A', 'B', 'C', 'D'][i]}', isDense: true),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        onChanged: (v) => widget.draft.options[i] = v,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
