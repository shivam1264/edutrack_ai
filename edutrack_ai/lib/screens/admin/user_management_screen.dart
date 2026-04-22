import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../models/class_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
          // Search Bar
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
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
                Text('No ${role}s found', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
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
            
            return PremiumCard(
              opacity: 1,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role).withOpacity(0.1),
                  child: Text(data['name']?[0].toUpperCase() ?? '?', style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold)),
                ),
                title: Text(data['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                subtitle: Text('ID: ${doc.id.substring(0, 8)}...', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (role == 'teacher')
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: AppTheme.secondary, size: 22),
                        onPressed: () => _editFacultyProfile(doc.id, data),
                        tooltip: 'Edit Subjects/Classes',
                      ),
                    IconButton(
                      icon: const Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 20),
                      onPressed: () => _changeRoleDialog(doc.id, role),
                      tooltip: 'Change Role',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
                      onPressed: () => _confirmDelete(doc.id, data['name'] ?? 'this user'),
                      tooltip: 'Delete User',
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

  Color _getRoleColor(String role) {
    if (role == 'teacher') return AppTheme.secondary;
    if (role == 'parent') return AppTheme.accent;
    return AppTheme.primary;
  }

  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove $name? This action will wipe their Firestore record and block access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().deleteUserRecord(uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name removed successfully'), backgroundColor: AppTheme.danger),
                );
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _changeRoleDialog(String uid, String currentRole) {
    final roles = ['admin', 'teacher', 'student', 'parent'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modify Permissions', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) => RadioListTile<String>(
            title: Text(role.toUpperCase()),
            value: role,
            groupValue: currentRole,
            onChanged: (val) {
              if (val != null) {
                FirebaseFirestore.instance.collection('users').doc(uid).update({'role': val});
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _editFacultyProfile(String uid, Map<String, dynamic> data) {
    List<String> assignedClasses = List<String>.from(data['assigned_classes'] ?? []);
    List<String> subjects = List<String>.from(data['subjects'] ?? []);
    final masterSubjects = [
      'Mathematics', 'Science', 'English', 'Hindi', 
      'Social Studies', 'Computer Science', 'Physics', 
      'Chemistry', 'Biology', 'History', 'Geography', 'Economics'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Edit ${data['name']}', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ASSIGNED CLASSES', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ClassModel>>(
                    stream: ClassService().getClasses(),
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];
                      return Wrap(
                        spacing: 6, runSpacing: 6,
                        children: classes.map((c) {
                          final isSelected = assignedClasses.contains(c.displayName);
                          return FilterChip(
                            label: Text(c.displayName, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                            selected: isSelected,
                            onSelected: (val) => setLocalState(() => val ? assignedClasses.add(c.displayName) : assignedClasses.remove(c.displayName)),
                            selectedColor: AppTheme.primary,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('ASSIGNED SUBJECTS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: masterSubjects.map((s) {
                      final isSelected = subjects.contains(s);
                      return FilterChip(
                        label: Text(s, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                        selected: isSelected,
                        onSelected: (val) => setLocalState(() => val ? subjects.add(s) : subjects.remove(s)),
                        selectedColor: AppTheme.secondary,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'assigned_classes': assignedClasses,
                  'subjects': subjects,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
