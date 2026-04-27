import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedSubject = 'General';
  bool _isSaving = false;

  final List<String> _subjects = ['General', 'Mathematics', 'Science', 'English', 'History', 'Computer'];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedSubject = _subjects.contains(note.subject) ? note.subject : 'General';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: () => _saveNote(userId),
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSubjectPicker(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Note Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Start writing your mission notes...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPicker() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedSubject == _subjects[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_subjects[index]),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedSubject = _subjects[index]),
              selectedColor: AppTheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveNote(String userId) async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both title and content.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'student_id': userId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'subject': _selectedSubject,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (widget.note == null) {
        await FirebaseFirestore.instance.collection('notes').add({
          ...data,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('notes').doc(widget.note!.id).update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved successfully! ✅')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save note.')));
      }
    }
  }
}
