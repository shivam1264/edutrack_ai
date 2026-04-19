import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('School Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildChartSection('Student Risk Distribution', _RiskPieChart()),
            const SizedBox(height: 24),
            _buildChartSection('Attendance Trends', _AttendanceBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'Total Students', collection: 'users', filter: {'role': 'student'})),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Total Teachers', collection: 'users', filter: {'role': 'teacher'})),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String collection;
  final Map<String, dynamic> filter;

  const _StatBox({required this.label, required this.collection, required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection)
          .where(filter.keys.first, isEqualTo: filter.values.first)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('$count', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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

        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(value: low.toDouble(), color: Colors.green, title: 'Low', radius: 50),
              PieChartSectionData(value: med.toDouble(), color: Colors.orange, title: 'Med', radius: 50),
              PieChartSectionData(value: high.toDouble(), color: Colors.red, title: 'High', radius: 50),
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
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 85, color: AppTheme.primary)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 70, color: AppTheme.secondary)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 90, color: AppTheme.accent)]),
        ],
      ),
    );
  }
}
