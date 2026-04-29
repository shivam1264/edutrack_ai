import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/theme_provider.dart';
import 'package:edutrack_ai/widgets/glass_card.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildListTile(context, Icons.person_outline_rounded, l10n.personalInformation, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.settings_suggest_rounded, l10n.accountSettings, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.auto_stories_rounded, l10n.studyPreferences, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPreferencesScreen()));
                }),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.app_settings_alt_rounded, l10n.appSettings, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
                }),
                _buildThemeTile(context),
                const SizedBox(height: 12),
                _buildListTile(context, Icons.help_center_rounded, l10n.helpSupport, () {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.profileCenter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
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
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                      ? Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                          style: const TextStyle(color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w900),
                        )
                      : null,
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
                        stream: (user?.classId != null && user!.classId.isNotEmpty)
                            ? FirebaseFirestore.instance.collection('classes').doc(user.classId).snapshots()
                            : null,
                        builder: (context, snapshot) {
                          final classData = snapshot.data?.data() as Map<String, dynamic>?;
                          String className = 'Loading...';
                          if (classData != null) {
                            final standard = classData['standard'] ?? '';
                            final section = classData['section'] ?? '';
                            className = section.isNotEmpty ? '$standard - $section' : standard;
                          } else if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && !snapshot.hasData)) {
                            className = user?.classId ?? "N/A";
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
                          child: Text(AppLocalizations.of(context)!.editProfile, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
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

  Widget _buildThemeTile(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    return _buildListTile(
      context, 
      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
      "Appearance: ${isDark ? 'Dark' : 'Light'}", 
      () => themeProvider.toggleTheme(),
      trailing: Switch(
        value: isDark,
        onChanged: (_) => themeProvider.toggleTheme(),
        activeColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderLight),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.bgLight, 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 15, 
            color: isDark ? Colors.white : AppTheme.textPrimary
          )
        ),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : AppTheme.textHint),
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
        title: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
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
