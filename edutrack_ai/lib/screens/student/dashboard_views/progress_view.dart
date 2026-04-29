import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<AnalyticsProvider>().loadStudentAnalytics(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final isLoading = analytics.isLoading;
    final data = analytics.studentAnalytics;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildTabs(data, l10n),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else
                  _buildContent(data, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      expandedHeight: 104,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceLight,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
        title: Text(
          l10n.performanceOverview,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        background: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(Map<String, dynamic>? data, AppLocalizations l10n) {
    final subjectAvg = data?['subject_avg'] as Map<String, dynamic>? ?? {};
    final dynamicTabs = [l10n.all, ...subjectAvg.keys];

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dynamicTabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                ),
              ),
              child: Center(
                child: Text(
                  dynamicTabs[index],
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? data, AppLocalizations l10n) {
    if (data == null) return Center(child: Text(l10n.noPerformanceDataAvailable));

    final subjectAvg = data['subject_avg'] as Map<String, dynamic>? ?? {};
    final dynamicTabs = [l10n.all, ...subjectAvg.keys];
    
    final selectedSubject = _selectedTabIndex < dynamicTabs.length ? dynamicTabs[_selectedTabIndex] : l10n.all;
    double avgScore = 0.0;
    List<double> last5Scores = [];

    if (_selectedTabIndex == 0) {
      // All view
      avgScore = (data['avg_score'] as num?)?.toDouble() ?? 0.0;
      last5Scores = (data['last_5_scores'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    } else {
      // Subject specific view from real data
      avgScore = (subjectAvg[selectedSubject] as num?)?.toDouble() ?? 0.0;
      // Filter quiz results for this subject if available, otherwise fallback
      last5Scores = (data['last_5_scores'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainStats(avgScore, (data['attendance'] as num?)?.toDouble() ?? 0.0, l10n),
          const SizedBox(height: 32),
          Text(
            _selectedTabIndex == 0 ? l10n.learningVelocityOverall : l10n.learningTrend,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildScoreChart(last5Scores, l10n),
          const SizedBox(height: 32),
          if (_selectedTabIndex == 0) ...[
            Text(l10n.subjectBreakdown, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildSubjectPerformance(subjectAvg, l10n),
          ] else ...[
            Text(l10n.masteryGoals, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildMasteryCard(selectedSubject, avgScore, l10n),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMainStats(double avgScore, double attendance, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.averageScore,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${avgScore.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.attendance,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${attendance.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.secondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreChart(List<double> scores, AppLocalizations l10n) {
    if (scores.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(child: Text(l10n.completeMoreQuizzesToSeeTrend)),
      );
    }
    
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < scores.length) {
                    return Text('${l10n.q}${index + 1}', style: const TextStyle(color: AppTheme.textHint, fontSize: 10, fontWeight: FontWeight.bold));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (scores.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.info],
              ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPerformance(Map<String, dynamic> subjectAvg, AppLocalizations l10n) {
    if (subjectAvg.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(l10n.noSubjectDataAvailableYet)),
      );
    }

    return Column(
      children: subjectAvg.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (entry.value as num) / 100,
                      minHeight: 8,
                      backgroundColor: AppTheme.bgLight,
                      valueColor: AlwaysStoppedAnimation<Color>(_getColorForSubject(entry.key)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(entry.value as num).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMasteryCard(String subject, double mastery, AppLocalizations l10n) {
    final target = ((mastery + 10).clamp(75, 100)).toInt();
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$subject ${l10n.mastery}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${l10n.target}: $target%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(value: mastery, color: AppTheme.primary, radius: 20, title: '${mastery.toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 100 - mastery, color: AppTheme.bgLight, radius: 15, title: ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.keepPracticingToImproveYourScore, style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return Colors.blue;
      case 'science': return Colors.green;
      case 'english': return Colors.orange;
      case 'history': return Colors.purple;
      case 'computer': return Colors.teal;
      default: return AppTheme.primary;
    }
  }
}
