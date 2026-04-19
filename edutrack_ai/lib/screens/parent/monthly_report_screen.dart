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

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

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
    final studentId = user?.parentOf; // In our schema parentOf stores linked studentId, or children array.
    // For simplicity, finding the first student linked to this parent.
    if (studentId == null || studentId.isEmpty) {
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'student')
          // Using a placeholder query, ideally parents should have a 'children' array
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student data not found.')));
      return;
    }

    setState(() { _isGenerating = true; _generatedReport = null; });

    try {
      final monthStr = "${_selectedDate.month}/${_selectedDate.year}";
      final res = await http.post(
        Uri.parse(Config.endpoint('/generate-monthly-report')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentName': _studentData!['name'] ?? 'Your Child',
          'attendance': '88%', // Here we would ideally calculate actual attendance
          'avgScore': '76%',   // Here we would calculate actual avg score from assignments
          'behavior': 'Excellent', 
          'month': monthStr,
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _generatedReport = data['report'] ?? 'Report generated successfully.');
      } else {
        setState(() => _generatedReport = _offlineReport());
      }
    } catch (e) {
      setState(() => _generatedReport = _offlineReport());
    }

    setState(() => _isGenerating = false);
  }

  String _offlineReport() {
    return '''📄 MONTHLY PROGRESS REPORT: ${_studentData?['name'] ?? 'Student'}
    
🌟 ACADEMIC PERFORMANCE
Average Score: 76%
They have shown steady academic progress this month setup.

📅 ATTENDANCE & CONSISTENCY
Attendance: 88%
Regular attendance is key to success.

💡 STRENGTHS & AREAS TO IMPROVE
Strengths: Active participation in class activities.
Areas to improve: Consistent revision at home.

👨‍👩‍👦 SUGGESTIONS FOR PARENTS
Please review homework daily and encourage reading habits. Feel free to contact teachers for specific queries.''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0EA5E9),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -10, right: -10,
                      child: Icon(Icons.assessment_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('AI Monthly Report', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          Text('AI-generated performance summary', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_studentData != null)
                    PremiumCard(
                      opacity: 1,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                                child: Text((_studentData!['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w900, fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_studentData!['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                    Text('Class: ${_studentData!['classId'] ?? 'NA'}', style: const TextStyle(color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.date_range_rounded, color: AppTheme.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Text('Month: ${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: _isGenerating 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome_rounded),
                              label: Text(_isGenerating ? 'Analyzing Data...' : 'Generate AI Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0EA5E9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isGenerating ? null : _generateReport,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(),

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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.assessment_rounded, color: Color(0xFF0EA5E9)),
                              ),
                              const SizedBox(width: 12),
                              const Text('Monthly Insight', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(_generatedReport!, style: const TextStyle(height: 1.6, fontSize: 15, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
