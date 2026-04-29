import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(l10n.appSettings),
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
            _buildSectionTitle(l10n.appearance),
            const SizedBox(height: 16),
            PremiumCard(
              child: SwitchListTile(
                title: Text(l10n.darkMode, style: const TextStyle(fontWeight: FontWeight.bold)),
                secondary: Icon(Icons.dark_mode_outlined, color: isDarkMode ? Colors.amber : AppTheme.textSecondary),
                value: isDarkMode,
                onChanged: (v) {
                  if (v) {
                    themeProvider.setThemeMode(ThemeMode.dark);
                  } else {
                    themeProvider.setThemeMode(ThemeMode.light);
                  }
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.notifications.toUpperCase()),
            const SizedBox(height: 16),
            PremiumCard(
              child: SwitchListTile(
                title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.info),
                value: _notifications,
                onChanged: (v) {
                  setState(() => _notifications = v);
                  _saveNotificationPreference(v);
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.language.toUpperCase()),
            const SizedBox(height: 16),
            _buildLanguageSelector(context),
            const SizedBox(height: 48),
            Center(
              child: Text(
                '${l10n.version} 1.0.4 (Stable)',
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

  Widget _buildLanguageSelector(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final languages = [
      {'name': 'English', 'code': 'en'},
      {'name': 'Hindi', 'code': 'hi'},
      {'name': 'Marathi', 'code': 'mr'},
      {'name': 'Gujarati', 'code': 'gu'},
    ];

    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: languages.map((lang) {
          final isSelected = languageProvider.locale.languageCode == lang['code'];
          return ListTile(
            title: Text(lang['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
            onTap: () => languageProvider.setLocale(Locale(lang['code']!)),
          );
        }).toList(),
      ),
    );
  }
}
