import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
import 'create_quiz_screen.dart';
import 'quiz_results_list_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherQuizzesScreen extends StatefulWidget {
  final String classId;
  const TeacherQuizzesScreen({super.key, required this.classId});

  @override
  State<TeacherQuizzesScreen> createState() => _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends State<TeacherQuizzesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QuizService _service = QuizService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Quizzes', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizList('active'),
          _buildQuizList('upcoming'),
          _buildQuizList('expired'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizScreen(classId: widget.classId)));
          if (result == true) setState(() {});
        },
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildQuizList(String filter) {
    return FutureBuilder<List<QuizModel>>(
      future: _service.getQuizzesByClass(widget.classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snapshot.data ?? [];
        
        // Filter based on status
        if (filter == 'active') items = items.where((q) => q.isActive).toList();
        else if (filter == 'upcoming') items = items.where((q) => q.isUpcoming).toList();
        else if (filter == 'expired') items = items.where((q) => q.isExpired).toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 60, color: AppTheme.textHint.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No $filter quizzes found.', style: const TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final q = items[index];
            return _buildQuizCard(q).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
          },
        );
      },
    );
  }

  Widget _buildQuizCard(QuizModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (q.isActive ? const Color(0xFF059669) : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bolt_rounded, color: q.isActive ? const Color(0xFF059669) : Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                    Text(q.subject, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${q.questions.length} Qs', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textHint)),
                  const SizedBox(height: 4),
                  _buildStatusBadge(q),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<List<QuizResultModel>>(
                future: _service.getQuizResults(q.id),
                builder: (context, resSnap) {
                  final count = resSnap.data?.length ?? 0;
                  return Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 6),
                      Text('$count Submissions', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w800)),
                    ],
                  );
                }
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizResultsListScreen(quiz: q))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                  foregroundColor: const Color(0xFF059669),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Results', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(QuizModel q) {
    if (q.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green)),
      );
    } else if (q.isUpcoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Text('UPCOMING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppTheme.textHint.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Text('EXPIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textHint)),
      );
    }
  }
}
