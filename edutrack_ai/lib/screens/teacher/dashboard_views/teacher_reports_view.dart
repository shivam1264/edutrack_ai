import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/analytics_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import '../../../services/analytics_service.dart';

class TeacherReportsView extends StatelessWidget {
  final String? selectedClassId;
  const TeacherReportsView({super.key, this.selectedClassId});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final data = analytics.classAnalytics;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Reports & Insights', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final avg = data?['class_avg'] == null ? 'N/A' : '${(data!['class_avg'] as num).toStringAsFixed(1)}%';
              Clipboard.setData(ClipboardData(text: 'EduTrack class report: average score $avg'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report summary copied.')));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _buildPerformanceStats(data),
          const SizedBox(height: 24),
          _buildPerformanceTrend(data),
          const SizedBox(height: 24),
          _buildSubjectPerformance(data),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats(Map<String, dynamic>? data) {
    final students = data?['students'] as List?;
    final avg = (data?['class_avg'] as num? ?? 0).toStringAsFixed(0);
    
    double highest = 0;
    double lowest = 100;
    
    if (students != null && students.isNotEmpty) {
      for (var s in students) {
        final score = (s['avg_score'] as num?)?.toDouble() ?? 0;
        if (score > highest) highest = score;
        if (score < lowest) lowest = score;
      }
    } else {
      lowest = 0;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Class Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderLight)),
              child: Row(
                children: [
                  Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatBox('$avg%', 'Class Average', Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatBox('${highest.toStringAsFixed(0)}%', 'Highest', Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatBox('${lowest.toStringAsFixed(0)}%', 'Lowest', Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrend(Map<String, dynamic>? data) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: FutureBuilder<List<double>>(
              future: AnalyticsService.instance.getClassPerformanceTrend(selectedClassId ?? ''),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final trend = snapshot.data ?? [];
                if (trend.isEmpty) {
                  return const Center(
                    child: Text(
                      'No performance trend recorded yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            final date = now.subtract(Duration(days: 6 - value.toInt()));
                            return Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: AppTheme.secondary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: AppTheme.secondary.withOpacity(0.1)),
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformance(Map<String, dynamic>? data) {
    final students = data?['students'] as List?;
    final Map<String, List<double>> subjectsMap = {};
    
    if (students != null) {
      for (var s in students) {
        final subAvgRaw = s['subject_avg'];
        final Map<String, dynamic>? subAvg = subAvgRaw is Map ? Map<String, dynamic>.from(subAvgRaw) : null;
        if (subAvg != null) {
          subAvg.forEach((sub, score) {
             subjectsMap.putIfAbsent(sub, () => []);
             subjectsMap[sub]!.add((score as num).toDouble());
          });
        }
      }
    }

    final subjectRows = subjectsMap.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildSubjectBar(e.key, avg / 100, AppTheme.subjectColors[subjectsMap.keys.toList().indexOf(e.key) % AppTheme.subjectColors.length]),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subject Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: subjectRows.isEmpty 
              ? [const Text('No subject data recorded yet.', style: TextStyle(color: AppTheme.textHint, fontSize: 13))]
              : subjectRows,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectBar(String subject, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
