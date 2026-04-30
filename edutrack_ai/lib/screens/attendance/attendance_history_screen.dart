import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../models/attendance_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String? initialClassId;
  final bool isAdmin;

  const AttendanceHistoryScreen({
    super.key,
    this.initialClassId,
    this.isAdmin = false,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _selectedClassId;
  List<DateTime> _markedDates = [];
  bool _isLoading = false;
  bool _showCalendar = true; // Default to calendar view
  AttendanceStats? _classStats;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<AttendanceModel>> _detailsCache = {};

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _selectedDay = DateTime.now();
    if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
      _loadDates();
    }
  }

  Future<void> _loadDates() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final dates = await AttendanceService().getMarkedDates(_selectedClassId!);
      final stats = await AttendanceService().getClassAttendanceStats(_selectedClassId!);
      setState(() {
        _markedDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toList();
        _classStats = stats;
        _detailsCache.clear();
      });
      if (_selectedDay != null) _loadDetails(_selectedDay!);
    } catch (e) {
      _showSnack('Failed to load archive: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadDetails(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_detailsCache.containsKey(normalizedDate)) return;
    try {
      final details = await AttendanceService().getAttendanceByDate(
        classId: _selectedClassId!,
        date: normalizedDate,
        filterBySubject: false,
      );
      setState(() {
        _detailsCache[normalizedDate] = details;
      });
    } catch (e) {
      _showSnack('Failed to sync details: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: StreamBuilder<DocumentSnapshot>(
                stream: _selectedClassId != null && _selectedClassId!.isNotEmpty
                  ? FirebaseFirestore.instance.collection('classes').doc(_selectedClassId).snapshots()
                  : null,
                builder: (context, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>?;
                  final name = data?['name'] ?? 'Attendance Archive';
                  return Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16));
                }
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: Icon(_showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded),
                onPressed: () => setState(() => _showCalendar = !_showCalendar),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: (_selectedClassId == null || _selectedClassId!.isEmpty)
                ? SliverFillRemaining(hasScrollBody: false, child: _buildNoClassSelected())
                : _isLoading
                    ? const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
                    : _showCalendar 
                        ? SliverToBoxAdapter(child: _buildCalendarView())
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HISTORICAL LOGS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _buildClassPicker(),
          if (_classStats != null && _selectedClassId != null && _selectedClassId!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(label: 'Avg. Attendance', value: '${_classStats!.percentage.toStringAsFixed(1)}%', icon: Icons.analytics_rounded),
                  _SummaryItem(label: 'Total Sessions', value: '${_markedDates.length}', icon: Icons.history_rounded),
                  _SummaryItem(label: 'Total Present', value: '${_classStats!.totalPresent}', icon: Icons.people_rounded),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(8),
          child: TableCalendar(
            firstDay: DateTime(2023),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.3), shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
              markerDecoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              markersMaxCount: 1,
            ),
            eventLoader: (day) {
              final normalized = DateTime(day.year, day.month, day.day);
              return _markedDates.contains(normalized) ? [true] : [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadDetails(selectedDay);
            },
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedDay != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Details for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailsList(_detailsCache[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildListView() {
    return _markedDates.isEmpty
        ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final date = _markedDates[index];
                final isExpanded = _detailsCache.containsKey(date);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    opacity: 1,
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      onExpansionChanged: (expanding) {
                        if (expanding) _loadDetails(date);
                      },
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.event_available_rounded, color: AppTheme.secondary, size: 22),
                      ),
                      title: Text(DateFormat('EEEE, dd MMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      subtitle: const Text('Click to view roll-call details', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      children: [
                        if (!isExpanded)
                          const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          _buildDetailsList(_detailsCache[date]!),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
              },
              childCount: _markedDates.length,
            ),
          );
  }

  Widget _buildClassPicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final classes = snapshot.data!.docs;
        final classIds = classes.map((doc) => doc.id).toList();
        final effectiveValue = classIds.contains(_selectedClassId) ? _selectedClassId : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              dropdownColor: AppTheme.secondary,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              hint: const Text('Select a Class', style: TextStyle(color: Colors.white70)),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              items: classes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(data['name'] ?? doc.id),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClassId = val;
                  _detailsCache.clear();
                });
                _loadDates();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoClassSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: 80, color: AppTheme.textHint.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text('Please select a class to view records.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: AppTheme.textHint.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text('No attendance records found for this class.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDetailsList(List<AttendanceModel> details) {
    if (details.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No logs found for this date.'));

    final presentCount = details.where((d) => d.isPresent).length;
    final absentCount = details.where((d) => d.isAbsent).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: AppTheme.bgLight.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(label: 'Present', value: '$presentCount', color: Colors.green),
              _MiniStat(label: 'Absent', value: '$absentCount', color: Colors.red),
              _MiniStat(label: 'Late', value: '${details.length - presentCount - absentCount}', color: Colors.orange),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: details.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = details[i];
            return ListTile(
              dense: true,
              leading: Text('${i + 1}.', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              title: FutureBuilder(
                future: AuthService().getUserModel(a.studentId),
                builder: (context, snapshot) {
                  return Text(snapshot.data?.name ?? 'Loading...', style: const TextStyle(fontWeight: FontWeight.w700));
                },
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(a.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.status.name.toUpperCase(),
                  style: TextStyle(color: _getStatusColor(a.status), fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late: return Colors.orange;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
