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
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Access Control Hub', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
               showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    const Text('FILTER BY STATUS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.all_inclusive_rounded, color: AppTheme.primary),
                      title: const Text('Show All Status', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      onTap: () { setState(() => _statusFilter = 'all'); Navigator.pop(context); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                      title: const Text('Active Users Only', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      onTap: () { setState(() => _statusFilter = 'active'); Navigator.pop(context); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.pause_circle_rounded, color: Colors.orange),
                      title: const Text('Inactive Users Only', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      onTap: () { setState(() => _statusFilter = 'inactive'); Navigator.pop(context); },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(text: 'STUDENTS'),
            Tab(text: 'TEACHERS'),
            Tab(text: 'PARENTS'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF0F172A)),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
                Icon(Icons.person_off_rounded, size: 64, color: const Color(0xFF64748B).withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('No users matching filters', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: () => _navigateToDetail(doc.id, data, role),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getRoleColor(role).withOpacity(0.8),
                        _getRoleColor(role),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: _getRoleColor(role).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      data['name']?[0].toUpperCase() ?? '?', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)
                    ),
                  ),
                ),
                title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? "ACTIVE" : "SUSPENDED",
                          style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(doc.id, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), overflow: TextOverflow.ellipsis)),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                        onPressed: () => _editUserDialog(doc.id, data, role),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        onPressed: () => _confirmDelete(doc.id, data['name'] ?? 'User'),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
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
          title: Text('Modify ${role.toUpperCase()} Details', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                  const Text('MODIFY SUBJECTS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 10, letterSpacing: 1.2)),
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
                            onSelected: (val) {
                              setLocalState(() {
                                if (role == 'student') {
                                  // Students usually belong to one class
                                  selectedClasses.clear();
                                  if (val) selectedClasses.add(c.id);
                                } else {
                                  val ? selectedClasses.add(c.id) : selectedClasses.remove(c.id);
                                }
                              });
                            },
                            selectedColor: AppTheme.primary,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
                if (role == 'student') ...[
                  const SizedBox(height: 24),
                  const Text('ASSIGN ACADEMIC CLASS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ClassModel>>(
                    stream: ClassService().getClasses(),
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        value: selectedClasses.isNotEmpty ? selectedClasses.first : null,
                        decoration: InputDecoration(
                          hintText: 'Select Class',
                          filled: true, fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                        ),
                        items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))).toList(),
                        onChanged: (v) => setLocalState(() => selectedClasses = v != null ? [v] : []),
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
                } else if (role == 'student') {
                  updateData['class_id'] = selectedClasses.isNotEmpty ? selectedClasses.first : null;
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
