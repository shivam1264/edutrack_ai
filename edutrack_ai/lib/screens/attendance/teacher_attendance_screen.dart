import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, AttendanceStatus> _statusMap = {};
  bool _isSaving = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('class_id', isEqualTo: widget.classId)
          .get();

      _students = snap.docs
          .map((d) => {'uid': d.id, 'name': d.data()['name'] ?? 'Unknown'})
          .toList();

      final existing = await AttendanceService().getAttendanceByDate(
        classId: widget.classId,
        date: _selectedDate,
      );

      for (final a in existing) {
        _statusMap[a.studentId] = a.status;
      }

      for (final s in _students) {
        _statusMap.putIfAbsent(s['uid'] as String, () => AttendanceStatus.present);
      }
    } catch (e) {
      _showSnack('Neural link failed: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      final teacherId = context.read<AuthProvider>().user?.uid ?? '';
      for (final student in _students) {
        final uid = student['uid'] as String;
        await AttendanceService().markAttendance(
          studentId: uid,
          classId: widget.classId,
          date: _selectedDate,
          status: _statusMap[uid] ?? AttendanceStatus.absent,
          markedBy: teacherId,
        );
      }
      _showSnack('Attendance protocols finalized! ✅');
    } catch (e) {
      _showSnack('Finalization failed: $e', isError: true);
    }
    setState(() => _isSaving = false);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final present = _statusMap.values.where((s) => s == AttendanceStatus.present).length;
    final absent = _statusMap.values.where((s) => s == AttendanceStatus.absent).length;
    final lateCount = _statusMap.values.where((s) => s == AttendanceStatus.late).length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.secondary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              title: Text('${widget.className} Roll Call', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatBadge('P', present, AppTheme.secondary),
                        const SizedBox(width: 12),
                        _StatBadge('A', absent, AppTheme.danger),
                        const SizedBox(width: 12),
                        _StatBadge('L', lateCount, AppTheme.accent),
                      ],
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                onPressed: _pickDate,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _students.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('No agents assigned to this hub.')))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final student = _students[index];
                            final uid = student['uid'] as String;
                            final name = student['name'] as String;
                            final status = _statusMap[uid] ?? AttendanceStatus.present;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _StudentAttendanceTile(
                                name: name,
                                rollNo: index + 1,
                                status: status,
                                onStatusChange: (newStatus) {
                                  setState(() => _statusMap[uid] = newStatus);
                                },
                              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
                            );
                          },
                          childCount: _students.length,
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: AppTheme.secondary.withOpacity(0.4),
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Finalize Roll Call', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.secondary, onPrimary: Colors.white, onSurface: AppTheme.textPrimary),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppTheme.secondary)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      _statusMap.clear();
      setState(() => _selectedDate = picked);
      await _loadStudents();
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label:', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _StudentAttendanceTile extends StatelessWidget {
  final String name;
  final int rollNo;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onStatusChange;

  const _StudentAttendanceTile({required this.name, required this.rollNo, required this.status, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('$rollNo', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textSecondary, fontSize: 13))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 15))),
          Row(
            children: [
              _RollBtn(icon: Icons.check_rounded, color: AppTheme.secondary, isSelected: status == AttendanceStatus.present, onTap: () => onStatusChange(AttendanceStatus.present)),
              const SizedBox(width: 8),
              _RollBtn(icon: Icons.close_rounded, color: AppTheme.danger, isSelected: status == AttendanceStatus.absent, onTap: () => onStatusChange(AttendanceStatus.absent)),
              const SizedBox(width: 8),
              _RollBtn(icon: Icons.schedule_rounded, color: AppTheme.accent, isSelected: status == AttendanceStatus.late, onTap: () => onStatusChange(AttendanceStatus.late)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RollBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RollBtn({required this.icon, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: isSelected ? color : color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? color : color.withOpacity(0.2))),
        child: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
      ),
    );
  }
}
