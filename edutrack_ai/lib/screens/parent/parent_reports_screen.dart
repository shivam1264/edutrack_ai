import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import 'monthly_report_screen.dart';

class ParentReportsScreen extends StatelessWidget {
  const ParentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>().studentAnalytics;
    final user = context.watch<AuthProvider>().user;
    final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : null;
    final avgScore = (analytics?['avg_score'] as num?)?.toDouble();
    final grade = avgScore == null ? 'N/A' : '${avgScore.toStringAsFixed(0)}%';
    final insight = avgScore == null
        ? 'No academic report data is available yet.'
        : avgScore >= 75
            ? 'Academic performance is currently strong. Keep encouraging regular revision.'
            : avgScore >= 50
                ? 'Academic performance is moderate. Focused revision can improve the next results.'
                : 'Academic performance needs attention. Please review assignments and recent quiz scores.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Text('Term 2 (Current)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(grade, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green)),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(insight, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text('Report Highlights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _highlightTile('Academics', avgScore == null ? 'No data' : '${avgScore.toStringAsFixed(0)}%', Colors.indigo, Icons.school_rounded),
            FutureBuilder(
              future: childId == null ? null : AttendanceService().getAttendanceStats(childId),
              builder: (context, snapshot) {
                final attendance = snapshot.data?.percentage;
                return _highlightTile('Attendance', attendance == null ? 'No data' : '${attendance.toStringAsFixed(0)}%', Colors.green, Icons.calendar_today_rounded);
              },
            ),
            _highlightTile('Assignments Submitted', '${analytics?['submitted_count'] ?? 0}', Colors.orange, Icons.assignment_turned_in_rounded),
            _highlightTile('Assignments Graded', '${analytics?['graded_count'] ?? 0}', Colors.teal, Icons.fact_check_rounded),
            const SizedBox(height: 40),
            const Text('Subject Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...(analytics?['subject_avg'] as Map<String, dynamic>? ?? {}).entries.map((e) => _highlightTile(
              e.key, 
              '${(e.value as num).toInt()}%', 
              Colors.blueGrey, 
              Icons.subject_rounded
            )),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen())),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFF97316)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('View Detailed Report', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _highlightTile(String label, String status, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
