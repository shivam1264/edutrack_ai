import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_theme.dart';
import '../../../providers/analytics_provider.dart';
import '../../admin/add_user_screen.dart';
import '../individual_student_analytics_screen.dart';

class TeacherStudentsView extends StatefulWidget {
  final String? selectedClassId;

  const TeacherStudentsView({super.key, required this.selectedClassId});

  @override
  State<TeacherStudentsView> createState() => _TeacherStudentsViewState();
}

class _TeacherStudentsViewState extends State<TeacherStudentsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Students', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => _searchFocus.requestFocus()),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentList('all'),
                  _buildStudentList('top'),
                  _buildStudentList('needs_attention'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.selectedClassId != null 
        ? FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddUserScreen(fixedRole: 'student', fixedClassId: widget.selectedClassId)));
            },
            backgroundColor: AppTheme.secondary,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search_rounded, color: AppTheme.textHint),
                  hintText: 'Search students...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final next = (_tabController.index + 1) % _tabController.length;
              _tabController.animateTo(next);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Icon(Icons.tune_rounded, color: AppTheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final analytics = context.watch<AnalyticsProvider>().classAnalytics;
    final allCount = (analytics?['students'] as List?)?.length ?? 0;
    final topCount = (analytics?['top5'] as List?)?.length ?? 0;
    final bottomCount = (analytics?['bottom5'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textHint,
        indicator: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(
            child: Container(
              alignment: Alignment.center,
              child: const Text('All'),
            ),
          ),
          Tab(
            child: Container(
              alignment: Alignment.center,
              child: const Text('Top'),
            ),
          ),
          Tab(
            child: Container(
              alignment: Alignment.center,
              child: const Text('Attention'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(String filter) {
    final analytics = context.watch<AnalyticsProvider>().classAnalytics;
    final isLoading = context.watch<AnalyticsProvider>().isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.selectedClassId == null || analytics == null) {
      return const Center(child: Text('Select a class to view students.'));
    }

    List<Map<String, dynamic>> students = [];
    if (filter == 'all') {
      students = List<Map<String, dynamic>>.from(analytics['students'] ?? []);
    } else if (filter == 'top') {
      students = List<Map<String, dynamic>>.from(analytics['top5'] ?? []);
    } else if (filter == 'needs_attention') {
      students = List<Map<String, dynamic>>.from(analytics['bottom5'] ?? []);
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      students = students.where((s) {
        final name = s['name']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery);
      }).toList();
    }

    if (students.isEmpty) {
      return const Center(child: Text('No students found in this category.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final name = s['name'] ?? 'Unknown';
        final uid = s['uid'] ?? '';
        final rollNo = s['roll_no'] ?? 'N/A';
        final avgScore = (s['avg_score'] as num? ?? 0.0).toDouble();
        
        return _buildStudentCard(name, 'Roll No: $rollNo', avgScore.toInt(), uid);
      },
    );
  }

  Widget _buildStudentCard(String name, String rollNo, int percent, String uid) {
    final status = percent >= 80 ? 'Excellent' : (percent >= 60 ? 'Good' : 'Needs Help');
    final color = percent >= 80 ? Colors.green : (percent >= 40 ? Colors.blue : Colors.red);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IndividualStudentAnalyticsScreen(studentId: uid, studentName: name),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(rollNo, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$percent%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
                Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
