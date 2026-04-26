import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_student_detail_screen.dart';

class AdminClassDetailScreen extends StatelessWidget {
  final String classId;
  final String className;

  const AdminClassDetailScreen({super.key, required this.classId, required this.className});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(className, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassInfoCard(),
            const SizedBox(height: 24),
            const Text('Performance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildPerformanceStats(),
            const SizedBox(height: 32),
            const Text('Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildStudentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Class Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoRow('Class Name', className),
          _buildInfoRow('Total Students', '42'),
          _buildInfoRow('Class Teacher', 'Neha Gupta'),
          _buildInfoRow('Room Number', 'Room 101'),
          _buildInfoRow('Status', 'Active', isStatus: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Row(
      children: [
        Expanded(
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Rate', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('92.5%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Average Score', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('78.6%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').where('class_id', isEqualTo: classId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminStudentDetailScreen(studentData: data, studentId: docs[index].id))),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(data['name']?[0].toUpperCase() ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                subtitle: Text('Roll No. ${data['roll_no']} • ID: ${docs[index].id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
