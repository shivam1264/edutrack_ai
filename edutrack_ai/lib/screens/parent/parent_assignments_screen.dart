import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/assignment_service.dart';
import '../../../models/assignment_model.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAssignmentsScreen extends StatelessWidget {
  const ParentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Assignments', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFFF97316),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF97316),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Submitted'),
                Tab(text: 'Completed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAssignmentList(context, 'pending'),
                  _buildAssignmentList(context, 'submitted'),
                  _buildAssignmentList(context, 'completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentList(BuildContext context, String status) {
    final user = context.watch<AuthProvider>().user;
    final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '';

    if (childId.isEmpty) return const Center(child: Text('No student linked'));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(childId).get(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = studentSnap.data?.data() as Map<String, dynamic>?;
        final classId = data?['class_id'] ?? '';

        if (classId.isEmpty) return const Center(child: Text('Student not assigned to any class'));

        return StreamBuilder<List<AssignmentModel>>(
          stream: AssignmentService().streamAssignmentsByClass(classId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final assignments = snapshot.data ?? [];
            if (assignments.isEmpty) {
              return const Center(child: Text('No assignments found for this class'));
            }

            return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: assignments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final a = assignments[i];
            final color = i % 2 == 0 ? Colors.indigo : Colors.orange;
            
            return PremiumCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.assignment_outlined, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Due: ${DateFormat('dd MMM, yyyy').format(a.dueDate)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'pending' ? Colors.orange.withOpacity(0.1) : (status == 'submitted' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(), 
                      style: TextStyle(
                        color: status == 'pending' ? Colors.orange : (status == 'submitted' ? Colors.blue : Colors.green), 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1);
          },
            );
          },
        );
      },
    );
  }
}
