import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../models/class_model.dart';
import '../../services/analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportsScreen extends StatelessWidget {
  final String? classId;
  const ReportsScreen({super.key, this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF334155)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('School Intelligence', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      const Text('Data-driven academic insights and reporting.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildQuickStats().animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 24),
                _buildChartSection('Student Success Risk Distribution', _RiskPieChart(classId: classId)).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
                _buildChartSection('Weekly Attendance protocols (%)', _AttendanceBarChart(classId: classId)).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'Total Students', collection: 'users', filter: {'role': 'student'}, icon: Icons.school_rounded, color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Active Doubts', collection: 'doubts', filter: {'status': 'pending'}, icon: Icons.help_center_rounded, color: Colors.orange)),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.query_stats_rounded, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String collection;
  final Map<String, dynamic> filter;
  final IconData icon;
  final Color color;

  const _StatBox({required this.label, required this.collection, required this.filter, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection)
          .where(filter.keys.first, isEqualTo: filter.values.first)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(height: 12),
              Text('$count', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w900)),
              Text(
                label, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textHint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiskPieChart extends StatelessWidget {
  final String? classId;
  const _RiskPieChart({this.classId});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('ai_predictions');
    if (classId != null) {
      query = query.where('class_id', isEqualTo: classId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        int low = 0; int med = 0; int high = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final risk = data['risk_level']?.toString().toLowerCase();
          if (risk == 'low' || risk == 'safe') low++;
          else if (risk == 'medium' || risk == 'watch') med++;
          else if (risk == 'high' || risk == 'alert') high++;
        }

        final total = low + med + high;
        if (total == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 40, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text('Not enough intelligence data.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              if (low > 0) PieChartSectionData(value: low.toDouble(), color: const Color(0xFF10B981), title: 'Safe', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              if (med > 0) PieChartSectionData(value: med.toDouble(), color: const Color(0xFFF59E0B), title: 'Watch', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              if (high > 0) PieChartSectionData(value: high.toDouble(), color: const Color(0xFFEF4444), title: 'Alert', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  final String? classId;
  const _AttendanceBarChart({this.classId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: AnalyticsService.instance.getWeeklyAttendanceTrend(classId: classId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!;
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
        
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                if (v.toInt() < days.length) {
                  return Text(days[v.toInt()], style: const TextStyle(color: AppTheme.textHint, fontSize: 10, fontWeight: FontWeight.bold));
                }
                return const Text('');
              })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.length, (i) {
              final val = data[i];
              Color barColor = Colors.blue;
              if (val < 60) barColor = Colors.red;
              else if (val < 80) barColor = Colors.orange;
              else barColor = Colors.green;
              
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: val == 0 ? 5 : val, color: barColor, width: 22, borderRadius: BorderRadius.circular(6))
              ]);
            }),
          ),
        );
      },
    );
  }
}
