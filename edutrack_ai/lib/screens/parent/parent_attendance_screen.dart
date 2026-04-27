import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/attendance_service.dart';
import '../../../models/attendance_model.dart';
import '../../widgets/premium_card.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAttendanceScreen extends StatefulWidget {
  final String? studentId;
  const ParentAttendanceScreen({super.key, this.studentId});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFFF97316),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF97316),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Calendar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(context),
                  _buildCalendarTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    if (childId.isEmpty) return const Center(child: Text('No student linked'));

    return FutureBuilder<AttendanceStats>(
      future: AttendanceService().getAttendanceStats(childId),
      builder: (context, statsSnap) {
        if (statsSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = statsSnap.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAttendanceCircle(stats?.percentage),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      children: [
                        _statBox(stats?.totalPresent.toString() ?? 'N/A', 'Present', Colors.green),
                        const SizedBox(width: 12),
                        _statBox(stats?.totalAbsent.toString() ?? 'N/A', 'Absent', Colors.red),
                        const SizedBox(width: 12),
                        _statBox(stats?.totalLate.toString() ?? 'N/A', 'Late', Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Attendance Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              FutureBuilder<List<AttendanceModel>>(
                future: AttendanceService().getStudentAttendanceHistory(studentId: childId),
                builder: (context, trendSnap) {
                  final trend = _buildStudentTrend(trendSnap.data ?? []);
                  if (trend.isEmpty) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: Text('No attendance trend yet', style: TextStyle(color: Colors.grey))),
                    );
                  }
                  return SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, m) {
                                const mnts = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                                if (v.toInt() >= 0 && v.toInt() < mnts.length) {
                                  return Text(mnts[v.toInt()], style: const TextStyle(fontSize: 9, color: Colors.grey));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: trend.asMap().entries.map((e) => _barGroup(e.key, e.value)).toList(),
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  TextButton(
                    onPressed: () => DefaultTabController.of(context).animateTo(1),
                    child: const Text('View Calendar >', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<AttendanceModel>>(
                future: AttendanceService().getStudentAttendanceHistory(studentId: childId),
                builder: (context, historySnap) {
                  final records = historySnap.data ?? [];
                  if (records.isEmpty) return const Center(child: Text('No recent records'));
                  
                  return Column(
                    children: records.take(5).map((r) => _attendanceRow(
                      DateFormat('dd MMM, yyyy').format(r.date),
                      r.status.name.toUpperCase(),
                      r.isPresent ? Colors.green : Colors.red,
                    )).toList(),
                  );
                }
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAttendanceCircle(double? percentage) {
    final value = percentage == null ? 0.0 : percentage.clamp(0, 100).toDouble();
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green.withOpacity(0.1), width: 8),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84, height: 84,
            child: CircularProgressIndicator(value: value / 100, strokeWidth: 8, color: Colors.green, backgroundColor: Colors.transparent),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(percentage == null ? 'N/A' : '${percentage.toInt()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const Text('Present', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String val, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(width: 20, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: Colors.green, width: 16, borderRadius: BorderRadius.circular(4))]);
  }

  List<double> _buildStudentTrend(List<AttendanceModel> records) {
    if (records.isEmpty) return [];
    final now = DateTime.now();
    final days = <DateTime>[];
    var cursor = now;
    while (days.length < 5) {
      if (cursor.weekday != DateTime.saturday && cursor.weekday != DateTime.sunday) {
        days.add(DateTime(cursor.year, cursor.month, cursor.day));
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return days.reversed.map((day) {
      final dayRecords = records.where((r) =>
          r.date.year == day.year && r.date.month == day.month && r.date.day == day.day);
      if (dayRecords.isEmpty) return 0.0;
      final presentValue = dayRecords.where((r) => r.isPresent).length +
          (dayRecords.where((r) => r.isLate).length * 0.5);
      return (presentValue / dayRecords.length) * 100;
    }).toList();
  }

  Widget _buildCalendarTab(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    return FutureBuilder<List<AttendanceModel>>(
      future: AttendanceService().getStudentAttendanceHistory(studentId: childId),
      builder: (context, historySnap) {
        final records = historySnap.data ?? [];
        if (records.isEmpty) return const Center(child: Text('No attendance records found'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final r = records[index];
            return _attendanceRow(
              DateFormat('EEEE, dd MMM yyyy').format(r.date),
              r.status.name.toUpperCase(),
              r.isPresent ? Colors.green : (r.status.name == 'late' ? Colors.orange : Colors.red),
            );
          },
        );
      }
    );
  }

  Widget _attendanceRow(String date, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: color, size: 16),
            const SizedBox(width: 12),
            Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
