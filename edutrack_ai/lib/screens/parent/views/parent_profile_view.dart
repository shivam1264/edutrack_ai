import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/premium_card.dart';
import '../../../utils/app_theme.dart';

class ParentProfileView extends StatelessWidget {
  const ParentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _infoTile('Parent Name', parent?.name ?? 'John Doe'),
            _infoTile('Email', parent?.email ?? 'john.doe@gmail.com'),
            _infoTile('Phone', '+91 98765 43210'),
            const SizedBox(height: 32),
            const Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _prefItem(Icons.notifications_outlined, 'Notification Settings', null),
            _prefItem(Icons.language_rounded, 'Language', 'English'),
            _prefItem(Icons.privacy_tip_outlined, 'Privacy Policy', null),
            _prefItem(Icons.help_outline_rounded, 'Help & Support', null),
            const SizedBox(height: 40),
            InkWell(
              onTap: () => context.read<AuthProvider>().logout(),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _prefItem(IconData icon, String title, String? trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF64748B), size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
