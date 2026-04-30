import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SubjectRadarChart extends StatelessWidget {
  final Map<String, double> subjectAvg;
  final bool animate;

  const SubjectRadarChart({
    super.key,
    required this.subjectAvg,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Standardize data: Ensure at least 3 subjects for a good radar look
    final Map<String, double> displayData = Map.from(subjectAvg);
    final defaultSubjects = ['Math', 'Science', 'English', 'History', 'Physics', 'Arts'];
    
    if (displayData.length < 3) {
      for (final s in defaultSubjects) {
        if (!displayData.containsKey(s) && displayData.length < 5) {
          displayData[s] = 0.0;
        }
      }
    }

    final List<String> subjects = displayData.keys.toList();
    final List<RadarEntry> entries = subjects.map((s) => RadarEntry(value: displayData[s]!)).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: AppTheme.primary.withOpacity(isDark ? 0.4 : 0.25),
            borderColor: AppTheme.primary,
            entryRadius: 3,
            dataEntries: entries,
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(color: isDark ? Colors.white10 : AppTheme.borderLight, width: 1),
        radarShape: RadarShape.circle,
        getTitle: (index, angle) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return RadarChartTitle(
            text: subjects[index],
            angle: angle,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
        },
        tickCount: 4,
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
        tickBorderData: BorderSide(color: isDark ? Colors.white10 : AppTheme.borderLight, width: 1),
        gridBorderData: BorderSide(color: isDark ? Colors.white10 : AppTheme.borderLight, width: 1),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeInOutBack,
    );
  }
}
