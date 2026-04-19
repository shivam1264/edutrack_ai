import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'submission_list_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AssignmentAuditScreen extends StatefulWidget {
  final String classId;
  const AssignmentAuditScreen({super.key, required this.classId});

  @override
  State<AssignmentAuditScreen> createState() => _AssignmentAuditScreenState();
}

class _AssignmentAuditScreenState extends State<AssignmentAuditScreen> {
  final AssignmentService _service = AssignmentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Academic Audit'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: StreamBuilder<List<AssignmentModel>>(
        stream: _service.streamAssignmentsByClass(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final a = items[index];
              return PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.assignment_rounded, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(a.subject, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmissionListScreen(assignment: a))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary.withOpacity(0.1),
                        foregroundColor: AppTheme.secondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fact_check_outlined, size: 60, color: AppTheme.borderLight),
          const SizedBox(height: 16),
          Text('No assignments to audit.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
