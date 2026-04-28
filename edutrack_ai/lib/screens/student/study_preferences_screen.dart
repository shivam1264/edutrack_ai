import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class StudyPreferencesScreen extends StatefulWidget {
  const StudyPreferencesScreen({super.key});

  @override
  State<StudyPreferencesScreen> createState() => _StudyPreferencesScreenState();
}

class _StudyPreferencesScreenState extends State<StudyPreferencesScreen> {
  String _difficulty = 'Intermediate';
  bool _aiFeedback = true;
  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'History', 
    'Geography', 'Computer Science', 'Physics', 'Chemistry', 'Biology'
  ];
  final Set<String> _selectedSubjects = {'Mathematics', 'Science', 'Physics'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Study Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('LEARNING GOALS'),
            const SizedBox(height: 16),
            _buildDifficultySelector(),
            const SizedBox(height: 32),
            _buildSectionTitle('PREFERRED SUBJECTS'),
            const SizedBox(height: 16),
            _buildSubjectChips(),
            const SizedBox(height: 32),
            _buildSectionTitle('AI ASSISTANCE'),
            const SizedBox(height: 16),
            _buildAISettings(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await _savePreferences();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Study preferences saved! ✅'), backgroundColor: AppTheme.success),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Preferences'),
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

  Widget _buildDifficultySelector() {
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
          final isSelected = _difficulty == level;
          return ListTile(
            title: Text(level, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
            onTap: () => setState(() => _difficulty = level),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _subjects.map((subject) {
        final isSelected = _selectedSubjects.contains(subject);
        return FilterChip(
          label: Text(subject),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) _selectedSubjects.add(subject);
              else _selectedSubjects.remove(subject);
            });
          },
          selectedColor: AppTheme.primary.withOpacity(0.2),
          checkmarkColor: AppTheme.primary,
          labelStyle: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderLight)),
        );
      }).toList(),
    );
  }

  Widget _buildAISettings() {
    return PremiumCard(
      child: SwitchListTile(
        title: const Text('Real-time AI Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Get instant hints while solving problems.', style: TextStyle(fontSize: 12)),
        value: _aiFeedback,
        onChanged: (v) => setState(() => _aiFeedback = v),
        activeColor: AppTheme.primary,
      ),
    );
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_difficulty', _difficulty);
    await prefs.setStringList('study_subjects', _selectedSubjects.toList());
    await prefs.setBool('ai_feedback', _aiFeedback);
  }
}
