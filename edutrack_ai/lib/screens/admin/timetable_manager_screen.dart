import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/class_model.dart';
import '../../models/timetable_model.dart';
import '../../models/user_model.dart';
import '../../services/timetable_service.dart';
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
  List<UserModel> _teachers = [];
  List<PeriodModel> _periods = [];
  bool _isLoading = false;
  bool _isSaving = false;

  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final _masterSubjects = [
    'Mathematics', 'Science', 'English', 'Hindi', 
    'Social Studies', 'Computer Science', 'Physics', 
    'Chemistry', 'Biology', 'History', 'Geography', 'Economics'
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _loadClasses();
    await _loadTeachers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadClasses() async {
    final snap = await FirebaseFirestore.instance.collection('classes').get();
    _classes = snap.docs;
    if (_classes.isNotEmpty) {
      _selectedClass = _classes.first.id;
      await _loadTimetable();
    }
  }

  Future<void> _loadTeachers() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();
    _teachers = snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<void> _loadTimetable() async {
    if (_selectedClass.isEmpty) return;
    final timetable = await TimetableService().getTimetable(_selectedClass);
    if (timetable != null) {
      setState(() => _periods = timetable.weeklySchedule[_selectedDay] ?? []);
    } else {
      setState(() => _periods = []);
    }
  }

  Future<void> _saveTimetable() async {
    if (_selectedClass.isEmpty) return;
    setState(() => _isSaving = true);
    
    // Fetch current full timetable to update only the selected day
    final existing = await TimetableService().getTimetable(_selectedClass);
    final schedule = existing?.weeklySchedule ?? {};
    schedule[_selectedDay] = _periods;

    final timetable = TimetableModel(
      classId: _selectedClass,
      weeklySchedule: schedule,
      updatedAt: DateTime.now(),
    );

    await TimetableService().saveTimetable(timetable);
    
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Timetable deployed successfully!'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showPeriodDialog({PeriodModel? existing, int? index}) async {
    String? selectedTeacherId = existing?.teacherId;
    String? selectedSubject = existing?.subject;
    TimeOfDay startTime = existing != null 
        ? TimeOfDay(hour: existing.startTime ~/ 60, minute: existing.startTime % 60)
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = existing != null 
        ? TimeOfDay(hour: existing.endTime ~/ 60, minute: existing.endTime % 60)
        : const TimeOfDay(hour: 10, minute: 0);
    final roomCtrl = TextEditingController(text: existing?.room ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing == null ? 'Schedule Period' : 'Refine Period', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: _inputDecoration('Subject', Icons.book_rounded),
                  items: _masterSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setLocalState(() => selectedSubject = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTeacherId,
                  decoration: _inputDecoration('Faculty', Icons.person_rounded),
                  items: _teachers.map((t) => DropdownMenuItem(value: t.uid, child: Text(t.name))).toList(),
                  onChanged: (v) => setLocalState(() => selectedTeacherId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: startTime);
                          if (picked != null) setLocalState(() => startTime = picked);
                        },
                        child: _timeBox('Start', startTime),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: endTime);
                          if (picked != null) setLocalState(() => endTime = picked);
                        },
                        child: _timeBox('End', endTime),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roomCtrl,
                  decoration: _inputDecoration('Room (Optional)', Icons.room_rounded),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (selectedTeacherId == null || selectedSubject == null) return;
                
                final startMinutes = (startTime.hour * 60) + startTime.minute;
                final endMinutes = (endTime.hour * 60) + endTime.minute;

                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
                  return;
                }

                // Conflict Check
                final conflicts = await TimetableService().checkTeacherConflict(
                  teacherId: selectedTeacherId!,
                  day: _selectedDay,
                  startTime: startMinutes,
                  endTime: endMinutes,
                  currentClassId: _selectedClass,
                );

                if (conflicts.isNotEmpty) {
                  if (context.mounted) {
                    _showConflictWarning(conflicts);
                  }
                  return;
                }

                final teacher = _teachers.firstWhere((t) => t.uid == selectedTeacherId);
                final period = PeriodModel(
                  subject: selectedSubject!,
                  teacherId: selectedTeacherId!,
                  teacherName: teacher.name,
                  room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                  startTime: startMinutes,
                  endTime: endMinutes,
                );

                setState(() {
                  if (index != null) {
                    _periods[index] = period;
                  } else {
                    _periods.add(period);
                    _periods.sort((a, b) => a.startTime.compareTo(b.startTime));
                  }
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConflictWarning(List<String> conflicts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Schedule Conflict'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This teacher is already assigned during this time:'),
            const SizedBox(height: 12),
            ...conflicts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $c', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('I will fix it')),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Widget _timeBox(String label, TimeOfDay time) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPeriodDialog(),
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
                      Text('AI-Conflict prevention active 🛡️', style: TextStyle(color: Colors.white70)),
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
                        prefixIcon: const Icon(Icons.class_rounded, color: Color(0xFF0F766E)),
                      ),
                      items: _classes.map((c) {
                        final d = c.data() as Map<String, dynamic>;
                        final model = ClassModel.fromMap(c.id, d);
                        return DropdownMenuItem(value: c.id, child: Text(model.displayName));
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
                        padding: EdgeInsets.all(80),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Empty Schedule.\nTap + to assign faculty.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _periods.length,
                      itemBuilder: (context, i) {
                        final p = _periods[i];
                        return Padding(
                          key: ValueKey(p.startTime),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            opacity: 1,
                            padding: const EdgeInsets.all(14),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
                              ),
                              title: Text(p.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('${p.startTimeStr} - ${p.endTimeStr}\n${p.teacherName}${p.room != null ? " • ${p.room}" : ""}'),
                              isThreeLine: true,
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
