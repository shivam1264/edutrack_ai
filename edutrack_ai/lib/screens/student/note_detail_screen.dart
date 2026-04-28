import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'note_editor_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final NoteModel note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final isTeacherNote = note.teacherId != null;
    final hasFile = note.fileUrl != null && note.fileUrl!.isNotEmpty;
    final isImage = (note.fileType != null && ['jpg', 'jpeg', 'png', 'webp'].contains(note.fileType!.toLowerCase())) ||
                     (note.fileUrl != null && ['jpg', 'jpeg', 'png', 'webp'].any((ext) => note.fileUrl!.toLowerCase().contains(ext)));
    final isPdf = (note.fileType != null && note.fileType!.toLowerCase() == 'pdf') ||
                   (note.fileUrl != null && note.fileUrl!.toLowerCase().contains('.pdf'));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(note.subject, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Text(
                        '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(note.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  if (isTeacherNote)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Shared by ${note.teacherName}', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 24),
                  
                  if (hasFile && isImage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetwork_Image(
                          imageUrl: note.fileUrl!,
                          placeholder: (context, url) => Container(height: 200, color: Colors.grey[100], child: const Center(child: CircularProgressIndicator())),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    
                  if (note.content.isNotEmpty || note.description != null)
                    Text(
                      note.content.isNotEmpty ? note.content : (note.description ?? ''),
                      style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
                    ),
                    
                  if (hasFile && !isImage)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(note.fileType?.toUpperCase() ?? 'PDF', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 4),
                            const Text('Academic Resource Attached', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _launchURL(note.fileUrl!, context),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: const Text('Open Resource', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isTeacherNote ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note))),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('Edit Personal Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      // Force external application for PDFs (browser or PDF viewer)
      // This is generally more reliable for Cloudinary URLs on mobile
      await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open resource. Please ensure a PDF viewer is installed.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.studentGradient),
          child: Center(
            child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }
}

// Fixed a typo in the widget name
typedef CachedNetwork_Image = CachedNetworkImage;
