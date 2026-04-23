import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'permissions_screen.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _autoNotifyParents = true;
  double _attendanceThreshold = 75.0;
  String _aiModel = 'Gemini-1.5-Pro';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('System Configuration', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('AI & ANALYTICS ENGINE'),
          const SizedBox(height: 16),
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDropdownTile(
                  icon: Icons.psychology_rounded,
                  color: Colors.purple,
                  title: 'Core AI Model',
                  value: _aiModel,
                  items: ['Gemini-1.5-Pro', 'Gemini-1.5-Flash', 'EduTrack-Custom-v2'],
                  onChanged: (val) => setState(() => _aiModel = val!),
                ),
                const Divider(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Risk Sensitivity', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('${_attendanceThreshold.toInt()}% Threshold', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Slider(
                      value: _attendanceThreshold,
                      min: 50, max: 90,
                      onChanged: (val) => setState(() => _attendanceThreshold = val),
                      activeColor: AppTheme.primary,
                    ),
                    const Text('Students below this attendance will be flagged as High Risk.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 32),
          _buildSectionHeader('NOTIFICATION NODES'),
          const SizedBox(height: 16),
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-Notify Parents', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Send instant alerts for attendance/grade dips', style: TextStyle(fontSize: 11)),
                  value: _autoNotifyParents,
                  onChanged: (val) => setState(() => _autoNotifyParents = val),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 20),
                  ),
                  activeColor: AppTheme.primary,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.broadcast_on_home_rounded, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Global Announcement Rules', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Define who can send bulk messages', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

          const SizedBox(height: 32),
          _buildSectionHeader('SECURITY & ACCESS'),
          const SizedBox(height: 16),
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.security_rounded, color: Colors.red, size: 20),
                  ),
                  title: const Text('Permissions Matrix', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Configure role-based access control', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.backup_rounded, color: Colors.teal, size: 20),
                  ),
                  title: const Text('Database Backup Control', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Schedule automated system backups', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _saveSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save System Configuration', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.grey),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              DropdownButton<String>(
                value: value,
                isExpanded: true,
                underline: const SizedBox(),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System configuration updated successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
