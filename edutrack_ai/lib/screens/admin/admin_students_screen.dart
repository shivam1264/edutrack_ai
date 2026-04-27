import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_student_screen.dart';
import 'admin_student_detail_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

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
        title: const Text('Students', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentList('all'),
                _buildStudentList('active'),
                _buildStudentList('inactive'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddStudentScreen())),
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: const InputDecoration(
            hintText: 'Search students...',
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF0F172A),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF0F172A),
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'Active'),
        Tab(text: 'Inactive'),
      ],
    );
  }

  Widget _buildStudentList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildStudentTile(data, index, doc.id);
          },
        );
      },
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> data, int index, String studentId) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminStudentDetailScreen(studentData: data, studentId: studentId))),
      child: PremiumCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(data['name']?[0].toUpperCase() ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('Class ${data['class_id'] ?? "N/A"} • Roll No. ${data['roll_no'] ?? "N/A"}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
    );
  }
}
