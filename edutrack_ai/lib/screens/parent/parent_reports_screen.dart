import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/premium_card.dart';

class ParentReportsScreen extends StatelessWidget {
  const ParentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>().studentAnalytics;
    final grade = analytics?['overall_grade'] ?? 'B+';
    final insight = analytics?['performance_insight'] ?? "DI is performing well. Keep encouraging!";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () {}),
        ],
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
            _highlightTile('Academics', analytics?['academic_status'] ?? 'Good', Colors.indigo, Icons.school_rounded),
            _highlightTile('Attendance', analytics?['attendance_status'] ?? 'Excellent', Colors.green, Icons.calendar_today_rounded),
            _highlightTile('Behavior', analytics?['behavior_status'] ?? 'Good', Colors.teal, Icons.psychology_rounded),
            _highlightTile('Participation', analytics?['participation_status'] ?? 'Very Good', Colors.orange, Icons.star_rounded),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {},
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
