import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Account Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('SECURITY'),
            const SizedBox(height: 16),
            _buildSettingTile(context, Icons.lock_outline_rounded, 'Change Password', 'Update your login credentials'),
            _buildSettingTile(context, Icons.phonelink_lock_rounded, 'Two-Factor Authentication', 'Add an extra layer of security'),
            const SizedBox(height: 32),
            _buildSectionTitle('PRIVACY'),
            const SizedBox(height: 16),
            _buildSettingTile(context, Icons.visibility_off_outlined, 'Profile Visibility', 'Control who can see your progress'),
            _buildSettingTile(context, Icons.data_usage_rounded, 'Data Management', 'Export or delete your learning data'),
            const SizedBox(height: 48),
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.textHint));
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _showInfo(context, '$title is managed by the school admin.'),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DANGER ZONE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.danger)),
        const SizedBox(height: 16),
        PremiumCard(
          child: ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.danger),
            title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
            subtitle: const Text('Permanently remove your data', style: TextStyle(fontSize: 12)),
            onTap: () => _showInfo(context, 'Account deletion requires school admin approval.'),
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
