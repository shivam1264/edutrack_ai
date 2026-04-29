import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Map<DateTime, List<AttendanceModel>> _detailsCache = {};

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    if (_selectedClassId != null) {
      _loadDates();
    }
  }

  Future<void> _loadDates() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    try {
      final dates = await AttendanceService().getMarkedDates(_selectedClassId!);
      setState(() {
        _markedDates = dates;
        _detailsCache.clear();
      });
    } catch (e) {
      _showSnack('Failed to load archive: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadDetails(DateTime date) async {
    if (_detailsCache.containsKey(date)) return;
    try {
      final details = await AttendanceService().getAttendanceByDate(
        classId: _selectedClassId!,
        date: date,
        filterBySubject: false,
      );
      setState(() {
        _detailsCache[date] = details;
      });
    } catch (e) {
      _showSnack('Failed to sync details: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: StreamBuilder<DocumentSnapshot>(
                stream: _selectedClassId != null 
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
          ),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _selectedClassId == null
                ? SliverFillRemaining(hasScrollBody: false, child: _buildNoClassSelected())
                : _isLoading
                    ? const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
                    : _markedDates.isEmpty
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
                                    child: Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                                        subtitle: Text('Click to view roll-call details', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                        children: [
                                          if (!isExpanded)
                                            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                                          else
                                            _buildDetailsList(_detailsCache[date]!),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
                                );
                              },
                              childCount: _markedDates.length,
                            ),
                          ),
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
          if (widget.isAdmin)
            _buildClassPicker()
          else
            const SizedBox(height: 10),
        ],
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
                setState(() => _selectedClassId = val);
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

  Widget _buildDateList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _markedDates.length,
      itemBuilder: (context, index) {
        final date = _markedDates[index];
        final isExpanded = _detailsCache.containsKey(date);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            opacity: 1,
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                subtitle: Text('Click to view roll-call details', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                children: [
                  if (!isExpanded)
                    const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    _buildDetailsList(_detailsCache[date]!),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
        );
      },
    );
  }

  Widget _buildDetailsList(List<AttendanceModel> details) {
    if (details.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No data captured.'));

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      a.status.name.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(a.status), fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                    if (a.subject != null)
                      Text(a.subject!, style: const TextStyle(color: AppTheme.textHint, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
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
