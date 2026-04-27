import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../utils/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import '../../services/analytics_service.dart';
import '../../models/attendance_model.dart';

class MonthlyReportScreen extends StatefulWidget {
  final String? studentId;
  const MonthlyReportScreen({super.key, this.studentId});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  String? _generatedReport;
  bool _isGenerating = false;
  Map<String, dynamic>? _studentData;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    final user = context.read<AuthProvider>().user;
    final studentId = widget.studentId ?? user?.parentOf?.first;
    if (studentId == null || studentId.isEmpty) {
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'student')
          .limit(1).get();
      if (snap.docs.isNotEmpty) {
        setState(() => _studentData = snap.docs.first.data() as Map<String, dynamic>);
      }
    } else {
      final doc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (doc.exists) {
        setState(() => _studentData = doc.data() as Map<String, dynamic>);
      }
    }
  }

  Future<void> _generateReport() async {
    if (_studentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ward data synchronization failed.')));
      return;
    }

    setState(() { _isGenerating = true; _generatedReport = null; });

    try {
      final monthStr = DateFormat('MMMM yyyy').format(_selectedDate);
      final studentId = _studentData!['uid'] ?? '';
      final attendanceStats = await AttendanceService().getAttendanceStats(studentId);
      final attendanceStr = '${attendanceStats.percentage.toInt()}%';
      
      final analytics = await AnalyticsService.instance.getStudentAnalytics(studentId);
      final avgScoreStr = '${(analytics['avg_score'] as double).toInt()}%';

      final res = await http.post(
        Uri.parse(Config.endpoint('/generate-monthly-report')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentName': _studentData!['name'] ?? 'Student',
          'attendance': attendanceStr, 
          'avgScore': avgScoreStr,   
          'behavior': 'Good', 
          'month': monthStr,
        }),
      ).timeout(const Duration(seconds: 40));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _generatedReport = data['report'] ?? 'Intelligence report generated successfully.');
      } else {
        final report = await _getOfflineReportData();
        setState(() => _generatedReport = report);
      }
    } catch (e) {
      final report = await _getOfflineReportData();
      setState(() => _generatedReport = report);
    }

    setState(() => _isGenerating = false);
  }

  Future<String> _getOfflineReportData() async {
    final studentId = _studentData!['uid'] ?? '';
    final analytics = await AnalyticsService.instance.getStudentAnalytics(studentId);
    final attendanceStats = await AttendanceService().getAttendanceStats(studentId);
    
    final avgScore = (analytics['avg_score'] as num? ?? 0).toInt();
    final attendance = attendanceStats.percentage.toInt();
    final level = analytics['performance_level'] ?? 'Good';
    final insight = analytics['performance_insight'] ?? 'The student has demonstrated stable performance.';

    return '''📊 ACADEMIC SUMMARY: ${_studentData?['name'] ?? 'Student'}
    
✨ PERFORMANCE INSIGHTS
Overall Status: $level ($avgScore%)
$insight

📅 CONSISTENCY PROTOCOLS
Attendance: $attendance%
Consistency rating is based on session participation logs.

💡 STRATEGIC ADVISORY
Maintained the current study rhythm. Performance is tracked via continuous assessment cycles.

👨‍👩‍👦 GUARDIAN RECOMMENDATIONS
Encourage deeper exploration of core subjects to maintain growth potential.''';
  }


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
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10, right: -10,
                    child: Icon(Icons.auto_awesome_motion_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Performance Log', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        Text('Strategic insights for your ward\'s progress', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_studentData != null)
                    PremiumCard(
                      opacity: 1,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(
                                  child: Text(
                                    (_studentData!['name'] ?? 'S')[0].toUpperCase(), 
                                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w900, fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_studentData!['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                                    Text('Class Link: ${_studentData!['classId'] ?? 'NA'}', style: const TextStyle(color: AppTheme.textHint, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.calendar_today_rounded, color: AppTheme.secondary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(DateFormat('MMMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2023),
                                    lastDate: DateTime.now(),
                                  );
                                  if (d != null) setState(() => _selectedDate = d);
                                },
                                child: const Text('Change Period', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton.icon(
                              icon: _isGenerating 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.rocket_launch_rounded),
                              label: Text(_isGenerating ? 'Analyzing Metrics...' : 'Generate Intelligence Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondary,
                                foregroundColor: Colors.white,
                                shadowColor: AppTheme.secondary.withOpacity(0.4),
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: _isGenerating ? null : _generateReport,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                  if (_generatedReport != null) ...[
                    const SizedBox(height: 24),
                    PremiumCard(
                      opacity: 1,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.fact_check_rounded, color: AppTheme.secondary),
                              ),
                              const SizedBox(width: 16),
                              const Text('Strategic Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                          Text(
                            _generatedReport!, 
                            style: const TextStyle(height: 1.7, fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: AppTheme.secondary, size: 14),
                              SizedBox(width: 6),
                              Text('AI PREDICTION ENGINE', style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
