import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('App Settings'),
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
            _buildSectionTitle('APPEARANCE'),
            const SizedBox(height: 16),
            PremiumCard(
              child: SwitchListTile(
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                secondary: Icon(Icons.dark_mode_outlined, color: _darkMode ? Colors.amber : AppTheme.textSecondary),
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('NOTIFICATIONS'),
            const SizedBox(height: 16),
            PremiumCard(
              child: SwitchListTile(
                title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.info),
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('LANGUAGE'),
            const SizedBox(height: 16),
            _buildLanguageSelector(),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Version 1.0.4 (Stable)',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.textHint));
  }

  Widget _buildLanguageSelector() {
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: ['English', 'Hindi', 'Marathi', 'Gujarati'].map((lang) {
          final isSelected = _language == lang;
          return ListTile(
            title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
            onTap: () => setState(() => _language = lang),
          );
        }).toList(),
      ),
    );
  }
}
