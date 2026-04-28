import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../services/analytics_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';

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
        title: const Text(
          'Analytics Overview',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopMetrics(),
            const SizedBox(height: 24),
            const Text(
              'Enrollment Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'New student entries over the last seven days.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildEnrollmentChart(),
            const SizedBox(height: 28),
            const Text(
              'Top Performing Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Average class performance based on current analytics.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceList(),
            const SizedBox(height: 28),
            _buildAIIntelligence(),
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
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _MetricCard(
                title: 'Total Students',
                value: '$count',
                subtitle: 'Live count',
                color: AppTheme.primary,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<double>(
            future: _analyticsService.getGlobalAttendance(),
            builder: (context, snapshot) {
              final rate = snapshot.data ?? 0.0;
              return _MetricCard(
                title: 'Attendance Today',
                value: '${rate.toStringAsFixed(1)}%',
                subtitle: rate > 85 ? 'Healthy' : 'Monitor',
                color: rate > 85 ? AppTheme.secondary : AppTheme.warning,
              );
            },
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
          return const PremiumCard(
            child: Text(
              'Enrollment trend could not be loaded.',
              style: TextStyle(color: AppTheme.danger),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: PremiumCard(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!;
        final spots = data.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            (entry.value['count'] as int).toDouble(),
          );
        }).toList();

        if (data.every((e) => (e['count'] as int) == 0) || spots.length < 2) {
          return const SizedBox(
            height: 220,
            child: PremiumCard(
              child: Center(
                child: Text(
                  'Not enough enrollment activity yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          );
        }

        double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        if (maxY < 5) maxY = 5;

        return PremiumCard(
          padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[index]['date'],
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
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
                        colors: [
                          AppTheme.primary.withOpacity(0.16),
                          AppTheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        if (classes.isEmpty) {
          return const PremiumCard(
            child: Text(
              'No class performance data yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return Column(
          children: classes.asMap().entries.map((entry) {
            final data = entry.value;
            final index = entry.key;
            final colors = [
              AppTheme.primary,
              AppTheme.accent,
              AppTheme.warning,
              AppTheme.secondary,
            ];
            final percent = (data['average_score'] as double).clamp(0, 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        data['name'] ?? 'Class',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: AppTheme.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors[index % colors.length],
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAIIntelligence() {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Intelligence',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'High-level AI monitoring across the school.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ai_predictions')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _AIStatCard(
                    label: 'Total Insights',
                    value: '$count',
                    trend: 'Real-time',
                    color: AppTheme.primary,
                  );
                },
              ),
              const SizedBox(width: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ai_predictions')
                    .where('risk_level', isEqualTo: 'High')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _AIStatCard(
                    label: 'High Risk',
                    value: '$count',
                    trend: 'Needs review',
                    color: AppTheme.danger,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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

  const _AIStatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
