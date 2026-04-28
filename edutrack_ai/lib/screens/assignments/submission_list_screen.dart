import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/config.dart';
import 'package:url_launcher/url_launcher.dart';

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
    
    // Parallelize name fetching for better performance
    await Future.wait(list.map((sub) async {
      if (!_studentNames.containsKey(sub.studentId)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(sub.studentId).get();
        if (userDoc.exists) {
          _studentNames[sub.studentId] = userDoc.data()?['name'] ?? 'Incomplete Profile';
        } else {
          _studentNames[sub.studentId] = 'Unknown Student';
        }
      }
    }));

    if (mounted) {
      setState(() {
        _submissions = list;
        _isLoading = false;
      });
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
            backgroundColor: AppTheme.secondary,
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
                            return _SubmissionListItem(
                              submission: sub, 
                              studentName: studentName, 
                              maxMarks: widget.assignment.maxMarks,
                              onGraded: _loadSubmissions,
                            ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
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
  final double maxMarks;
  final VoidCallback onGraded;

  const _SubmissionListItem({
    required this.submission, 
    required this.studentName, 
    required this.maxMarks,
    required this.onGraded,
  });

  @override
  State<_SubmissionListItem> createState() => _SubmissionListItemState();
}

class _SubmissionListItemState extends State<_SubmissionListItem> {
  bool _isChecking = false;
  Map<String, dynamic>? _aiResult;

  Future<void> _checkOriginality() async {
    if (widget.submission.content == null || widget.submission.content!.isEmpty) return;
    
    setState(() => _isChecking = true);
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/check-originality')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': widget.submission.content}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() => _aiResult = result);
        // Save to Firestore
        await AssignmentService().saveAIScanResult(
          submissionId: widget.submission.id,
          result: result,
        );
      }
    } catch (e) {
      debugPrint('Originality Check Error: $e');
    }
    setState(() => _isChecking = false);
  }

  Future<void> _scanImageWithAI() async {
    if (widget.submission.fileUrl == null) return;
    
    setState(() => _isChecking = true);
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/scan-image')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_url': widget.submission.fileUrl,
          'submission_id': widget.submission.id,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() => _aiResult = result);
        // Save to Firestore
        await AssignmentService().saveAIScanResult(
          submissionId: widget.submission.id,
          result: result,
        );
      }
    } catch (e) {
      debugPrint('Image Scan Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image scan failed: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isChecking = false);
  }

  Future<void> _allowResubmission() async {
    try {
      await AssignmentService().allowResubmission(widget.submission.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student can now resubmit this assignment'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGraded();  // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showResubmissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: AppTheme.secondary),
            SizedBox(width: 12),
            Text('Allow Resubmission?', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'This will allow the student to submit this assignment again. Use this when you want the student to improve their work.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _allowResubmission();
            },
            icon: const Icon(Icons.check),
            label: const Text('Allow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile() async {
    if (widget.submission.fileUrl != null) {
      final url = Uri.parse(widget.submission.fileUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _showGradeDialog() async {
    final marksCtrl = TextEditingController(text: widget.submission.marks?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: widget.submission.feedback ?? '');
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.grade_rounded, color: AppTheme.secondary),
              const SizedBox(width: 12),
              const Text('Evaluate Mission', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${widget.studentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textHint)),
              const SizedBox(height: 20),
              TextField(
                controller: marksCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Marks Awarded (Max: ${widget.maxMarks})',
                  prefixIcon: const Icon(Icons.star_rounded, color: AppTheme.accent),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Feedback / Remarks',
                  prefixIcon: Icon(Icons.comment_rounded, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final m = double.tryParse(marksCtrl.text);
                if (m == null || m > widget.maxMarks) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Marks!')));
                  return;
                }
                setLocalState(() => isSaving = true);
                await AssignmentService().gradeSubmission(
                  submissionId: widget.submission.id,
                  marks: m,
                  feedback: feedbackCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  widget.onGraded();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGraded = widget.submission.status == AssignmentStatus.graded;

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
                decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(widget.studentName[0].toUpperCase(), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w900, fontSize: 18))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.studentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                    Text(isGraded ? 'Status: Evaluated ✅' : 'Status: Pending Review ⏳', 
                      style: TextStyle(fontSize: 10, color: isGraded ? AppTheme.success : AppTheme.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (isGraded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.submission.marks}/${widget.maxMarks}', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          if (widget.submission.fileUrl != null) ...[
            Builder(
              builder: (context) {
                final isImage = ['jpg', 'jpeg', 'png', 'webp'].any((ext) => widget.submission.fileUrl!.toLowerCase().contains(ext));
                return InkWell(
                  onTap: _openFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isImage ? AppTheme.secondary.withOpacity(0.05) : AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                              color: isImage ? AppTheme.secondary : AppTheme.danger,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Evidence of Work', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textPrimary)),
                                  Text('Click to inspect full asset', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded, size: 16, color: AppTheme.textHint),
                          ],
                        ),
                        if (isImage) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.submission.fileUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
          ],
          Text(
            widget.submission.content ?? '[No textual log transmitted]', 
            maxLines: 3, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          // AI Scan Buttons
          if (_aiResult == null) ...[
            Row(
              children: [
                // Text AI Scan
                if (widget.submission.content != null && widget.submission.content!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : _checkOriginality,
                      icon: _isChecking 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.text_snippet_rounded, size: 16),
                      label: const Text('Scan Text', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        side: const BorderSide(color: AppTheme.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (widget.submission.content != null && widget.submission.content!.isNotEmpty && 
                    widget.submission.fileUrl != null)
                  const SizedBox(width: 8),
                // Image AI Scan
                if (widget.submission.fileUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : _scanImageWithAI,
                      icon: _isChecking 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.document_scanner_rounded, size: 16),
                      label: const Text('Scan Image', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_aiResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _buildRiskBadge(_aiResult!['ai_probability'] ?? _aiResult!['confidence']),
                  const SizedBox(width: 8),
                  if (_aiResult!['score'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Score: ${_aiResult!['score']}/${_aiResult!['max_score'] ?? widget.maxMarks}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _aiResult = null),
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Rescan',
                  ),
                ],
              ),
            ),
          
          // Action Buttons Row
          Row(
            children: [
              // Allow Resubmission (only if graded)
              if (isGraded && !widget.submission.resubmissionAllowed)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showResubmissionDialog,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Allow Resubmit', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: const BorderSide(color: AppTheme.warning),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (isGraded && !widget.submission.resubmissionAllowed)
                const SizedBox(width: 8),
              // Resubmission pending badge
              if (widget.submission.resubmissionAllowed)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Resubmit Allowed',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.submission.resubmissionAllowed)
                const SizedBox(width: 8),
              // Grade Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _showGradeDialog,
                  icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                  label: Text(
                    isGraded ? 'Re-Evaluate' : 'Grade Mission', 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          if (_aiResult != null && _aiResult!['analysis'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Analysis:',
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _aiResult!['analysis'], 
                    style: const TextStyle(
                      fontSize: 11, 
                      color: AppTheme.textSecondary, 
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  if (_aiResult!['suggestions'] != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Suggestions:',
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _aiResult!['suggestions'], 
                      style: const TextStyle(
                        fontSize: 11, 
                        color: AppTheme.warning, 
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskBadge(dynamic prob) {
    final double p = (prob is int) ? prob.toDouble() : (prob as double);
    final isHigh = p > 0.7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh ? AppTheme.danger.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('AI: ${(p * 100).toStringAsFixed(0)}%', style: TextStyle(color: isHigh ? AppTheme.danger : Colors.green, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}
