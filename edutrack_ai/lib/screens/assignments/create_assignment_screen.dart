import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;

  const CreateAssignmentScreen({super.key, required this.classId});

  @override
  State<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '100');
  String _subject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  File? _pickedFile;
  String? _pickedFileName;
  bool _isSaving = false;

  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Computer Science', 'Physics',
    'Chemistry', 'Biology', 'History',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
        _pickedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      await AssignmentService().createAssignment(
        classId: widget.classId,
        teacherId: uid,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        subject: _subject,
        dueDate: _dueDate,
        maxMarks: double.parse(_marksCtrl.text),
        attachedFile: _pickedFile,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully! 🎉'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Create Assignment'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──
              _label('Assignment Title'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Chapter 3 - Algebra Problems',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    v?.isEmpty == true ? 'Title required' : null,
              ),
              const SizedBox(height: 16),

              // ── Subject ──
              _label('Subject'),
              DropdownButtonFormField<String>(
                value: _subject,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.subject_rounded),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _subject = v!),
              ),
              const SizedBox(height: 16),

              // ── Description ──
              _label('Description'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the assignment in detail...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child: Icon(Icons.description_rounded),
                  ),
                ),
                validator: (v) =>
                    v?.isEmpty == true ? 'Description required' : null,
              ),
              const SizedBox(height: 16),

              // ── Max Marks ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Max Marks'),
                        TextFormField(
                          controller: _marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.star_rounded),
                          ),
                          validator: (v) {
                            if (v?.isEmpty == true) return 'Required';
                            if (double.tryParse(v!) == null)
                              return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Due Date'),
                        GestureDetector(
                          onTap: _pickDueDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_rounded,
                                    color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM').format(_dueDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── File Attachment ──
              _label('Attach File (Optional)'),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pickedFile != null
                          ? AppTheme.primary
                          : AppTheme.borderLight,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedFile != null
                            ? Icons.attachment_rounded
                            : Icons.upload_file_rounded,
                        color: _pickedFile != null
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedFileName ?? 'Tap to attach a file',
                          style: TextStyle(
                            color: _pickedFile != null
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      if (_pickedFile != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _pickedFile = null;
                            _pickedFileName = null;
                          }),
                          child: const Icon(Icons.close_rounded,
                              color: AppTheme.danger, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Create Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _create,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_task_rounded),
                  label:
                      Text(_isSaving ? 'Creating...' : 'Create Assignment'),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 13),
        ),
      );

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
}
