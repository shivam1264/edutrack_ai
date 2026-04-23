import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/brain_dna_visualizer.dart';
import '../../services/brain_dna_service.dart';
import '../../models/knowledge_node.dart';
import 'package:flutter_animate/flutter_animate.dart';

class IndividualStudentAnalyticsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const IndividualStudentAnalyticsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<IndividualStudentAnalyticsScreen> createState() => _IndividualStudentAnalyticsScreenState();
}

class _IndividualStudentAnalyticsScreenState extends State<IndividualStudentAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadStudentAnalytics(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final data = analytics.studentAnalytics;
    final prediction = analytics.aiPrediction;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (analytics.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
                else ...[
                  // AI Risk Alert
                  if (prediction != null) _buildAIRiskCard(prediction),
                  const SizedBox(height: 24),

                  // Knowledge DNA (The Core Visualization)
                  _buildKnowledgeDNASection(),
                  const SizedBox(height: 24),

                  // Performance Overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimpleStat('Avg Mastery', '${(data?['avg_score'] as num? ?? 0).toStringAsFixed(1)}%', Icons.psychology_rounded, AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSimpleStat('Submissions', '${data?['submitted_count'] ?? 0}', Icons.assignment_turned_in_rounded, AppTheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subject Breakdown
                  const Text('Subject-wise Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  _buildSubjectChart(data),
                  const SizedBox(height: 24),

                  // Recommendations (AI Generated)
                  _buildAIInsightsSection(data),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: const BoxDecoration(gradient: AppTheme.studentGradient)),
            Positioned(
              top: -30, right: -20,
              child: Icon(Icons.analytics_rounded, color: Colors.white.withOpacity(0.1), size: 180),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(widget.studentName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.studentName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('Detailed Mastery Report', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRiskCard(Map<String, dynamic> prediction) {
    final risk = prediction['risk_level'] as String? ?? 'low';
    final isHigh = risk == 'high';
    
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isHigh ? AppTheme.danger : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isHigh ? Icons.warning_amber_rounded : Icons.insights_rounded, 
                 color: isHigh ? AppTheme.danger : Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh ? 'ATTENTION: HIGH RISK DETECTED' : 'AI PERFORMANCE FORECAST',
                  style: TextStyle(fontWeight: FontWeight.w900, color: isHigh ? AppTheme.danger : Colors.orange, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  isHigh ? 'Student is showing signs of learning fatigue.' : 'Stable performance with growth potential.',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildKnowledgeDNASection() {
    return StreamBuilder<List<KnowledgeNode>>(
      stream: BrainDNAService.instance.getBrainDNA(widget.studentId),
      builder: (context, snapshot) {
        final nodes = snapshot.data ?? [];
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Text('KNOWLEDGE DNA CLASS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary, fontSize: 12)),
                  Spacer(),
                  _DNAKey(color: Color(0xFF10B981), label: 'Mastered'),
                ],
              ),
              const SizedBox(height: 24),
              if (nodes.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Generating student DNA pulse...', style: TextStyle(color: AppTheme.textHint))))
              else
                Center(child: BrainDNAVisualizer(nodes: nodes, size: 240)),
              const SizedBox(height: 16),
              const Text(
                'This DNA map shows the student\'s real-time concept mastery. Glowing nodes represent strength areas, while faded nodes suggest concepts that require urgent revision.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleStat(String label, String value, IconData icon, Color color) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSubjectChart(Map<String, dynamic>? data) {
    final stats = (data?['subject_avg'] as Map<String, dynamic>? ?? {});
    final entries = stats.entries.toList();

    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 200,
        child: entries.isEmpty
            ? const Center(child: Text('Insufficient data for subject analysis'))
            : BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= entries.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[value.toInt()].key.substring(0, 3).toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: entries.asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value as num).toDouble(),
                        gradient: LinearGradient(
                        colors: e.value.value < 60 ? [AppTheme.danger, AppTheme.danger.withOpacity(0.5)] : [AppTheme.primary, AppTheme.primaryLight],
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  )).toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildAIInsightsSection(Map<String, dynamic>? data) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI LEARNING INSIGHTS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.secondary, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildInsightItem(Icons.auto_awesome_rounded, 'Personalization', 'Recommend focused revision on subjects below 60%.'),
          const Divider(height: 24),
          _buildInsightItem(Icons.trending_up_rounded, 'Growth Potential', 'High retention in Science indicates strong analytical potential.'),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.secondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DNAKey extends StatelessWidget {
  final Color color;
  final String label;
  const _DNAKey({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
