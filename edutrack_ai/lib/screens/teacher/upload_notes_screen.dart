import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedSubject = 'Mathematics';
  bool _isUploading = false;
  String? _filePath;
  String? _fileName;
  String? _fileType;

  final List<String> _subjects = ['Mathematics', 'Science', 'Physics', 'Chemistry',
    'Biology', 'English', 'Hindi', 'History', 'Geography', 'Computer Science'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
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
      // Upload to Cloudinary
      final result = await CloudinaryService.instance.uploadFile(_filePath!, _fileType ?? 'pdf');
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
        'classId': user?.classId ?? '',
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final classId = user?.classId ?? '';

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
                    children: const [
                      Text('Upload Notes', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('Share study materials with students', style: TextStyle(color: Colors.white70)),
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
                              Text(_fileName ?? 'Tap to select PDF / DOC / PPT',
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
                      .where('classId', isEqualTo: classId)
                      .where('teacherId', isEqualTo: user?.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) return const Center(child: Text('No notes uploaded yet', style: TextStyle(color: Colors.grey)));
                    return Column(
                      children: docs.asMap().entries.map((e) {
                        final d = e.value.data() as Map<String, dynamic>;
                        return Dismissible(
                          key: Key(e.value.id),
                          background: Container(
                            color: Colors.red, alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => e.value.reference.delete(),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PremiumCard(
                              opacity: 1,
                              padding: const EdgeInsets.all(14),
                              child: ListTile(
                                leading: const Icon(Icons.description_rounded, color: Color(0xFF059669)),
                                title: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(d['subject'] ?? ''),
                                trailing: const Icon(Icons.chevron_right_rounded),
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
