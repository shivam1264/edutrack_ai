import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/analytics_service.dart';
import '../../widgets/premium_card.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAcademicsScreen extends StatefulWidget {
  final String? studentId;
  final bool isEmbedded;
  const ParentAcademicsScreen({super.key, this.studentId, this.isEmbedded = false});

  @override
  State<ParentAcademicsScreen> createState() => _ParentAcademicsScreenState();
}

class _ParentAcademicsScreenState extends State<ParentAcademicsScreen> {
  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
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
                _buildSubjectsTab(),
                _buildExamsTab(),
                _buildProgressTab(),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Academics', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: body,
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
                      _statBox(data?['performance_level'] ?? 'Good', 'Status', Colors.purple, data?['performance_insight'] != null ? 'View Trend' : 'Keep it up'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subject Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      TextButton(
                        onPressed: () => DefaultTabController.of(context).animateTo(1),
                        child: const Text('View all', style: TextStyle(fontSize: 12)),
                      ),
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

  Widget _buildSubjectsTab() {
    final user = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    return FutureBuilder<Map<String, dynamic>>(
      future: AnalyticsService.instance.getStudentAnalytics(childId),
      builder: (context, snapshot) {
        final subjectAvgs = snapshot.data?['subject_avg'] as Map<String, dynamic>? ?? {};
        if (subjectAvgs.isEmpty) return const Center(child: Text('No subject data yet'));

        return ListView(
          padding: const EdgeInsets.all(24),
          children: subjectAvgs.entries.map((e) => PremiumCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: _getSubjectColor(e.key).withOpacity(0.1), child: Icon(Icons.book_rounded, color: _getSubjectColor(e.key), size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Text('Academic Average', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text('${(e.value as num).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, color: _getSubjectColor(e.key), fontSize: 16)),
              ],
            ),
          )).toList(),
        );
      }
    );
  }

  Widget _buildExamsTab() {
    final user = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quiz_results')
          .where('student_id', isEqualTo: childId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No exam/quiz records found'));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final score = (data['score'] as num).toInt();
            final total = (data['total'] as num).toInt();
            final percentage = (score / total * 100).toInt();

            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['quiz_title'] ?? 'Quiz', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${data['subject'] ?? ""} • Score: $score/$total', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressTab() {
    final user = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '');

    return FutureBuilder<Map<String, dynamic>>(
      future: AnalyticsService.instance.getStudentAnalytics(childId),
      builder: (context, snapshot) {
        final lastScores = snapshot.data?['last_5_scores'] as List<dynamic>? ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Performance Velocity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              const Text('Trend analysis of the last 5 assessment scores', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),
              SizedBox(
                height: 250,
                child: lastScores.isEmpty 
                  ? const Center(child: Text('Insufficient data for trend analysis', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text('T${value.toInt() + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: lastScores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                            isCurved: true,
                            color: const Color(0xFFF97316),
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true, 
                              gradient: LinearGradient(
                                colors: [const Color(0xFFF97316).withOpacity(0.3), const Color(0xFFF97316).withOpacity(0)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              const SizedBox(height: 40),
              PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFF97316), size: 20),
                        SizedBox(width: 12),
                        Text('AI LEARNING INSIGHT', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF97316), fontSize: 11, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.data?['performance_insight'] ?? "Analyzing student's learning patterns for personalized recommendations...",
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
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
