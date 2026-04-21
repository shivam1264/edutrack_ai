import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
      // FIX: Query 'users' collection instead of 'students' and filter by role
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('class_id', isEqualTo: widget.classId)
          .get();

      _students = snap.docs
          .map((d) => {'uid': d.id, 'name': d.data()['name'] ?? 'Incomplete Profile'})
          .toList();

      final existing = await AttendanceService().getAttendanceByDate(
        classId: widget.classId,
        date: _selectedDate,
      );

      // Create a fresh map for the new date/data
      final Map<String, AttendanceStatus> newStatusMap = {};
      
      // 1. Fill with existing data from DB
      for (final a in existing) {
        newStatusMap[a.studentId] = a.status;
      }

      // 2. Fill missing students with default status 'present'
      for (final s in _students) {
        final uid = s['uid'] as String;
        if (!newStatusMap.containsKey(uid)) {
          newStatusMap[uid] = AttendanceStatus.present;
        }
      }

      setState(() {
        _statusMap.clear();
        _statusMap.addAll(newStatusMap);
      });
    } catch (e) {
      _showSnack('Neural link failed: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      _showSnack('No student data detected for finalization.', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final teacherId = context.read<AuthProvider>().user?.uid ?? '';
      for (final student in _students) {
        final uid = student['uid'] as String;
        await AttendanceService().markAttendance(
          studentId: uid,
          classId: widget.classId,
          date: _selectedDate,
          status: _statusMap[uid] ?? AttendanceStatus.present,
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
    if (!mounted) return;
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
            pinned: true,
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10, left: -10,
                    child: Icon(Icons.how_to_reg_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.className} Roll Call', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text(DateFormat('EEEE, dd MMMM').format(_selectedDate), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _StatBadge(label: 'Present', count: present, color: const Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            _StatBadge(label: 'Absent', count: absent, color: AppTheme.danger),
                            const SizedBox(width: 8),
                            _StatBadge(label: 'Late', count: lateCount, color: AppTheme.accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.event_note_rounded), onPressed: _pickDate),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _students.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('No student data synchronized for this sector.')))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final student = _students[index];
                            final uid = student['uid'] as String;
                            final name = student['name'] as String;
                            final status = _statusMap[uid] ?? AttendanceStatus.present;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _StudentAttendanceTile(
                                name: name,
                                rollNo: index + 1,
                                status: status,
                                onStatusChange: (newStatus) {
                                  setState(() => _statusMap[uid] = newStatus);
                                },
                              ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.1),
                            );
                          },
                          childCount: _students.length,
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.secondary.withOpacity(0.4),
          ),
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text('Finalize Roll Call', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadStudents();
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('$rollNo', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 14))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 15))),
          Row(
            children: [
              _RollBtn(icon: Icons.check_rounded, color: const Color(0xFF10B981), isSelected: status == AttendanceStatus.present, onTap: () => onStatusChange(AttendanceStatus.present)),
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
        duration: const Duration(milliseconds: 250),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.15)),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
      ),
    );
  }
}
