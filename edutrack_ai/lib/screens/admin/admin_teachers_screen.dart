import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_teacher_screen.dart';

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Teachers', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _tabController.animateTo((_tabController.index + 1) % _tabController.length),
          ),
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
                _buildTeacherList('all'),
                _buildTeacherList('active'),
                _buildTeacherList('inactive'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTeacherScreen())),
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
            hintText: 'Search teachers...',
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

  Widget _buildTeacherList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final itemStatus = _statusOf(data);
          final matchesStatus = status == 'all' || itemStatus == status;
          return matchesStatus && name.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTeacherTile(data, index);
          },
        );
      },
    );
  }

  Widget _buildTeacherTile(Map<String, dynamic> data, int index) {
    final subjects = List<String>.from(data['subjects'] ?? []);
    final status = _statusOf(data);
    final isActive = status == 'active';
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.secondary.withOpacity(0.1),
            child: Text(data['name']?[0].toUpperCase() ?? 'T', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                Text(subjects.isNotEmpty ? subjects.join(', ') : 'No subjects assigned', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(status.toUpperCase(), style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }

  String _statusOf(Map<String, dynamic> data) {
    final raw = data['status']?.toString().toLowerCase();
    if (raw == 'inactive' || raw == 'disabled' || raw == 'archived') return 'inactive';
    return 'active';
  }
}
