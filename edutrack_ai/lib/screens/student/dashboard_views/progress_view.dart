import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';
import 'package:edutrack_ai/widgets/glass_card.dart';
import 'package:edutrack_ai/screens/student/learning_dna_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.bgLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
        title: Text(
          l10n.performanceOverview,
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 18,
            color: isDark ? Colors.white : AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), Colors.white],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(Map<String, dynamic>? data, AppLocalizations l10n) {
    final subjectAvg = data?['subject_avg'] as Map<String, dynamic>? ?? {};
    final dynamicTabs = [l10n.all, ...subjectAvg.keys];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> tabColors = [
      AppTheme.primary,
      ...List.generate(subjectAvg.keys.length, (index) => AppTheme.subjectColors[index % AppTheme.subjectColors.length])
    ];

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dynamicTabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final color = tabColors[index];
          
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : (isDark ? Colors.white10 : AppTheme.borderLight.withOpacity(0.5)),
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              alignment: Alignment.center,
              child: Text(
                dynamicTabs[index],
                style: TextStyle(
                  color: isSelected ? color : (isDark ? Colors.white70 : AppTheme.textSecondary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
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
    final subjectScoresMap = data['subject_scores'] as Map<String, dynamic>? ?? {};
    final dynamicTabs = [l10n.all, ...subjectAvg.keys];
    
    final selectedSubject = _selectedTabIndex < dynamicTabs.length ? dynamicTabs[_selectedTabIndex] : l10n.all;
    double avgScore = 0.0;
    List<double> trendScores = [];

    if (_selectedTabIndex == 0) {
      avgScore = (data['avg_score'] as num?)?.toDouble() ?? 0.0;
      trendScores = (data['scores_trend'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    } else {
      avgScore = (subjectAvg[selectedSubject] as num?)?.toDouble() ?? 0.0;
      final subjectScores = subjectScoresMap[selectedSubject] as List?;
      trendScores = subjectScores?.map((e) => (e as num).toDouble()).toList() ?? [];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDNAHeader(context, data, l10n).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _buildMainStats(
            avgScore, 
            (data['attendance'] as num?)?.toDouble() ?? 0.0,
            (data['course_completion'] as num?)?.toDouble() ?? 0.0,
            (data['graded_count'] as num?)?.toInt() ?? 0,
            l10n
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTabIndex == 0 ? l10n.learningVelocityOverall : l10n.learningTrend,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              if (trendScores.length > 1)
                (() {
                  final velocity = trendScores.last - trendScores.first;
                  final isPositive = velocity >= 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(isPositive ? Icons.trending_up : Icons.trending_down, 
                             color: isPositive ? AppTheme.success : AppTheme.danger, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${isPositive ? '+' : ''}${velocity.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: isPositive ? AppTheme.success : AppTheme.danger, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  );
                })(),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreChart(trendScores, l10n).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 32),
          if (_selectedTabIndex == 0) ...[
            Text(l10n.subjectBreakdown, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            _buildSubjectPerformance(subjectAvg, l10n),
          ] else ...[
            Text(l10n.masteryGoals, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            _buildMasteryCard(selectedSubject, avgScore, l10n),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildMainStats(double avgScore, double attendance, double completion, int gradedCount, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.averageScore,
                value: '${avgScore.toStringAsFixed(1)}%',
                icon: Icons.auto_graph_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: l10n.attendance,
                value: '${attendance.toStringAsFixed(0)}%',
                icon: Icons.calendar_today_rounded,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Course Completion",
                value: '${completion.toStringAsFixed(0)}%',
                icon: Icons.task_alt_rounded,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: "Graded Tasks",
                value: '$gradedCount',
                icon: Icons.assignment_turned_in_rounded,
                color: AppTheme.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? color.withOpacity(0.15) : color.withOpacity(0.02),
              isDark ? Colors.transparent : Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -5,
              bottom: -5,
              child: Icon(icon, size: 50, color: color.withOpacity(0.04)),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChart(List<double> scores, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (scores.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.query_stats_rounded, size: 48, color: AppTheme.textHint.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.completeMoreQuizzesToSeeTrend,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.borderLight.withOpacity(0.5)),
        boxShadow: AppTheme.softShadow(AppTheme.primary),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false, 
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.borderLight.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < scores.length && index == value) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${l10n.q}${index + 1}', 
                        style: TextStyle(
                          color: AppTheme.textHint, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Monospace'
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => isDark ? const Color(0xFF334155) : Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}%',
                    const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (scores.length - 1).toDouble().clamp(4, double.infinity),
          minY: 0,
          maxY: 105,
          lineBarsData: [
            LineChartBarData(
              spots: scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.info],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
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
        padding: const EdgeInsets.all(40),
        child: Center(child: Text(l10n.noSubjectDataAvailableYet, style: const TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Column(
      children: subjectAvg.entries.toList().asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        final color = _getColorForSubject(entry.key);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconForSubject(entry.key), color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key, 
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2)
                          ),
                          Text(
                            '${(entry.value as num).toStringAsFixed(0)}%', 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedFractionallySizedBox(
                            duration: Duration(milliseconds: 1000 + (index * 200)),
                            curve: Curves.easeOutCubic,
                            widthFactor: (entry.value as num) / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (400 + index * 100).ms).slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildMasteryCard(String subject, double mastery, AppLocalizations l10n) {
    final target = ((mastery + 10).clamp(75, 100)).toInt();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$subject ${l10n.mastery}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${l10n.target}: $target%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: mastery, 
                        color: AppTheme.primary, 
                        radius: 20, 
                        showTitle: false,
                        badgeWidget: _Badge('${mastery.toStringAsFixed(0)}%', AppTheme.primary),
                        badgePositionPercentageOffset: 1,
                      ),
                      PieChartSectionData(
                        value: 100 - mastery, 
                        color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.bgLight, 
                        radius: 15, 
                        showTitle: false
                      ),
                    ],
                  ),
                ).animate().rotate(duration: 1.seconds, begin: -0.5, end: 0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${mastery.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary),
                    ),
                    Text(
                      "Mastery",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.keepPracticingToImproveYourScore, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 13)
          ),
        ],
      ),
    );
  }

  Widget _buildDNAHeader(BuildContext context, Map<String, dynamic>? data, AppLocalizations l10n) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(isDark ? 0.2 : 0.1),
            AppTheme.accent.withOpacity(isDark ? 0.2 : 0.1),
          ],
        ),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: -5,
                  )
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: AppTheme.primary, size: 32),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Learning DNA",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "AI-powered sequence of your academic profile",
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LearningDNAScreen(studentId: userId)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: AppTheme.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                children: [
                  Text("Explore", style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return Icons.calculate_rounded;
      case 'science': return Icons.science_rounded;
      case 'english': return Icons.menu_book_rounded;
      case 'history': return Icons.history_edu_rounded;
      case 'computer': return Icons.computer_rounded;
      case 'physics': return Icons.rocket_launch_rounded;
      case 'chemistry': return Icons.biotech_rounded;
      case 'biology': return Icons.eco_rounded;
      default: return Icons.auto_stories_rounded;
    }
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
