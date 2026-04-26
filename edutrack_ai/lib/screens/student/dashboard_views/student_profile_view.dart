import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/screens/settings/profile_screen.dart';
import 'package:edutrack_ai/screens/student/study_preferences_screen.dart';
import 'package:edutrack_ai/screens/settings/app_settings_screen.dart';
import 'package:edutrack_ai/screens/settings/help_support_screen.dart';
import 'package:edutrack_ai/screens/settings/account_settings_screen.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildListTile(context, Icons.person_outline_rounded, 'Personal Information', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.settings_suggest_rounded, 'Account Settings', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.auto_stories_rounded, 'Study Preferences', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPreferencesScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.app_settings_alt_rounded, 'App Settings', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.help_center_rounded, 'Help & Support', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                }),
                const SizedBox(height: 12),
                _buildLogoutTile(context),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        decoration: const BoxDecoration(
          color: AppTheme.primaryDark,
          gradient: AppTheme.studentGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Profile Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Student Name',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('classes').doc(user?.classId ?? '').snapshots(),
                        builder: (context, snapshot) {
                          final classData = snapshot.data?.data() as Map<String, dynamic>?;
                          String className = user?.classId ?? "N/A";
                          if (classData != null) {
                            final standard = classData['standard'] ?? '';
                            final section = classData['section'] ?? '';
                            className = section.isNotEmpty ? '$standard - $section' : standard;
                          }
                          return Text(
                            'Class $className • ID: ${user?.schoolId ?? "---"}',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                          ),
                          child: const Text('Edit Profile', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
        ),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Logout Profile?'),
              content: const Text('Are you sure you want to sign out from EduTrack AI?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthProvider>().logout();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
