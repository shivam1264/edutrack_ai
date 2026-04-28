import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
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
        title: Text(AppLocalizations.of(context)!.appSettings, style: const TextStyle(fontWeight: FontWeight.w900)),
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
                    label: Text(AppLocalizations.of(context)!.editProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.profileInformation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    _infoTile(AppLocalizations.of(context)!.guardianName, parent?.name ?? 'Guardian', bottomPadding: 16),
                    _infoTile(AppLocalizations.of(context)!.emailAddress, parent?.email ?? 'N/A', bottomPadding: 16),
                    _infoTile(AppLocalizations.of(context)!.phoneNumber, parent?.phone ?? 'N/A', bottomPadding: 16),
                    _infoTile(AppLocalizations.of(context)!.relationship, parent?.relationship ?? 'Guardian', bottomPadding: 16),
                    _infoTile(AppLocalizations.of(context)!.homeAddress, parent?.address ?? 'No Address Provided', bottomPadding: 0),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_note_rounded, color: AppTheme.parentColor, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.editProfileInfo, style: const TextStyle(color: AppTheme.parentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(AppLocalizations.of(context)!.account, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _prefItem(
              context,
              Icons.manage_accounts_outlined,
              AppLocalizations.of(context)!.accountSettings,
              null,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen())),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.preferences, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _prefItem(
              context,
              Icons.notifications_outlined,
              AppLocalizations.of(context)!.notificationSettings,
              null,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
            ),
            _prefItem(
              context,
              Icons.language_rounded,
              AppLocalizations.of(context)!.language,
              Localizations.localeOf(context).languageCode == 'hi' ? 'हिन्दी' : 'English',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
            ),
            _prefItem(
              context,
              Icons.privacy_tip_outlined,
              AppLocalizations.of(context)!.privacyPolicy,
              null,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
            ),
            _prefItem(
              context,
              Icons.help_outline_rounded,
              AppLocalizations.of(context)!.helpSupport,
              null,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
            ),
            const SizedBox(height: 40),
            InkWell(
              onTap: () => _showLogoutDialog(context),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.logout, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _prefItem(
    BuildContext context,
    IconData icon,
    String title,
    String? trailing,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from this parent account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
