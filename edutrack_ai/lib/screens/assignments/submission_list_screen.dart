import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/config.dart';

class SubmissionListScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const SubmissionListScreen({super.key, required this.assignment});

  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  final AssignmentService _service = AssignmentService();
  bool _isLoading = true;
  List<SubmissionModel> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final list = await _service.getSubmissionsByAssignment(widget.assignment.id);
    setState(() {
      _submissions = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Submissions: ${widget.assignment.title}'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _submissions.length,
                  itemBuilder: (context, index) {
                    return _SubmissionListItem(submission: _submissions[index])
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.1);
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 60, color: AppTheme.borderLight),
          const SizedBox(height: 16),
          Text('No submissions yet.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SubmissionListItem extends StatefulWidget {
  final SubmissionModel submission;
  const _SubmissionListItem({required this.submission});

  @override
  State<_SubmissionListItem> createState() => _SubmissionListItemState();
}

class _SubmissionListItemState extends State<_SubmissionListItem> {
  bool _isChecking = false;
  Map<String, dynamic>? _aiResult;

  Future<void> _checkOriginality() async {
    setState(() => _isChecking = true);
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/check-originality')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': widget.submission.content}),
      );

      if (response.statusCode == 200) {
        setState(() => _aiResult = jsonDecode(response.body));
      }
    } catch (e) {
      print('Originality Check Error: $e');
    }
    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: AppTheme.primary, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    Text(widget.submission.studentId, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (_aiResult != null)
                 _buildRiskBadge(_aiResult!['ai_probability']),
            ],
          ),
          const SizedBox(height: 12),
          const Text('CONTENT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(widget.submission.content ?? '[No content]', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_aiResult == null)
                TextButton.icon(
                  onPressed: _isChecking ? null : _checkOriginality,
                  icon: _isChecking 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(_isChecking ? 'Scanning...' : 'Check Originality'),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
                    child: Text(_aiResult!['analysis'], style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(double prob) {
    final isHigh = prob > 0.7;
    final isMed = prob > 0.4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh ? AppTheme.danger.withOpacity(0.1) : (isMed ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'AI PROB: ${(prob * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: isHigh ? AppTheme.danger : (isMed ? Colors.orange : Colors.green),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
