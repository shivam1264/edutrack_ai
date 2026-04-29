import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/screens/parent/parent_chat_screen.dart';

class ParentChildView extends StatelessWidget {
  const ParentChildView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final analytics = context.watch<AnalyticsProvider>();
    
    final childId = analytics.selectedStudentId ?? 
        ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    if (childId.isEmpty) return const Scaffold(body: Center(child: Text('No student linked')));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(childId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final studentData = snapshot.data!.data() as Map<String, dynamic>;
        final name = studentData['name'] ?? 'Unknown';
        final rollNo = studentData['roll_no'] ?? 'N/A';
        final classId = studentData['class_id'] ?? '';
        final avatarUrl = studentData['avatar_url'] ?? studentData['avatarUrl'];
        final schoolLabel =
            studentData['school_name'] ??
            studentData['school_id'] ??
            'School not listed';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Student Information', style: TextStyle(fontWeight: FontWeight.w900)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              _buildProfileHeader(name, rollNo, classId, avatarUrl, schoolLabel),
              Expanded(child: _buildOverviewTab(studentData, childId)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildProfileHeader(
    String name,
    String rollNo,
    String classId,
    String? avatarUrl,
    String schoolLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('classes').doc(classId).snapshots(),
                  builder: (context, classSnap) {
                    final cData = classSnap.data?.data() as Map<String, dynamic>?;
                    String cName = 'Loading...';
                    if (cData != null) {
                      final standard = cData['standard'] ?? '';
                      final section = cData['section'] ?? '';
                      cName = section.isNotEmpty ? '$standard - $section' : standard;
                    }
                    return Text('Grade $cName • Roll No. $rollNo', style: const TextStyle(color: Colors.grey, fontSize: 14));
                  },
                ),
                Text(
                  schoolLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data, String studentId) {
    final name = data['name'] ?? 'Student';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile('Date of Birth', data['dob'] ?? 'N/A'),
              const SizedBox(width: 24),
              _infoTile('Blood Group', data['blood_group'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 20),
          _infoTile(
            'School',
            data['school_name'] ?? data['school_id'] ?? 'School not listed',
          ),
          const SizedBox(height: 32),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').doc(data['class_id']).snapshots(),
            builder: (context, classSnap) {
              final classData = classSnap.data?.data() as Map<String, dynamic>?;
              final teacherName =
                  classData?['class_teacher_name'] ??
                  classData?['teacher_name'] ??
                  'Not Assigned';
              
              return PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFF97316), child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class Teacher', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFF97316)), 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentChatScreen(studentId: studentId))),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

}
