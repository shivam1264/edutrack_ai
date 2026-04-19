import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  bool _isLoading = true;
  String _schedule = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    final analytics = context.read<AnalyticsProvider>();
    final data = analytics.studentAnalytics;

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/generate-smart-schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject_avg': data?['subject_avg'] ?? {},
          'avg_score': data?['avg_score'] ?? 0,
          'attendance': data?['attendance'] ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _schedule = result['schedule'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to generate mission strategy.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Neural connectivity error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // ── Premium Header ──
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(gradient: AppTheme.meshGradient),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Strategic Planner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('AI-Generated Study Roadmap', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 28),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _error.isNotEmpty
                    ? _buildError()
                    : _buildRoadmap(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 24),
          const Text('Analyzing academic performance...', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text('Designing your optimization roadmap...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 60),
            const SizedBox(height: 20),
            Text(_error, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.danger)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _generatePlan, child: const Text('Retry Analysis')),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmap() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Text('AI GUIDANCE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                MarkdownBody(
                  data: _schedule,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6),
                    h1: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 24),
                    h2: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 20, height: 2.0),
                    h3: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16, height: 1.8),
                    tableBorder: TableBorder.all(color: AppTheme.borderLight, width: 1),
                    tableHead: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary),
                    tableBody: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    listBullet: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
