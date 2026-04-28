import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../services/class_service.dart';
import '../../settings/app_settings_screen.dart';
import '../../settings/help_support_screen.dart';
import '../../settings/profile_screen.dart';

class TeacherMoreView extends StatelessWidget {
  const TeacherMoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.more, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: 32),
          _buildSection(AppLocalizations.of(context)!.account, [
            _buildMenuItem(Icons.person_outline_rounded, AppLocalizations.of(context)!.profileSettings, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _buildMenuItem(Icons.school_outlined, AppLocalizations.of(context)!.classSubject, () => _showAcademicSheet(context, user)),
            _buildMenuItem(Icons.notifications_none_rounded, AppLocalizations.of(context)!.notificationSettings, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
            }),
          ]),
          const SizedBox(height: 24),
          _buildSection(AppLocalizations.of(context)!.support, [
            _buildMenuItem(Icons.help_outline_rounded, AppLocalizations.of(context)!.helpSupport, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            }),
            _buildMenuItem(Icons.feedback_outlined, 'Feedback', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            }),
          ]),
          const SizedBox(height: 24),
          _buildSection(AppLocalizations.of(context)!.other, [
            _buildMenuItem(Icons.privacy_tip_outlined, AppLocalizations.of(context)!.privacyPolicy, () => _showPrivacyDialog(context)),
            _buildMenuItem(Icons.logout_rounded, AppLocalizations.of(context)!.logout, () => _showLogoutDialog(context), isDestructive: true),
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
                Text(user?.name ?? 'Teacher', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(
                  '${(user?.subjects != null && user!.subjects!.isNotEmpty) ? user.subjects!.first : "Faculty"} Member', 
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
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
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.areYouSureLogout),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAcademicSheet(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Academic Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Your assigned teaching roles across EduTrack AI.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.school_rounded, color: Colors.blue)),
              title: const Text('Assigned Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user?.subjects?.join(', ') ?? 'No subjects assigned'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text('PRIMARY CLASSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textHint, letterSpacing: 1)),
            ),
            if (user?.assignedClasses == null || user!.assignedClasses!.isEmpty)
              const ListTile(title: Text('No classes assigned', style: TextStyle(color: Colors.grey, fontSize: 13)))
            else
              ...user.assignedClasses!.map((classId) => StreamBuilder<ClassModel>(
                stream: ClassService().getClassById(classId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final cls = snapshot.data!;
                  return ListTile(
                    dense: true,
                    leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.class_rounded, color: Colors.orange, size: 16)),
                    title: Text(cls.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      'Standard ${cls.standard} - Section ${cls.section?.isNotEmpty == true ? cls.section : 'Not assigned'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Privacy & Trust', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Text(
            'At EduTrack AI, your data privacy is our top priority. We use industry-standard encryption to protect student records, attendance logs, and personal faculty information. \n\nWe do not share your data with third-party advertisers.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('I Understand'))],
      ),
    );
  }
}
