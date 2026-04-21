import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AssignmentModel> _assignments = [];
  List<SubmissionModel> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().user;
    final uid = user?.uid ?? '';
    final classId = user?.classId ?? '';

    try {
      final results = await Future.wait([
        AssignmentService().getAssignmentsByClass(classId),
        AssignmentService().getStudentSubmissions(uid),
      ]);
      _assignments = results[0] as List<AssignmentModel>;
      _submissions = results[1] as List<SubmissionModel>;
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  bool _isSubmitted(String assignmentId) => _submissions.any((s) => s.assignmentId == assignmentId);

  SubmissionModel? _getSubmission(String assignmentId) {
    try {
      return _submissions.firstWhere((s) => s.assignmentId == assignmentId);
    } catch (_) {
      return null;
    }
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
            backgroundColor: AppTheme.accent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.assignment_ind_rounded, color: Colors.white.withOpacity(0.1), size: 200),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mission Logs', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        Text('Manage your academic objectives', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              child: Container(
                color: AppTheme.bgLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicator: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: '🚨 Pending'),
                      Tab(text: '✅ Done'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(pending: true),
                      _buildList(pending: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({required bool pending}) {
    final filtered = _assignments.where((a) {
      final submitted = _isSubmitted(a.id);
      return pending ? !submitted : submitted;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pending ? Icons.assignment_turned_in_rounded : Icons.assignment_rounded, size: 80, color: AppTheme.accent.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(pending ? 'All clear! No pending tasks 🎉' : 'No submission records yet', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final assignment = filtered[index];
          final submission = _getSubmission(assignment.id);
          return _AssignmentCard(
            assignment: assignment,
            submission: submission,
            studentId: context.read<AuthProvider>().user?.uid ?? '',
            onSubmitted: _loadData,
          ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final SubmissionModel? submission;
  final String studentId;
  final VoidCallback onSubmitted;

  const _AssignmentCard({required this.assignment, required this.submission, required this.studentId, required this.onSubmitted});

  Color get _dueDateColor {
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return AppTheme.danger;
    if (daysLeft <= 2) return AppTheme.warning;
    return AppTheme.secondary;
  }

  String get _dueDateLabel {
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return '${daysLeft.abs()}d overdue';
    if (daysLeft == 0) return 'Due Today!';
    if (daysLeft == 1) return 'Due Tomorrow';
    return 'Due in ${daysLeft}d';
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitted = submission != null;
    final graded = submission?.marks != null;

    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                ),
              ),
              if (graded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${submission!.marks!.toStringAsFixed(0)}/${assignment.maxMarks.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTag(assignment.subject, AppTheme.accent),
              const SizedBox(width: 12),
              Icon(Icons.schedule_rounded, size: 14, color: _dueDateColor),
              const SizedBox(width: 4),
              Text(_dueDateLabel, style: TextStyle(color: _dueDateColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            assignment.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (!isSubmitted)
            Row(
              children: [
                if (assignment.fileUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(assignment.fileUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.description_rounded, size: 16),
                      label: const Text('View Brief'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (assignment.fileUrl != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSubmitDialog(context),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppTheme.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      graded ? 'Mission Evaluated' : 'Mission Submitted — Pending Review',
                      style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  if (submission?.submittedAt != null)
                    Text(DateFormat('dd MMM').format(submission!.submittedAt!), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Final Submission', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: noteCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any message for your teacher?',
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await AssignmentService().submitAssignment(assignmentId: assignment.id, studentId: studentId, note: noteCtrl.text.trim());

                    // Award XP for assignment submission (fixed 50 XP)
                    if (context.mounted) {
                      context.read<GamificationProvider>().addXp(studentId, 50);
                    }

                    onSubmitted();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Mission Complete! Assignment submitted. ✅'),
                          backgroundColor: AppTheme.secondary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Transmit Submission', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 80;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
