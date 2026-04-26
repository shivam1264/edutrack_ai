import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final SubmissionModel? existingSubmission;

  const SubmitAssignmentScreen({
    super.key,
    required this.assignment,
    this.existingSubmission,
  });

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSubmission?.content != null) {
      _controller.text = widget.existingSubmission!.content!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your answer before submitting.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final studentId = context.read<AuthProvider>().user!.uid;
      await AssignmentService().submitAssignment(
        assignmentId: widget.assignment.id,
        studentId: studentId,
        content: content,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final isAlreadySubmitted = widget.existingSubmission != null;
    final isGraded = isAlreadySubmitted && widget.existingSubmission!.status == AssignmentStatus.graded;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(assignment.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignment Info Card
                PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(assignment.subject, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const Spacer(),
                          Text(
                            'Max: ${assignment.maxMarks.toInt()} marks',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Text(assignment.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Graded Result
                if (isGraded) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.grade, color: Colors.green, size: 36),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Graded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            const SizedBox(height: 4),
                            Text(
                              'Score: ${widget.existingSubmission!.marks?.toInt() ?? 0} / ${assignment.maxMarks.toInt()}',
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (widget.existingSubmission!.feedback != null)
                              Text('Feedback: ${widget.existingSubmission!.feedback}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Your Answer
                const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 10,
                  readOnly: isAlreadySubmitted,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Write your answer here...',
                    hintStyle: const TextStyle(color: AppTheme.textHint),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          // Submit Button
          if (!isAlreadySubmitted)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
