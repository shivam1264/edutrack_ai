import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizResultsListScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizResultsListScreen({super.key, required this.quiz});

  @override
  State<QuizResultsListScreen> createState() => _QuizResultsListScreenState();
}

class _QuizResultsListScreenState extends State<QuizResultsListScreen> {
  final QuizService _service = QuizService();
  bool _isLoading = true;
  List<QuizResultModel> _results = [];
  final Map<String, String> _studentNames = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final list = await _service.getQuizResults(widget.quiz.id);
    
    for (var res in list) {
      if (!_studentNames.containsKey(res.studentId)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(res.studentId).get();
        if (userDoc.exists) {
          _studentNames[res.studentId] = userDoc.data()?['name'] ?? 'Incomplete Profile';
        } else {
          _studentNames[res.studentId] = 'Unknown Student';
        }
      }
    }

    if (mounted) {
      setState(() {
        _results = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double avgScore = 0;
    if (_results.isNotEmpty) {
      avgScore = _results.map((r) => r.score).reduce((a, b) => a + b) / _results.length;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF34D399)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.analytics_rounded, color: Colors.white.withOpacity(0.1), size: 220),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.quiz.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statChip(Icons.people_alt_rounded, '${_results.length} Attempts'),
                            const SizedBox(width: 12),
                            _statChip(Icons.assessment_rounded, 'Avg: ${avgScore.toStringAsFixed(1)}/${widget.quiz.totalMarks}'),
                          ],
                        ),
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
                : _results.isEmpty
                    ? _buildEmpty()
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final res = _results[index];
                            final studentName = _studentNames[res.studentId] ?? 'Resolving...';
                            return _ResultListItem(result: res, studentName: studentName, quiz: widget.quiz)
                                .animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
                          },
                          childCount: _results.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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
            Icon(Icons.history_rounded, size: 80, color: AppTheme.textHint.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No results yet.', style: TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.w900)),
            const Text('Students haven\'t taken this quiz yet.', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ResultListItem extends StatelessWidget {
  final QuizResultModel result;
  final String studentName;
  final QuizModel quiz;

  const _ResultListItem({required this.result, required this.studentName, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final bool isExcellent = result.percentage >= 80;
    final bool isWeak = result.percentage < 40;

    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (isExcellent ? Colors.green : (isWeak ? Colors.red : Colors.orange)).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                studentName[0].toUpperCase(),
                style: TextStyle(
                  color: isExcellent ? Colors.green : (isWeak ? Colors.red : Colors.orange),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary)),
                Text('Submitted ${timeAgo(result.submittedAt)}', style: const TextStyle(fontSize: 10, color: AppTheme.textHint, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${result.score.toStringAsFixed(0)}/${quiz.totalMarks.toStringAsFixed(0)}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isExcellent ? Colors.green : (isWeak ? Colors.red : Colors.orange)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${result.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isExcellent ? Colors.green : (isWeak ? Colors.red : Colors.orange),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
        ],
      ),
    );
  }

  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
