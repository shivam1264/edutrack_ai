import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/premium_card.dart';

class ParentWellnessScreen extends StatelessWidget {
  final String? studentId;
  final bool isEmbedded;
  const ParentWellnessScreen({super.key, this.studentId, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final aiData = context.watch<AnalyticsProvider>().aiPrediction;
    final riskLevel = aiData?['risk_level'] ?? 'Low';
    final insights = (aiData?['insights'] as List? ?? [
      {'title': 'Great Progress', 'sub': 'Continue regular reading habits.', 'icon': Icons.auto_awesome_rounded, 'color': Colors.green},
      {'title': 'Balance Screen Time', 'sub': 'Monitor recreational usage.', 'icon': Icons.timer_rounded, 'color': Colors.orange},
    ]).map(_normalizeInsight).toList();
    final recommendations = (aiData?['recommendations'] as List? ?? [
      {'title': 'Read 20 mins daily', 'sub': 'Improve focus & comprehension', 'icon': Icons.menu_book_rounded},
      {'title': 'Practice Math', 'sub': '15 mins of daily practice', 'icon': Icons.calculate_rounded},
    ]).map(_normalizeInsight).toList();

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBurnoutAlert(riskLevel),
          const SizedBox(height: 32),
          const Text('AI Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          ...insights.map((ins) => _insightTile(
            ins['title'] ?? 'Insight',
            ins['sub'] ?? '',
            Icons.auto_awesome_rounded,
            riskLevel == 'High' ? Colors.red : Colors.green,
          )),
          const SizedBox(height: 32),
          const Text('Personalized Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _recommendationTile(
            rec['title'] ?? 'Action',
            rec['sub'] ?? '',
            Icons.auto_awesome_rounded,
          )),
          const SizedBox(height: 100),
        ],
      ),
    );

    if (isEmbedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Wellness & AI Insights', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: body,
    );
  }


  Widget _buildBurnoutAlert(String level) {
    final color = level == 'High' ? Colors.red : (level == 'Medium' ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Wellness Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Risk Level: $level', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(level == 'Low' ? 'Healthy status maintained.' : 'Attention may be required.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightTile(String title, String sub, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _recommendationTile(String title, String sub, IconData icon) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _normalizeInsight(dynamic value) {
    if (value is Map) {
      return {
        'title': value['title']?.toString() ?? 'Insight',
        'sub': value['sub']?.toString() ?? value['message']?.toString() ?? '',
      };
    }

    final text = value?.toString() ?? 'Insight';
    return {
      'title': text,
      'sub': '',
    };
  }
}
