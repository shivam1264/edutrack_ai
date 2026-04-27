import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import '../../../services/analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsView extends StatefulWidget {
  const AdminAnalyticsView({super.key});

  @override
  State<AdminAnalyticsView> createState() => _AdminAnalyticsViewState();
}

class _AdminAnalyticsViewState extends State<AdminAnalyticsView> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Analytics Overview', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopMetrics(),
            const SizedBox(height: 24),
            const Text('Enrollment Trend (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildEnrollmentChart(),
            const SizedBox(height: 32),
            const Text('Top Performing Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildPerformanceList(),
            const SizedBox(height: 32),
            _buildAIIntelligence(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMetrics() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Students', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Live', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FutureBuilder<double>(
            future: _analyticsService.getGlobalAttendance(),
            builder: (context, snapshot) {
              final rate = snapshot.data ?? 0.0;
              return PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today\'s Attendance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('${rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.secondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(rate > 85 ? Icons.check_circle_outline : Icons.warning_amber_rounded, 
                             color: rate > 85 ? Colors.green : Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(rate > 85 ? 'Healthy' : 'Monitor', 
                             style: TextStyle(color: rate > 85 ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getGlobalEnrollmentTrend(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            height: 200,
            child: PremiumCard(
              child: Center(child: Text('Error loading trend: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 10))),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            height: 200,
            child: const PremiumCard(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!;
        final spots = data.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble());
        }).toList();

        // Check if all counts are zero
        bool allZero = data.every((e) => (e['count'] as int) == 0);
        if (allZero) {
          return Container(
            height: 200,
            child: const PremiumCard(
              child: Center(child: Text('No new student enrollments this week', style: TextStyle(color: Colors.grey, fontSize: 12))),
            ),
          );
        }

        // Ensure at least 2 spots for the line chart
        if (spots.length < 2) {
          return Container(
            height: 200,
            child: const PremiumCard(
              child: Center(child: Text('Gathering data...', style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        if (maxY < 5) maxY = 5;

        return PremiumCard(
          padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(data[index]['date'], style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withOpacity(0.2), AppTheme.primary.withOpacity(0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPerformanceList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getTopPerformingClasses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data!;
        if (classes.isEmpty) return const Center(child: Text('No class performance data yet.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))));

        return Column(
          children: classes.asMap().entries.map((entry) {
            final data = entry.value;
            final index = entry.key;
            final colors = [Colors.blue, Colors.purple, Colors.amber, Colors.red];
            final percent = (data['average_score'] as double).clamp(0, 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(data['name'] ?? 'Class', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: AppTheme.bgLight,
                        valueColor: AlwaysStoppedAnimation<Color>(colors[index % colors.length]),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildAIIntelligence() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Text('AI Intelligence', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ai_predictions').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _AIStatCard(label: 'Total Insights', value: '$count', trend: 'Real-time', color: Colors.blueAccent);
                }
              ),
              const SizedBox(width: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ai_predictions').where('risk_level', isEqualTo: 'High').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _AIStatCard(label: 'At Risk Students', value: '$count', trend: 'Requires Action', color: Colors.redAccent);
                }
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AIStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _AIStatCard({required this.label, required this.value, required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
