import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/premium_card.dart';

class ParentWellnessScreen extends StatefulWidget {
  final String? studentId;
  final bool isEmbedded;
  const ParentWellnessScreen({super.key, this.studentId, this.isEmbedded = false});

  @override
  State<ParentWellnessScreen> createState() => _ParentWellnessScreenState();
}

class _ParentWellnessScreenState extends State<ParentWellnessScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AnalyticsProvider>().loadWellnessData(widget.studentId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final studentId = widget.studentId ?? '';
    final aiData = provider.wellnessFor(studentId);
    final isLoading = provider.isWellnessLoading && aiData == null;

    if (isLoading) {
      return widget.isEmbedded
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          : Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(title: const Text('Wellness & AI Insights')),
              body: const Center(child: CircularProgressIndicator()),
            );
    }

    final riskLevel = aiData?['risk_level'] ?? 'Low';
    final report = aiData?['report']?.toString();
    final summary = aiData?['summary']?.toString();
    final answer = aiData?['answer']?.toString();
    final insights = (aiData?['insights'] as List? ?? [
      {'title': 'Great Progress', 'sub': 'Continue regular reading habits.', 'icon': Icons.auto_awesome_rounded, 'color': Colors.green},
      {'title': 'Balance Screen Time', 'sub': 'Monitor recreational usage.', 'icon': Icons.timer_rounded, 'color': Colors.orange},
    ]).map(_normalizeInsight).toList();
    final recommendations = (aiData?['recommendations'] as List? ?? [
      {'title': 'Read 20 mins daily', 'sub': 'Improve focus & comprehension', 'icon': Icons.menu_book_rounded},
      {'title': 'Practice Math', 'sub': '15 mins of daily practice', 'icon': Icons.calculate_rounded},
    ]).map(_normalizeInsight).toList();

    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBurnoutAlert(riskLevel),
          if ((report ?? '').isNotEmpty || (summary ?? '').isNotEmpty || (answer ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildNarrativeCard(
              report: report,
              summary: summary,
              answer: answer,
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              if (provider.isWellnessLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
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

    if (widget.isEmbedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Wellness & AI Insights', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadWellnessData(studentId, force: true),
          ),
        ],
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

  Widget _buildNarrativeCard({
    String? report,
    String? summary,
    String? answer,
  }) {
    final lines = [
      if (summary != null && summary.trim().isNotEmpty) summary.trim(),
      if (report != null && report.trim().isNotEmpty) report.trim(),
      if (answer != null && answer.trim().isNotEmpty) answer.trim(),
    ];

    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF97316)),
              SizedBox(width: 10),
              Text('Parent Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                line,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
              ),
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
