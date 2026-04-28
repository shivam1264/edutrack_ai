import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Real Configuration State
  bool _autoNotifyParents = true;
  double _attendanceThreshold = 75.0;
  String _aiModel = 'Llama-3.3-70b';
  String _academicYear = '2024-25';
  bool _enableGamification = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('system').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _autoNotifyParents = data['auto_notify_parents'] ?? true;
          _attendanceThreshold = (data['attendance_threshold'] ?? 75.0).toDouble();
          _aiModel = data['ai_model'] ?? 'Llama-3.3-70b';
          _academicYear = data['academic_year'] ?? '2024-25';
          _enableGamification = data['enable_gamification'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('system').set({
        'auto_notify_parents': _autoNotifyParents,
        'attendance_threshold': _attendanceThreshold,
        'ai_model': _aiModel,
        'academic_year': _academicYear,
        'enable_gamification': _enableGamification,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': 'admin',
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System configuration saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Academic Configuration', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('ACADEMIC CORE'),
          const SizedBox(height: 16),
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDropdownTile(
                  icon: Icons.calendar_today_rounded,
                  color: Colors.blue,
                  title: 'Active Academic Year',
                  value: _academicYear,
                  items: ['2023-24', '2024-25', '2025-26'],
                  onChanged: (val) => setState(() => _academicYear = val!),
                ),
                const Divider(height: 32),
                _buildDropdownTile(
                  icon: Icons.psychology_rounded,
                  color: Colors.purple,
                  title: 'Primary AI Model',
                  value: _aiModel,
                  items: ['Llama-3.3-70b', 'Llama-3.1-8b', 'EduTrack-Custom-v2'],
                  onChanged: (val) => setState(() => _aiModel = val!),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 32),
          _buildSectionHeader('RISK & PERFORMANCE'),
          const SizedBox(height: 16),
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Risk Threshold', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('${_attendanceThreshold.toInt()}% Attendance', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                  ],
                ),
                Slider(
                  value: _attendanceThreshold,
                  min: 50, max: 95,
                  divisions: 9,
                  onChanged: (val) => setState(() => _attendanceThreshold = val),
                  activeColor: AppTheme.primary,
                ),
                const Text('Students with attendance below this limit will trigger AI intervention alerts.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

          const SizedBox(height: 32),
          _buildSectionHeader('SYSTEM NODES'),
          const SizedBox(height: 16),
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-Notify Parents', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Automatic alerts for low attendance', style: TextStyle(fontSize: 11)),
                  value: _autoNotifyParents,
                  onChanged: (val) => setState(() => _autoNotifyParents = val),
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 24),
                SwitchListTile(
                  title: const Text('Enable Gamification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Badges and XP for student progress', style: TextStyle(fontSize: 11)),
                  value: _enableGamification,
                  onChanged: (val) => setState(() => _enableGamification = val),
                  activeColor: Colors.amber,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isSaving 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save System Configuration', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Color(0xFF64748B)),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
              DropdownButton<String>(
                value: value,
                isExpanded: true,
                underline: const SizedBox(),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))))).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
