import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edutrack_ai/models/note_model.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/models/user_model.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/screens/student/note_detail_screen.dart';
import 'package:edutrack_ai/screens/student/note_editor_screen.dart';
import 'package:edutrack_ai/screens/teacher/upload_notes_screen.dart';

class NotesLibraryScreen extends StatefulWidget {
  final String? classId;
  const NotesLibraryScreen({super.key, this.classId});

  @override
  State<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends State<NotesLibraryScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Mathematics', 'Science', 'English', 'History', 'Computer'];

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final classId = widget.classId ?? user?.classId;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Academic Vault', style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notes')
                  .where('class_id', isEqualTo: classId ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Sort in-memory to avoid index requirement
                final sortedDocs = docs.toList();
                sortedDocs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                });

                var notes = sortedDocs.map((d) {
                  return NoteModel.fromMap(d.id, d.data() as Map<String, dynamic>);
                }).toList();
                
                // Filter by selected tab
                if (_selectedTabIndex > 0) {
                  final selectedSubject = _tabs[_selectedTabIndex];
                  notes = notes.where((n) => n.subject.toLowerCase() == selectedSubject.toLowerCase()).toList();
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    children: [
                      if (notes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.note_alt_rounded, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No notes found for this subject.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...notes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NoteListCard(
                              note: note,
                              onTap: () {
                                // Increment view count in Firestore
                                if (note.teacherId != null) {
                                  FirebaseFirestore.instance.collection('notes').doc(note.id).update({
                                    'view_count': FieldValue.increment(1),
                                  });
                                }
                                Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)));
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      _buildCreateNoteBanner(classId),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 50,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateNoteBanner(String? classId) {
    final user = context.read<AuthProvider>().user;
    final isTeacher = user?.role == UserRole.teacher;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.05), Colors.white]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTeacher ? 'Resource Hub' : 'Personal Notebook', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryDark)),
                const SizedBox(height: 4),
                Text(isTeacher ? 'Manage and share academic materials' : 'Capture your thoughts and organize your studies.', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isTeacher) {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => UploadNotesScreen(classId: classId ?? '')));
                    } else {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorScreen()));
                    }
                  },
                  icon: Icon(isTeacher ? Icons.cloud_upload_rounded : Icons.add_rounded, size: 18),
                  label: Text(isTeacher ? 'Upload New Resource' : 'Create New Note', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Icon(isTeacher ? Icons.folder_zip_rounded : Icons.edit_note_rounded, color: Colors.orange, size: 64),
        ],
      ),
    );
  }
}

class _NoteListCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteListCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTeacherNote = note.teacherId != null;

    return GestureDetector(
      onTap: onTap,
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorForSubject(note.subject).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isTeacherNote ? Icons.description_rounded : _getIconForSubject(note.subject), 
                color: _getColorForSubject(note.subject), 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(note.subject, style: TextStyle(color: _getColorForSubject(note.subject), fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(isTeacherNote ? 'By ${note.teacherName}' : 'Personal', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            if (isTeacherNote)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show Delete only for teachers (Mock check or Auth check)
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isOwner = auth.user?.uid == note.teacherId;
                      if (!isOwner) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove Resource?'),
                              content: const Text('This will delete the note for all students in this class.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance.collection('notes').doc(note.id).delete();
                          }
                        },
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Resource', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return Icons.calculate;
      case 'science': return Icons.science;
      case 'english': return Icons.book;
      case 'history': return Icons.history_edu;
      case 'computer': return Icons.computer;
      default: return Icons.library_books;
    }
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return Colors.blue;
      case 'science': return Colors.green;
      case 'english': return Colors.orange;
      case 'history': return Colors.purple;
      case 'computer': return Colors.teal;
      default: return AppTheme.primary;
    }
  }
}
