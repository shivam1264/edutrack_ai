import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../utils/app_theme.dart';
import 'submission_list_screen.dart';
import 'create_assignment_screen.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  final String classId;
  const TeacherAssignmentsScreen({super.key, required this.classId});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AssignmentService _service = AssignmentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Assignments', style: TextStyle(fontWeight: FontWeight.w900)),
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
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'All Assignments'),
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentList('all'),
          _buildAssignmentList('pending'),
          _buildAssignmentList('submitted'),
          _buildAssignmentList('graded'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen(classId: widget.classId))),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAssignmentList(String filter) {
    return StreamBuilder<List<AssignmentModel>>(
      stream: _service.streamAssignmentsByClass(widget.classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No assignments found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final a = items[index];
            return _buildAssignmentCard(a);
          },
        );
      },
    );
  }

  Widget _buildAssignmentCard(AssignmentModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(a.subject, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Due: ${a.dueDate.day}/${a.dueDate.month}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('class_id', isEqualTo: widget.classId).where('role', isEqualTo: 'student').snapshots(),
                builder: (context, totalSnap) {
                  final total = totalSnap.data?.docs.length ?? 0;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('submissions').where('assignment_id', isEqualTo: a.id).snapshots(),
                    builder: (context, subSnap) {
                      final submitted = subSnap.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Text('$submitted/$total Submitted', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      );
                    }
                  );
                }
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmissionListScreen(assignment: a))),
                child: const Text('View Submissions', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
