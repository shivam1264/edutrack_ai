import 'package:flutter/material.dart';
import '../../services/class_service.dart';
import '../../widgets/premium_card.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final _classService = ClassService();
  String _selectedStandard = '1st';
  final _sectionController = TextEditingController();
  final List<String> _standards = [
    'Pre-Primary', 'KG', '1st', '2nd', '3rd', '4th', '5th', 
    '6th', '7th', '8th', '9th', '10th', '11th', '12th'
  ];

  Future<void> _addClass() async {
    _sectionController.clear();
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Establish New Class', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStandard,
                decoration: InputDecoration(
                  labelText: 'Academic Standard',
                  prefixIcon: Icon(Icons.school_rounded, color: AppTheme.secondary),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setModalState(() => _selectedStandard = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sectionController,
                decoration: InputDecoration(
                  labelText: 'Section (Optional)',
                  hintText: 'e.g. A, B, or Alpha',
                  prefixIcon: Icon(Icons.grid_view_rounded, color: AppTheme.secondary),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: () async {
                  await _classService.addClass(_selectedStandard, _sectionController.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Establish Class'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: _classService.getClasses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hub_outlined, size: 64, color: AppTheme.textHint.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No Academic Classes active.', style: TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                  Text('Establish your first class to begin.', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: classes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cls = classes[index];
              return PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(4),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.holiday_village_rounded, color: AppTheme.secondary, size: 24),
                  ),
                  title: Text(
                    cls.displayName,
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text('ID: ${cls.id.length > 6 ? cls.id.substring(0, 6).toUpperCase() : cls.id}', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textHint)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_sweep_rounded, color: AppTheme.danger, size: 22),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Remove Class?'),
                          content: const Text('This will remove the class from active rosters.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), 
                                child: Text('Delete', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _classService.deleteClass(cls.id);
                      }
                    },
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClass,
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Class'),
      ),
    );
  }
}
