import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../models/class_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_student_detail_screen.dart';
import 'admin_teacher_detail_screen.dart';
import 'admin_parent_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  final List<String> _subjectsList = [
    'Mathematics', 'Science', 'English', 'Hindi', 'History', 'Physics', 
    'Chemistry', 'Biology', 'Social Studies', 'Computer Science', 'Economics', 'Geography'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Access Control Hub', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) => setState(() => _statusFilter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Show All Status')),
              const PopupMenuItem(value: 'active', child: Text('Active Only')),
              const PopupMenuItem(value: 'inactive', child: Text('Inactive Only')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'STUDENTS', icon: Icon(Icons.people_alt_rounded, size: 20)),
            Tab(text: 'TEACHERS', icon: Icon(Icons.school_rounded, size: 20)),
            Tab(text: 'PARENTS', icon: Icon(Icons.family_restroom_rounded, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('student'),
                _buildUserList('teacher'),
                _buildUserList('parent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: (() {
        var q = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role);
        if (_statusFilter == 'active') q = q.where('status', isEqualTo: 'active');
        if (_statusFilter == 'inactive') q = q.where('status', isEqualTo: 'inactive');
        return q.snapshots();
      })(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final uid = doc.id.toLowerCase();
          return name.contains(_searchQuery) || uid.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No ${role}s matching filters', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isActive = data['status'] != 'inactive';
            
            return PremiumCard(
              opacity: 1,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              child: ListTile(
                onTap: () => _navigateToDetail(doc.id, data, role),
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role).withOpacity(0.1),
                  child: Text(data['name']?[0].toUpperCase() ?? '?', style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold)),
                ),
                title: Row(
                  children: [
                    Text(data['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle),
                    ),
                  ],
                ),
                subtitle: Text('${isActive ? "Active" : "Suspended"} • ${data['email'] ?? "No Email"}', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                      onPressed: () => _editUserDialog(doc.id, data, role),
                      tooltip: 'Quick Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.danger, size: 20),
                      onPressed: () => _confirmDelete(doc.id, data['name'] ?? 'User'),
                      tooltip: 'Permanent Delete',
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
          },
        );
      },
    );
  }

  void _navigateToDetail(String uid, Map<String, dynamic> data, String role) {
    Widget target;
    if (role == 'student') {
      target = AdminStudentDetailScreen(studentId: uid, studentData: data);
    } else if (role == 'teacher') {
      target = AdminTeacherDetailScreen(teacherId: uid, teacherData: data);
    } else {
      target = AdminParentDetailScreen(parentId: uid, parentData: data);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  void _editUserDialog(String uid, Map<String, dynamic> data, String role) {
    final nameCtrl = TextEditingController(text: data['name']);
    final emailCtrl = TextEditingController(text: data['email']);
    List<String> selectedSubjects = List<String>.from(data['subjects'] ?? []);
    List<String> selectedClasses = List<String>.from(data['assigned_classes'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Modify ${role.toUpperCase()} Details', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Display Name', icon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address', icon: Icon(Icons.email_rounded)),
                ),
                
                if (role == 'teacher') ...[
                  const SizedBox(height: 24),
                  const Text('MODIFY SUBJECTS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _subjectsList.map((s) {
                      final isSelected = selectedSubjects.contains(s);
                      return FilterChip(
                        label: Text(s, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                        selected: isSelected,
                        onSelected: (val) => setLocalState(() => val ? selectedSubjects.add(s) : selectedSubjects.remove(s)),
                        selectedColor: Colors.blueAccent,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('MODIFY CLASSES', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ClassModel>>(
                    stream: ClassService().getClasses(),
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];
                      return Wrap(
                        spacing: 6, runSpacing: 6,
                        children: classes.map((c) {
                          final isSelected = selectedClasses.contains(c.id);
                          return FilterChip(
                            label: Text(c.displayName, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                            selected: isSelected,
                            onSelected: (val) => setLocalState(() => val ? selectedClasses.add(c.id) : selectedClasses.remove(c.id)),
                            selectedColor: AppTheme.primary,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final Map<String, dynamic> updateData = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                };
                if (role == 'teacher') {
                  updateData['subjects'] = selectedSubjects;
                  updateData['assigned_classes'] = selectedClasses;
                }
                
                await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleStatus(String uid, String? currentStatus) {
    final nextStatus = currentStatus == 'inactive' ? 'active' : 'inactive';
    FirebaseFirestore.instance.collection('users').doc(uid).update({'status': nextStatus});
  }

  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permanent Deletion', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text('Are you sure you want to PERMANENTLY delete $name? This will remove their record from Firebase immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().deleteUserFullAccount(uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name fully removed from system'), backgroundColor: AppTheme.danger),
                );
              }
            },
            child: const Text('Delete from Firebase', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    if (role == 'teacher') return AppTheme.secondary;
    if (role == 'parent') return AppTheme.accent;
    return AppTheme.primary;
  }
}
