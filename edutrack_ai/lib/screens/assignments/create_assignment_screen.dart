import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          SnackBar(
            content: const Text('Mission Configured! Assignment live. 🚀'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('System Recall: $e'),
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10, right: -10,
                    child: Icon(Icons.add_task_rounded, color: Colors.white.withOpacity(0.1), size: 160),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create Assignment', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        Row(
                          children: [
                            Text('Deploy new academic missions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('Target: Sector ${widget.classId}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildFormCard(
                        title: 'Basic Info',
                        icon: Icons.info_outline_rounded,
                        children: [
                          _label('Assignment Title'),
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Quantum Mechanics Intro',
                              prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primary),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Title required' : null,
                          ),
                          const SizedBox(height: 16),
                          _label('Subject'),
                          DropdownButtonFormField<String>(
                            value: _subject,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.subject_rounded, color: AppTheme.primary),
                            ),
                            items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _subject = v!),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      _buildFormCard(
                        title: 'Mission Brief',
                        icon: Icons.description_outlined,
                        children: [
                          _label('Detailed Description'),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Provide clear instructions for the mission...',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Description required' : null,
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      _buildFormCard(
                        title: 'Deadlines & Rewards',
                        icon: Icons.stars_outlined,
                        children: [
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
                                        prefixIcon: Icon(Icons.star_rounded, color: AppTheme.accent),
                                      ),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.borderLight),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.event_rounded, color: AppTheme.primary, size: 18),
                                            const SizedBox(width: 8),
                                            Text(DateFormat('dd MMM').format(_dueDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      _buildFormCard(
                        title: 'Intelligence Assets',
                        icon: Icons.attachment_rounded,
                        children: [
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _pickedFile != null ? AppTheme.primary : AppTheme.borderLight,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(_pickedFile != null ? Icons.description_rounded : Icons.cloud_upload_outlined, color: _pickedFile != null ? AppTheme.primary : AppTheme.textHint),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _pickedFileName ?? 'Attach reference materials',
                                      style: TextStyle(color: _pickedFile != null ? AppTheme.textPrimary : AppTheme.textHint, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (_pickedFile != null) const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _create,
                          icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.rocket_launch_rounded),
                          label: Text(_isSaving ? 'Deploying...' : 'Deploy Assignment', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppTheme.primary.withOpacity(0.4),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required List<Widget> children}) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textHint),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 11, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13)),
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
