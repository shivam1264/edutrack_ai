import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../student/doubt_box_screen.dart';
import 'submit_assignment_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Pending', 'Submitted', 'Graded'];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final classId = user?.classId ?? '';
    final studentId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Assignments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<List<AssignmentModel>>(
              stream: AssignmentService().streamAssignmentsByClass(classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load assignments'));
                }

                final assignments = snapshot.data ?? [];
                
                return FutureBuilder<List<SubmissionModel>>(
                  future: AssignmentService().getStudentSubmissions(studentId),
                  builder: (context, subSnapshot) {
                    if (subSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final submissions = subSnapshot.data ?? [];
                    final submissionMap = {for (var sub in submissions) sub.assignmentId: sub};

                    final filteredAssignments = assignments.where((a) {
                      final sub = submissionMap[a.id];
                      if (_selectedTabIndex == 0) return true;
                      if (_selectedTabIndex == 1) return sub == null; // Pending
                      if (_selectedTabIndex == 2) return sub != null && sub.status == AssignmentStatus.submitted; // Submitted
                      if (_selectedTabIndex == 3) return sub != null && sub.status == AssignmentStatus.graded; // Graded
                      return true;
                    }).toList();

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          if (filteredAssignments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No assignments found.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                            )
                          else
                            ...filteredAssignments.map((assignment) {
                              final sub = submissionMap[assignment.id];
                              String status = 'Pending';
                              Color statusColor = Colors.blue;
                              
                              if (sub != null) {
                                if (sub.status == AssignmentStatus.graded) {
                                  status = 'Graded (${sub.marks}/${assignment.maxMarks})';
                                  statusColor = Colors.green;
                                } else {
                                  status = 'Submitted';
                                  statusColor = Colors.orange;
                                }
                              } else if (assignment.dueDate.isBefore(DateTime.now())) {
                                status = 'Overdue';
                                statusColor = Colors.red;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => SubmitAssignmentScreen(assignment: assignment, existingSubmission: sub)),
                                    );
                                  },
                                  child: _AssignmentCard(
                                    subject: assignment.subject,
                                    title: assignment.title,
                                    dueDate: 'Due: ${DateFormat('MMM dd, yyyy').format(assignment.dueDate)}',
                                    status: status,
                                    statusColor: statusColor,
                                    icon: _getIconForSubject(assignment.subject),
                                    color: _getColorForSubject(assignment.subject),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          _buildHelpBanner(context),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  }
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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            return GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: _TabItem(_tabs[index], isSelected: _selectedTabIndex == index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHelpBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                const SizedBox(height: 4),
                const Text('Ask your doubt in Doubt Box', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtBoxScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Ask Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Icons.calculate;
      case 'science': return Icons.science;
      case 'english': return Icons.book;
      case 'history': return Icons.history_edu;
      case 'computer': return Icons.computer;
      default: return Icons.library_books;
    }
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Colors.blue;
      case 'science': return Colors.green;
      case 'english': return Colors.orange;
      case 'history': return Colors.purple;
      case 'computer': return Colors.teal;
      default: return AppTheme.primary;
    }
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabItem(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final String subject;
  final String title;
  final String dueDate;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color color;

  const _AssignmentCard({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(dueDate, style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
