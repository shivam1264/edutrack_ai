import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../services/assignment_service.dart';
import '../../services/quiz_service.dart';
import '../../services/note_service.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../assignments/create_assignment_screen.dart';
import '../quiz/create_quiz_screen.dart';
import '../quiz/quiz_results_list_screen.dart';
import 'upload_notes_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ResourceManagementScreen extends StatefulWidget {
  final String classId;
  const ResourceManagementScreen({super.key, required this.classId});

  @override
  State<ResourceManagementScreen> createState() => _ResourceManagementScreenState();
}

class _ResourceManagementScreenState extends State<ResourceManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
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
                    child: Icon(Icons.manage_accounts_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resource Manager', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        const Text('Audit and maintain your academic assets', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Assignments'),
                Tab(text: 'Quizzes'),
                Tab(text: 'Notes'),
              ],
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              dividerColor: Colors.transparent,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AssignmentsList(classId: widget.classId),
                _QuizzesList(classId: widget.classId),
                _NotesList(classId: widget.classId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsList extends StatelessWidget {
  final String classId;
  const _AssignmentsList({required this.classId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AssignmentModel>>(
      stream: AssignmentService().streamAssignmentsByClass(classId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return _buildEmpty('No assignments deployed.');

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) => _ResourceItem(
            title: list[i].title,
            subtitle: 'Due: ${DateFormat('dd MMM').format(list[i].dueDate)}',
            icon: Icons.assignment_rounded,
            color: Colors.blue,
            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen(classId: classId, assignment: list[i]))),
            onDelete: () => _confirmDelete(context, 'Assignment', () => AssignmentService().deleteAssignment(list[i].id)),
          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1),
        );
      },
    );
  }
}

class _QuizzesList extends StatelessWidget {
  final String classId;
  const _QuizzesList({required this.classId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuizModel>>(
      stream: QuizService().streamQuizzesByClass(classId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return _buildEmpty('No quizzes active.');

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) => _ResourceItem(
            title: list[i].title,
            subtitle: '${list[i].questions.length} Questions • ${list[i].durationMins}m',
            icon: Icons.bolt_rounded,
            color: Colors.orange,
            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizScreen(classId: classId, quiz: list[i]))),
            onDelete: () => _confirmDelete(context, 'Quiz', () => QuizService().deleteQuiz(list[i].id)),
            trailing: IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizResultsListScreen(quiz: list[i]))), icon: const Icon(Icons.bar_chart_rounded, color: Colors.orange)),
          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1),
        );
      },
    );
  }
}

class _NotesList extends StatelessWidget {
  final String classId;
  const _NotesList({required this.classId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoteModel>>(
      stream: NoteService().streamNotesByClass(classId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return _buildEmpty('No notes uploaded.');

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) => _ResourceItem(
            title: list[i].title,
            subtitle: list[i].subject,
            icon: Icons.note_rounded,
            color: Colors.green,
            onEdit: () {
              // Notes editing is handled within UploadNotesScreen typically, 
              // but we can redirect or show a dialog.
              Navigator.push(context, MaterialPageRoute(builder: (_) => UploadNotesScreen(classId: classId)));
            },
            onDelete: () => _confirmDelete(context, 'Note', () => NoteService().deleteNote(list[i].id)),
          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1),
        );
      },
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? trailing;

  const _ResourceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onEdit,
    required this.onDelete,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded, color: AppTheme.secondary)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger)),
        ],
      ),
    );
  }
}

Widget _buildEmpty(String msg) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textHint.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(msg, style: const TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.w600)),
    ],
  ),
);

void _confirmDelete(BuildContext context, String type, Future<void> Function() onDelete) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Purge $type?'),
      content: Text('This action will permanently delete this $type and all associated data. Proceed?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await onDelete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type purged from archives. 🗑️'), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
