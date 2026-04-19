import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimetableManagerScreen extends StatefulWidget {
  const TimetableManagerScreen({super.key});

  @override
  State<TimetableManagerScreen> createState() => _TimetableManagerScreenState();
}

class _TimetableManagerScreenState extends State<TimetableManagerScreen> {
  String _selectedClass = '';
  String _selectedDay = 'Monday';
  List<QueryDocumentSnapshot> _classes = [];
  List<Map<String, dynamic>> _periods = [];
  bool _isSaving = false;

  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final snap = await FirebaseFirestore.instance.collection('classes').get();
    setState(() {
      _classes = snap.docs;
      if (_classes.isNotEmpty) _selectedClass = _classes.first.id;
    });
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    if (_selectedClass.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('timetable').doc(_selectedClass).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() => _periods = List<Map<String, dynamic>>.from(data[_selectedDay] ?? []));
    } else {
      setState(() => _periods = []);
    }
  }

  Future<void> _saveTimetable() async {
    if (_selectedClass.isEmpty) return;
    setState(() => _isSaving = true);
    final doc = await FirebaseFirestore.instance.collection('timetable').doc(_selectedClass).get();
    final existing = doc.exists ? (doc.data() ?? {}) : {};
    await FirebaseFirestore.instance.collection('timetable').doc(_selectedClass).set({
      ...existing,
      _selectedDay: _periods,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Timetable saved!'), backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  void _addPeriod() {
    _showPeriodDialog();
  }

  void _showPeriodDialog({Map<String, dynamic>? existing, int? index}) {
    final subjectCtrl = TextEditingController(text: existing?['subject'] ?? '');
    final teacherCtrl = TextEditingController(text: existing?['teacher'] ?? '');
    final roomCtrl = TextEditingController(text: existing?['room'] ?? '');
    final startTimeCtrl = TextEditingController(text: existing?['startTime'] ?? '');
    final endTimeCtrl = TextEditingController(text: existing?['endTime'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add Period' : 'Edit Period'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(subjectCtrl, 'Subject', Icons.book_rounded),
              const SizedBox(height: 12),
              _buildField(teacherCtrl, 'Teacher Name', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildField(roomCtrl, 'Room / Location', Icons.room_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildField(startTimeCtrl, 'Start (e.g. 9:00 AM)', Icons.access_time_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildField(endTimeCtrl, 'End (e.g. 9:45 AM)', Icons.access_time_filled_rounded)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () {
              final period = {
                'subject': subjectCtrl.text.trim(),
                'teacher': teacherCtrl.text.trim(),
                'room': roomCtrl.text.trim(),
                'startTime': startTimeCtrl.text.trim(),
                'endTime': endTimeCtrl.text.trim(),
              };
              setState(() {
                if (index != null) {
                  _periods[index] = period;
                } else {
                  _periods.add(period);
                }
              });
              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPeriod,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Period', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF0F766E),
            actions: [
              IconButton(
                icon: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                onPressed: _isSaving ? null : _saveTimetable,
                tooltip: 'Save Timetable',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Timetable Manager', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('Configure class schedules', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_classes.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.class_rounded),
                      ),
                      items: _classes.map((c) {
                        final d = c.data() as Map<String, dynamic>;
                        return DropdownMenuItem(value: c.id, child: Text(d['name'] ?? c.id));
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedClass = v!);
                        _loadTimetable();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final selected = _days[i] == _selectedDay;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDay = _days[i];
                            _loadTimetable();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF0F766E) : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: selected ? [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 8)] : [],
                            ),
                            child: Text(_days[i].substring(0, 3),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                                  color: selected ? Colors.white : const Color(0xFF0F766E)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_periods.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No periods added.\nTap + to add periods.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _periods.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final p = _periods.removeAt(oldIndex);
                          _periods.insert(newIndex, p);
                        });
                      },
                      itemBuilder: (context, i) {
                        final p = _periods[i];
                        return Padding(
                          key: ValueKey(i),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            opacity: 1,
                            padding: const EdgeInsets.all(14),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
                              ),
                              title: Text(p['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('${p['startTime']} - ${p['endTime']} | ${p['teacher']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: () => _showPeriodDialog(existing: p, index: i)),
                                  IconButton(icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.red), onPressed: () => setState(() => _periods.removeAt(i))),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (i * 60).ms);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
