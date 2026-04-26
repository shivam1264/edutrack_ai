import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Analytics Overview', style: TextStyle(fontWeight: FontWeight.w900)),
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
            const Text('Enrollment Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildEnrollmentChart(),
            const SizedBox(height: 32),
            const Text('Top Performing Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                    const Text('Students', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('+8.4%', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
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
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Rate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('87.6%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.secondary)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('+4.2%', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentChart() {
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
                    const days = ['9 May', '10 May', '11 May', '12 May', '13 May', '14 May', '15 May'];
                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(days[value.toInt()], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 1000), FlSpot(1, 1500), FlSpot(2, 1200), FlSpot(3, 2000),
                  FlSpot(4, 1800), FlSpot(5, 2500), FlSpot(6, 2850),
                ],
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
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

  Widget _buildPerformanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').limit(4).snapshots(),
      builder: (context, snapshot) {
        final classes = snapshot.data?.docs ?? [];
        if (classes.isEmpty) return const Center(child: Text('No class performance data yet.', style: TextStyle(fontSize: 12, color: Colors.grey)));

        return Column(
          children: classes.asMap().entries.map((entry) {
            final data = entry.value.data() as Map<String, dynamic>;
            final index = entry.key;
            final colors = [Colors.blue, Colors.purple, Colors.amber, Colors.red];
            final percent = (data['average_score'] ?? 85.0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(data['name'] ?? 'Class', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: AppTheme.bgLight,
                        valueColor: AlwaysStoppedAnimation<Color>(colors[index % colors.length]),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w900)),
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
                  return _AIStatCard(label: 'Predictions', value: '$count', trend: '+12.7%', color: Colors.greenAccent);
                }
              ),
              const SizedBox(width: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ai_predictions').where('risk_level', isEqualTo: 'High').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _AIStatCard(label: 'At Risk Students', value: '$count', trend: '+6.3%', color: Colors.redAccent);
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
