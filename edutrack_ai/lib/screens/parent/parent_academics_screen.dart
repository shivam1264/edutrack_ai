import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/premium_card.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAcademicsScreen extends StatelessWidget {
  const ParentAcademicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Academics', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('85%', 'Avg Score', Colors.green, 'Good'),
              const SizedBox(width: 12),
              _statBox('8 / 32', 'Class Rank', Colors.blue, 'Top 25%'),
              const SizedBox(width: 12),
              _statBox('B+', 'Overall Grade', Colors.purple, 'Good'),
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
          _subjectRow('Mathematics', 0.90, Colors.blue),
          _subjectRow('Science', 0.82, Colors.orange),
          _subjectRow('English', 0.75, Colors.green),
          _subjectRow('Social Studies', 0.70, Colors.purple),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Text('This Year', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
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
                      getTitlesWidget: (v, m) {
                        const mnts = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'];
                        if (v.toInt() >= 0 && v.toInt() < mnts.length) {
                          return Text(mnts[v.toInt()], style: const TextStyle(fontSize: 9, color: Colors.grey));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 40), FlSpot(1, 60), FlSpot(2, 50), FlSpot(3, 85), FlSpot(4, 75), FlSpot(5, 95)],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
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
