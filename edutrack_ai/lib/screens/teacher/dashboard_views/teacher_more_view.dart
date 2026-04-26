import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_theme.dart';
import '../../settings/profile_screen.dart';

class TeacherMoreView extends StatelessWidget {
  const TeacherMoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: 32),
          _buildSection('Account', [
            _buildMenuItem(Icons.person_outline_rounded, 'Profile Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _buildMenuItem(Icons.school_outlined, 'Class & Subject', () {}),
            _buildMenuItem(Icons.notifications_none_rounded, 'Notification Settings', () {}),
          ]),
          const SizedBox(height: 24),
          _buildSection('Support', [
            _buildMenuItem(Icons.help_outline_rounded, 'Help & Support', () {}),
            _buildMenuItem(Icons.feedback_outlined, 'Feedback', () {}),
          ]),
          const SizedBox(height: 24),
          _buildSection('Other', [
            _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
            _buildMenuItem(Icons.logout_rounded, 'Logout', () => _showLogoutDialog(context), isDestructive: true),
          ]),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.secondary.withOpacity(0.1),
            backgroundImage: user?.avatarUrl != null ? CachedNetworkImageProvider(user!.avatarUrl!) : null,
            child: user?.avatarUrl == null
                ? Text(user?.name[0].toUpperCase() ?? 'T', style: const TextStyle(color: AppTheme.secondary, fontSize: 24, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Alex Johnson', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('Science Teacher', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textHint, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.red : AppTheme.textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
