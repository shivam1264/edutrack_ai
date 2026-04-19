import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/config.dart';

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

  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Computer Science', 'Physics',
    'Chemistry', 'Biology',
  ];

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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('AI Question Generator'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topic (e.g. Solar System, Algebra)')),
            const SizedBox(height: 12),
            TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of Questions')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
        ],
      ),
    );

    if (result != true) return;

    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/generate-quiz')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topicCtrl.text.trim(),
          'subject': _subject,
          'count': int.tryParse(countCtrl.text) ?? 5,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> generated = jsonDecode(response.body);
        setState(() {
          for (var q in generated) {
            final draft = _QuestionDraft(type: QuestionType.mcq);
            draft.text = q['text'];
            for (int i = 0; i < 4; i++) {
              draft.options[i] = q['options'][i];
            }
            draft.correctOption = q['correctOption'];
            draft.marks = (q['marks'] as num).toDouble();
            _questions.add(draft);
          }
        });
        _showSnack('AI successfully generated ${generated.length} questions! ✨');
      } else {
        _showSnack('AI Generation failed. Check backend connection.', isError: true);
      }
    } catch (e) {
      _showSnack('Connectivity Error: $e', isError: true);
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
          const SnackBar(
            content: Text('Quiz created! 🎉'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
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
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              onPressed: _createQuiz,
              icon: const Icon(Icons.check_rounded, color: AppTheme.secondary),
              tooltip: 'Create Quiz',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Basic Info Card ──
              _SectionCard(
                title: 'Quiz Details',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quiz Title',
                        prefixIcon: Icon(Icons.quiz_rounded),
                      ),
                      validator: (v) =>
                          v?.isEmpty == true ? 'Title required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _subject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.subject_rounded),
                      ),
                      items: _subjects
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _subject = v!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _durationMins,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              prefixIcon: Icon(Icons.timer_rounded),
                            ),
                            items: [10, 15, 20, 30, 45, 60, 90, 120]
                                .map((d) => DropdownMenuItem(
                                    value: d, child: Text('$d mins')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _durationMins = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Time selectors
                    _TimeSelector(
                      label: 'Start Time',
                      value: _startTime,
                      onChanged: (dt) => setState(() => _startTime = dt),
                    ),
                    const SizedBox(height: 8),
                    _TimeSelector(
                      label: 'End Time',
                      value: _endTime,
                      onChanged: (dt) => setState(() => _endTime = dt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Questions ──
              Row(
                children: [
                  const Text(
                    'Questions',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_questions.length} added',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _isSaving ? null : _aiGenerateQuestions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.meshGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('AI MAGIC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._questions.asMap().entries.map((e) {
                return _QuestionEditor(
                  key: ValueKey(e.key),
                  index: e.key,
                  draft: e.value,
                  onRemove: () => setState(() => _questions.removeAt(e.key)),
                );
              }),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addMCQQuestion,
                      icon: const Icon(Icons.radio_button_checked_rounded,
                          size: 16),
                      label: const Text('Add MCQ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addShortQuestion,
                      icon: const Icon(Icons.short_text_rounded, size: 16),
                      label: const Text('Add Short'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _createQuiz,
                  icon: const Icon(Icons.publish_rounded),
                  label: Text(_isSaving ? 'Creating...' : 'Create Quiz'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _TimeSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

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
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onChanged(DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
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

  const _QuestionEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q${widget.index + 1} • ${widget.draft.type == QuestionType.mcq ? "MCQ" : "Short"}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Marks
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: widget.draft.marks.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) widget.draft.marks = parsed;
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.delete_rounded,
                    color: AppTheme.danger, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: widget.draft.text,
            decoration: const InputDecoration(
              hintText: 'Question text...',
              isDense: true,
            ),
            maxLines: 2,
            onChanged: (v) => widget.draft.text = v,
          ),
          if (widget.draft.type == QuestionType.mcq) ...[
            const SizedBox(height: 10),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: widget.draft.correctOption,
                      onChanged: (v) =>
                          setState(() => widget.draft.correctOption = v!),
                      activeColor: AppTheme.secondary,
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.draft.options[i],
                        decoration: InputDecoration(
                          hintText: 'Option ${['A', 'B', 'C', 'D'][i]}',
                          isDense: true,
                        ),
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
