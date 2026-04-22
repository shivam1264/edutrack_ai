import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Map<String, String> _studentNames = {};

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final list = await _service.getSubmissionsByAssignment(widget.assignment.id);
    
    // Resolve names for all students who submitted
    for (var sub in list) {
      if (!_studentNames.containsKey(sub.studentId)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(sub.studentId).get();
        if (userDoc.exists) {
          _studentNames[sub.studentId] = userDoc.data()?['name'] ?? 'Incomplete Profile';
        } else {
          _studentNames[sub.studentId] = 'Unknown Student';
        }
      }
    }

    setState(() {
      _submissions = list;
      _isLoading = false;
    });
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
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.fact_check_rounded, color: Colors.white.withOpacity(0.1), size: 200),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.assignment.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text('Intellectual Submission Log • ${_submissions.length} Total', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _submissions.isEmpty
                    ? _buildEmpty()
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sub = _submissions[index];
                            final studentName = _studentNames[sub.studentId] ?? 'Resolving Identity...';
                            return _SubmissionListItem(submission: sub, studentName: studentName)
                                .animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
                          },
                          childCount: _submissions.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.textHint.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No submissions detected.', style: TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.w900)),
            const Text('The class is currently inactive.', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SubmissionListItem extends StatefulWidget {
  final SubmissionModel submission;
  final String studentName;
  const _SubmissionListItem({required this.submission, required this.studentName});

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
      ).timeout(const Duration(seconds: 45));

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
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(widget.studentName[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.studentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                    Text('UID Hash: ${widget.submission.studentId.substring(0, 8)}...', style: const TextStyle(fontSize: 10, color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_aiResult != null)
                 _buildRiskBadge(_aiResult!['ai_probability']),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          const Row(
            children: [
              Icon(Icons.description_rounded, size: 14, color: AppTheme.textHint),
              SizedBox(width: 8),
              Text('SUBMISSION LOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textHint, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.submission.content ?? '[No text content transmitted]', 
            maxLines: 4, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          if (_aiResult == null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkOriginality,
                icon: _isChecking 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.bolt_rounded, size: 18),
                label: Text(_isChecking ? 'Scanning Content...' : 'Initiate Originality Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('AI ANALYSIS VERDICT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiResult!['analysis'], style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(dynamic prob) {
    final double p = (prob is int) ? prob.toDouble() : (prob as double);
    final isHigh = p > 0.7;
    final isMed = p > 0.4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHigh ? AppTheme.danger.withOpacity(0.1) : (isMed ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'AI PROB: ${(p * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: isHigh ? AppTheme.danger : (isMed ? Colors.orange : Colors.green),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
