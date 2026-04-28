import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/screens/parent/views/parent_child_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_insights_view.dart';
import 'package:edutrack_ai/screens/settings/profile_screen.dart';
import 'package:edutrack_ai/screens/settings/account_settings_screen.dart';
import 'package:edutrack_ai/screens/settings/app_settings_screen.dart';
import 'package:edutrack_ai/screens/settings/help_support_screen.dart';

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
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.parentColor, width: 2)),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: (parent?.avatarUrl != null && parent!.avatarUrl!.isNotEmpty) 
                              ? NetworkImage(parent!.avatarUrl!) 
                              : null,
                          child: (parent?.avatarUrl == null || parent!.avatarUrl!.isEmpty) 
                              ? const Icon(Icons.person_rounded, size: 50, color: Colors.grey) 
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppTheme.parentColor, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(parent?.name ?? 'Guardian', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(parent?.email ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.parentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              borderRadius: BorderRadius.circular(16),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoTile('Guardian Name', parent?.name ?? 'Guardian', bottomPadding: 16),
                    _infoTile('Email Address', parent?.email ?? 'N/A', bottomPadding: 16),
                    _infoTile('Phone Number', parent?.phone ?? 'N/A', bottomPadding: 16),
                    _infoTile('Relationship', parent?.relationship ?? 'Guardian', bottomPadding: 16),
                    _infoTile('Home Address', parent?.address ?? 'No Address Provided', bottomPadding: 0),
                    const Divider(height: 32),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, color: AppTheme.parentColor, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Profile Information', style: TextStyle(color: AppTheme.parentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _infoTile(String label, String value, {double bottomPadding = 20}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)))),
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
