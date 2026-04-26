import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/analytics_service.dart';
import '../../widgets/premium_card.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAcademicsScreen extends StatefulWidget {
  final String? studentId;
  const ParentAcademicsScreen({super.key, this.studentId});

  @override
  State<ParentAcademicsScreen> createState() => _ParentAcademicsScreenState();
}

class _ParentAcademicsScreenState extends State<ParentAcademicsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Academics', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              labelColor: Color(0xFFF97316),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF97316),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Subjects'),
                Tab(text: 'Exams'),
                Tab(text: 'Progress'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(),
                  const Center(child: Text('Subjects')),
                  const Center(child: Text('Exams')),
                  const Center(child: Text('Progress')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final user = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    if (childId.isEmpty) return const Center(child: Text('No student linked'));

    return FutureBuilder<Map<String, dynamic>>(
      future: AnalyticsService.instance.getStudentAnalytics(childId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final avgScore = data != null ? "${(data['avg_score'] as num).toInt()}%" : "N/A";
        final classId = data?['class_id'] ?? '';
        final subjectAvgs = data?['subject_avg'] as Map<String, dynamic>? ?? {};
        final lastScores = data?['last_5_scores'] as List<dynamic>? ?? [];

        return FutureBuilder<Map<String, dynamic>?>(
          future: classId.isNotEmpty ? AnalyticsService.instance.getStudentRank(childId, classId) : null,
          builder: (context, rankSnap) {
            final rankData = rankSnap.data;
            final rankStr = rankData != null ? "${rankData['rank']} / ${rankData['total']}" : "N/A";
            final percentile = rankData != null ? "Top ${((rankData['rank'] / rankData['total']) * 100).toInt()}%" : "N/A";

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Academic Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statBox(avgScore, 'Avg Score', Colors.green, 'Overall'),
                      const SizedBox(width: 12),
                      _statBox(rankStr, 'Class Rank', Colors.blue, percentile),
                      const SizedBox(width: 12),
                      _statBox('Good', 'Status', Colors.purple, 'Keep it up'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subject Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (subjectAvgs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No subject data available', style: TextStyle(color: Colors.grey, fontSize: 12))),
                    )
                  else
                    ...subjectAvgs.entries.map((e) => _subjectRow(
                      e.key, 
                      (e.value as num).toDouble() / 100, 
                      _getSubjectColor(e.key)
                    )),
                  const SizedBox(height: 32),
                  const Text('Academic Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: lastScores.isEmpty 
                              ? [const FlSpot(0, 0)] 
                              : lastScores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                            isCurved: true,
                            color: const Color(0xFF10B981),
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Color _getSubjectColor(String name) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.indigo, Colors.teal];
    return colors[name.length % colors.length];
  }

  Widget _statBox(String val, String label, Color color, String sub) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _subjectRow(String title, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${(val * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: val,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
