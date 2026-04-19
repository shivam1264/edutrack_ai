import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('User Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final users = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final role = user['role'] ?? 'student';
                    
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(role).withOpacity(0.1),
                          child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
                        ),
                        title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(role.toUpperCase(), style: TextStyle(fontSize: 12, color: _getRoleColor(role))),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () => _showRoleDialog(context, users[index].id, role),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return AppTheme.danger;
      case 'teacher': return AppTheme.secondary;
      case 'student': return AppTheme.primary;
      case 'parent': return AppTheme.accent;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'teacher': return Icons.school_rounded;
      case 'student': return Icons.person_rounded;
      case 'parent': return Icons.family_restroom_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  void _showRoleDialog(BuildContext context, String uid, String currentRole) {
    final roles = ['admin', 'teacher', 'student', 'parent'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
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
}
