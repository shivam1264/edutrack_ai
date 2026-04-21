import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'flashcard_generator_screen.dart';
import 'ai_mindmap_screen.dart';

class NotesLibraryScreen extends StatefulWidget {
  const NotesLibraryScreen({super.key});

  @override
  State<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends State<NotesLibraryScreen> {
  String _selectedSubject = 'All';
  final List<String> _subjects = ['All', 'Mathematics', 'Science', 'Physics',
    'Chemistry', 'Biology', 'English', 'Hindi', 'History', 'Geography', 'Computer Science'];

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
            expandedHeight: 160,
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
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: Icon(Icons.menu_book_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes Library', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          Row(
                            children: [
                              Text('Study materials from your teachers', style: TextStyle(color: Colors.white70)),
                              const SizedBox(width: 8),
                              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text('Sector: ${context.read<AuthProvider>().user?.classId ?? 'N/A'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = _subjects[i] == _selectedSubject;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSubject = _subjects[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF059669) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: selected ? [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 8)] : [],
                        ),
                        child: Text(_subjects[i],
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                              color: selected ? Colors.white : AppTheme.textSecondary),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getNotesStream(classId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(40), child: CircularProgressIndicator(),
                )));
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No notes uploaded yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return _NoteCard(data: d).animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.3);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getNotesStream(String classId) {
    var query = FirebaseFirestore.instance
        .collection('notes')
        .where('classId', isEqualTo: classId);
    if (_selectedSubject != 'All') {
      query = query.where('subject', isEqualTo: _selectedSubject);
    }
    return query.snapshots();
  }
}

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NoteCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final fileType = (data['fileType'] ?? 'pdf').toString().toLowerCase();
    final icon = fileType == 'pdf' ? Icons.picture_as_pdf_rounded
        : fileType == 'video' ? Icons.play_circle_rounded
        : Icons.insert_drive_file_rounded;
    final color = fileType == 'pdf' ? Colors.red
        : fileType == 'video' ? Colors.blue
        : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? 'Note', style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(data['subject'] ?? '', style: const TextStyle(
                            fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text('by ${data['teacherName'] ?? 'Teacher'}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  if (data['description'] != null && data['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(data['description'], maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on_rounded, color: AppTheme.accent),
                  tooltip: 'Generate Flashcards',
                  onPressed: () {
                    final url = data['fileUrl'];
                    if (url != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FlashcardGeneratorScreen(initialFileUrl: url)
                      ));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_tree_rounded, color: AppTheme.accent),
                  tooltip: 'Generate Mind Map',
                  onPressed: () {
                    final url = data['fileUrl'];
                    if (url != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AIMindMapScreen(initialFileUrl: url)
                      ));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF059669)),
                  onPressed: () async {
                    final url = data['fileUrl'];
                    if (url != null) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
