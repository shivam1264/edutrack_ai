import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10, right: -10,
                    child: Icon(Icons.analytics_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hub Intelligence', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        Text('Real-time data synchronization & risk analysis', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildQuickStats().animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 24),
                _buildChartSection('Student Success Risk Distribution', _RiskPieChart()).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
                _buildChartSection('Monthly Attendance Protocols', _AttendanceBarChart()).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
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
        Expanded(child: _StatBox(label: 'Active Students', collection: 'users', filter: {'role': 'student'}, icon: Icons.school_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Verified Faculty', collection: 'users', filter: {'role': 'teacher'}, icon: Icons.psychology_rounded)),
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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
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

  const _StatBox({required this.label, required this.collection, required this.filter, required this.icon});

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
                decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 14, color: AppTheme.primary),
              ),
              const SizedBox(height: 12),
              Text('$count', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: AppTheme.textHint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
        );
      },
    );
  }
}

class _RiskPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ai_predictions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        int low = 0; int med = 0; int high = 0;
        for (var doc in snapshot.data!.docs) {
          final risk = doc['risk_level'];
          if (risk == 'low') low++;
          else if (risk == 'medium') med++;
          else if (risk == 'high') high++;
        }

        final total = low + med + high;
        if (total == 0) return const Center(child: Text('No intelligence data gathered.'));

        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: low.toDouble(), 
                color: const Color(0xFF10B981), 
                title: 'Safe', 
                radius: 60,
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              PieChartSectionData(
                value: med.toDouble(), 
                color: const Color(0xFFF59E0B), 
                title: 'Watch', 
                radius: 60,
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              PieChartSectionData(
                value: high.toDouble(), 
                color: const Color(0xFFEF4444), 
                title: 'Alert', 
                radius: 60,
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
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
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 85, color: const Color(0xFF10B981), width: 20, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 70, color: const Color(0xFFF59E0B), width: 20, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 90, color: const Color(0xFF3B82F6), width: 20, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 65, color: const Color(0xFF6366F1), width: 20, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 95, color: AppTheme.secondary, width: 20, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }
}
