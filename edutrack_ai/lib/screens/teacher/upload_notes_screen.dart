import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';

class UploadNotesScreen extends StatefulWidget {
  final String classId;
  const UploadNotesScreen({super.key, required this.classId});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedSubject;
  bool _isUploading = false;
  String? _filePath;
  String? _fileName;
  String? _fileType;

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
        _selectedSubject = _subjects.first;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _filePath = result.files.first.path;
        _fileName = result.files.first.name;
        _fileType = result.files.first.extension ?? 'pdf';
      });
    }
  }

  Future<void> _uploadNote() async {
    if (_titleCtrl.text.trim().isEmpty || _filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and select a file'), backgroundColor: Colors.orange),
      );
      return;
    }
    final user = context.read<AuthProvider>().user;
    setState(() => _isUploading = true);
    try {
      final result = await CloudinaryService.instance.uploadFile(File(_filePath!));
      if (result == null) throw Exception('Upload failed');
      final url = result.secureUrl;

      await FirebaseFirestore.instance.collection('notes').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'subject': _selectedSubject,
        'fileUrl': url,
        'fileType': _fileType ?? 'pdf',
        'fileName': _fileName,
        'teacherId': user?.uid,
        'teacherName': user?.name ?? 'Teacher',
        'class_id': widget.classId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() { _filePath = null; _fileName = null; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Note uploaded successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to remove this academic resource? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('notes').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted permanently.')));
      }
    }
  }

  Future<void> _editNote(String id, Map<String, dynamic> data) async {
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['description']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note Resources'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('notes').doc(id).update({
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final classId = widget.classId;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF34D399)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upload Notes', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      StreamBuilder<ClassModel>(
                        stream: ClassService().getClassById(classId),
                        builder: (context, classSnap) {
                          final className = classSnap.data?.displayName ?? '';
                          return Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text('Share study materials', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                      const Text('Note Title', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g., Chapter 5 - Algebra Notes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Subject', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _selectedSubject = v!),
                      ),
                      const SizedBox(height: 16),
                      const Text('Description (optional)', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Brief description of the note...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: _filePath != null ? const Color(0xFF059669) : Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
                            color: _filePath != null ? const Color(0xFF059669).withOpacity(0.05) : AppTheme.bgLight,
                          ),
                          child: Column(
                            children: [
                              Icon(_filePath != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                                  size: 40, color: _filePath != null ? const Color(0xFF059669) : Colors.grey),
                              const SizedBox(height: 8),
                              Text(_fileName ?? 'Tap to select PDF / Image / Document',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _filePath != null ? const Color(0xFF059669) : Colors.grey, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isUploading
                              ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Uploading...'),
                              ])
                              : const Text('Upload Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 24),
                const Text('📚 Uploaded Notes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notes')
                      .where('teacherId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    
                    var docs = snap.data!.docs;
                    var filteredDocs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['class_id'] == classId;
                    }).toList();
                    
                    filteredDocs.sort((a, b) {
                      final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                    });
                    
                    if (filteredDocs.isEmpty) return const Center(child: Text('No notes uploaded for this class yet', style: TextStyle(color: Colors.grey)));
                    return Column(
                      children: filteredDocs.asMap().entries.map((e) {
                        final d = e.value.data() as Map<String, dynamic>;
                        final docId = e.value.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            opacity: 1,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.description_rounded, color: Color(0xFF059669)),
                              ),
                              title: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                              subtitle: Row(
                                children: [
                                  Text(d['subject'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.remove_red_eye_outlined, size: 12, color: AppTheme.textHint),
                                  const SizedBox(width: 4),
                                  Text('${d['view_count'] ?? 0} Views', style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 20),
                                    onPressed: () => _editNote(docId, d),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                                    onPressed: () => _deleteNote(docId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (e.key * 60).ms);
                      }).toList(),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
