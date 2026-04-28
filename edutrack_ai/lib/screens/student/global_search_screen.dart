import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../assignments/submit_assignment_screen.dart';
import '../quiz/take_quiz_screen.dart';
import '../quiz/quiz_review_screen.dart';
import 'note_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SearchResult> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    final user = context.read<AuthProvider>().user;
    final classId = user?.classId ?? '';
    final studentId = user?.uid ?? '';
    final searchLower = query.toLowerCase();

    List<SearchResult> results = [];

    // Search Assignments
    try {
      final assignments = await AssignmentService().getAssignmentsByClass(classId);
      final submissions = await AssignmentService().getStudentSubmissions(studentId);
      final submissionMap = {for (var sub in submissions) sub.assignmentId: sub};

      for (final assignment in assignments) {
        if (assignment.title.toLowerCase().contains(searchLower) ||
            assignment.description.toLowerCase().contains(searchLower) ||
            assignment.subject.toLowerCase().contains(searchLower) ||
            DateFormat('MMM dd, yyyy').format(assignment.dueDate).toLowerCase().contains(searchLower)) {
          final sub = submissionMap[assignment.id];
          results.add(SearchResult(
            id: assignment.id,
            title: assignment.title,
            subtitle: '${assignment.subject} • Due ${DateFormat('MMM dd').format(assignment.dueDate)}',
            type: SearchType.assignment,
            status: sub?.status == AssignmentStatus.graded ? 'graded'
                : sub != null ? 'submitted'
                : assignment.isOverdue ? 'overdue' : 'pending',
            date: assignment.dueDate,
            data: assignment,
          ));
        }
      }
    } catch (e) {
      debugPrint('Assignment search error: $e');
    }

    // Search Quizzes
    try {
      final quizzes = await QuizService().getQuizzesByClass(classId);
      final quizResults = await QuizService().getStudentResults(studentId);
      final resultMap = {for (var r in quizResults) r.quizId: r};

      for (final quiz in quizzes) {
        if (quiz.title.toLowerCase().contains(searchLower) ||
            quiz.subject.toLowerCase().contains(searchLower) ||
            DateFormat('MMM dd, yyyy').format(quiz.startTime).toLowerCase().contains(searchLower)) {
          final hasTaken = resultMap.containsKey(quiz.id);
          results.add(SearchResult(
            id: quiz.id,
            title: quiz.title,
            subtitle: '${quiz.subject} • ${DateFormat('MMM dd, hh:mm a').format(quiz.startTime)}',
            type: SearchType.quiz,
            status: hasTaken ? 'completed'
                : quiz.isActive ? 'active'
                : quiz.isUpcoming ? 'upcoming' : 'expired',
            date: quiz.startTime,
            data: quiz,
          ));
        }
      }
    } catch (e) {
      debugPrint('Quiz search error: $e');
    }

    // Search Notes
    try {
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('class_id', isEqualTo: classId)
          .get();

      for (final doc in notesSnapshot.docs) {
        final note = NoteModel.fromMap(doc.id, doc.data());
        if (note.title.toLowerCase().contains(searchLower) ||
            note.content.toLowerCase().contains(searchLower) ||
            note.subject.toLowerCase().contains(searchLower) ||
            DateFormat('MMM dd, yyyy').format(note.createdAt).toLowerCase().contains(searchLower)) {
          results.add(SearchResult(
            id: note.id,
            title: note.title,
            subtitle: '${note.subject} • Added ${DateFormat('MMM dd').format(note.createdAt)}',
            type: SearchType.notes,
            status: 'available',
            date: note.createdAt,
            data: note,
          ));
        }
      }
    } catch (e) {
      debugPrint('Notes search error: $e');
    }

    // Sort by date (newest first)
    results.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search assignments, quizzes, notes...',
                hintStyle: TextStyle(color: AppTheme.textHint),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textHint),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
            ),
          ),

          // Category Filter Chips
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${_results.length})',
                    isSelected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Assignments (${_results.where((r) => r.type == SearchType.assignment).length})',
                    isSelected: false,
                    color: Colors.red,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Quizzes (${_results.where((r) => r.type == SearchType.quiz).length})',
                    isSelected: false,
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Notes (${_results.where((r) => r.type == SearchType.notes).length})',
                    isSelected: false,
                    color: Colors.green,
                    onTap: () {},
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 80,
                              color: AppTheme.textHint.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search for assignments, quizzes, or notes',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching by title, subject, or date',
                              style: TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: AppTheme.textHint.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results for "$_searchQuery"',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final result = _results[index];
                              return _buildResultCard(result);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchResult result) {
    IconData icon;
    Color color;

    switch (result.type) {
      case SearchType.assignment:
        icon = Icons.assignment;
        color = Colors.red;
        break;
      case SearchType.quiz:
        icon = Icons.quiz;
        color = Colors.blue;
        break;
      case SearchType.notes:
        icon = Icons.note;
        color = Colors.green;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => _openResult(result),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(result.status, color),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color typeColor) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'graded':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Graded';
        break;
      case 'submitted':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Submitted';
        break;
      case 'pending':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        label = 'Pending';
        break;
      case 'overdue':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Overdue';
        break;
      case 'active':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'LIVE';
        break;
      case 'upcoming':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Upcoming';
        break;
      case 'completed':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Completed';
        break;
      case 'expired':
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = 'Expired';
        break;
      default:
        bgColor = typeColor.withOpacity(0.1);
        textColor = typeColor;
        label = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _openResult(SearchResult result) async {
    switch (result.type) {
      case SearchType.assignment:
        final assignment = result.data as AssignmentModel;
        final submissions = await AssignmentService().getStudentSubmissions(
          context.read<AuthProvider>().user?.uid ?? '',
        );
        final submission = submissions.firstWhere(
          (s) => s.assignmentId == assignment.id,
          orElse: () => SubmissionModel(
            id: '',
            assignmentId: '',
            studentId: '',
            submittedAt: DateTime.now(),
            status: AssignmentStatus.pending,
          ),
        );
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmitAssignmentScreen(
              assignment: assignment,
              existingSubmission: submission.id.isNotEmpty ? submission : null,
            ),
          ),
        );
        break;

      case SearchType.quiz:
        final quiz = result.data as QuizModel;
        final userId = context.read<AuthProvider>().user?.uid ?? '';
        final quizResult = await QuizService().getStudentResult(
          quizId: quiz.id,
          studentId: userId,
        );
        
        if (!mounted) return;
        
        if (quizResult != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizReviewScreen(quiz: quiz, result: quizResult),
            ),
          );
        } else if (quiz.isActive) {
          final taken = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: quiz)),
          );
          if (taken == true) {
            _performSearch(_searchQuery);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quiz.isUpcoming ? 'Quiz has not started yet.' : 'Quiz has ended.'),
              backgroundColor: quiz.isUpcoming ? AppTheme.accent : AppTheme.danger,
            ),
          );
        }
        break;

      case SearchType.notes:
        final note = result.data as NoteModel;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
        );
        break;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppTheme.primary) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? AppTheme.primary) : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

enum SearchType { assignment, quiz, notes }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchType type;
  final String status;
  final DateTime date;
  final dynamic data;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.date,
    required this.data,
  });
}
