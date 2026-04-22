import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<AttendanceModel> _records = [];
  AttendanceStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    try {
      _records = await AttendanceService().getStudentAttendanceHistory(studentId: uid);
      _stats = await AttendanceService().getAttendanceStats(uid);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Presence Log', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
              centerTitle: true,
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsCard().animate().fadeIn().scale(),
                  const SizedBox(height: 24),
                  _buildSubjectBreakdown().animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  const Text('Mission History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  if (_records.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No presence data available yet.', style: TextStyle(color: AppTheme.textSecondary))))
                  else
                    ..._records.asMap().entries.map((entry) => _RecordTile(record: entry.value).animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: 0.05)),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();
    final pct = _stats!.percentage / 100;
    final color = _stats!.percentage >= 75 ? AppTheme.secondary : (_stats!.percentage >= 60 ? AppTheme.accent : AppTheme.danger);

    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: pct.clamp(0.0, 1.0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_stats!.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
                ),
                const Text('NET SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1)),
              ],
            ),
            progressColor: color,
            backgroundColor: color.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1200,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem('On-Duty', _stats!.totalPresent, AppTheme.secondary, Icons.check_circle_outline_rounded),
              _StatItem('Fallen', _stats!.totalAbsent, AppTheme.danger, Icons.cancel_outlined),
              _StatItem('Late-Op', _stats!.totalLate, AppTheme.accent, Icons.schedule_rounded),
            ],
          ),
          if (_stats!.percentage < 75) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
              child: Row(
                children: [
                   const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                   const SizedBox(width: 12),
                   const Expanded(child: Text('Warning: Presence is below 75%. This may impact your mission evaluation.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.danger, height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown() {
    if (_stats == null || _stats!.subjectStats == null || _stats!.subjectStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject Performance Breakdown', 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        ..._stats!.subjectStats!.entries.map((entry) {
          final sub = entry.key;
          final sStats = entry.value;
          final color = sStats.percentage >= 75 ? AppTheme.secondary : (sStats.percentage >= 60 ? AppTheme.accent : AppTheme.danger);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PremiumCard(
              opacity: 1,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sub, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('${sStats.percentage.toStringAsFixed(1)}%', 
                        style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 8,
                    percent: (sStats.percentage / 100).clamp(0.0, 1.0),
                    progressColor: color,
                    backgroundColor: color.withOpacity(0.1),
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                    animation: true,
                    animationDuration: 1000,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniStat(label: 'Present: ${sStats.totalPresent}', color: AppTheme.secondary),
                      const SizedBox(width: 16),
                      _MiniStat(label: 'Absent: ${sStats.totalAbsent}', color: AppTheme.danger),
                      const SizedBox(width: 16),
                      _MiniStat(label: 'Late: ${sStats.totalLate}', color: AppTheme.accent),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatItem(this.label, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
        const SizedBox(height: 8),
        Text('$count', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.5)),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceModel record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.isPresent ? AppTheme.secondary : (record.isLate ? AppTheme.accent : AppTheme.danger);
    final icon = record.isPresent ? Icons.verified_rounded : (record.isLate ? Icons.timer_rounded : Icons.not_interested_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${record.date.day} ${DateFormat('MMMM').format(record.date)}, ${record.date.year}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                Text(record.subject ?? 'General Academic Session', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(record.status.name.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
