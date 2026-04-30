import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';

class LearningDNAScreen extends StatefulWidget {
  final String studentId;
  const LearningDNAScreen({super.key, required this.studentId});

  @override
  State<LearningDNAScreen> createState() => _LearningDNAScreenState();
}

class _LearningDNAScreenState extends State<LearningDNAScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dnaData;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDNA();
    });
  }

  Future<void> _loadDNA() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = context.read<AnalyticsProvider>();
      final user = context.read<AuthProvider>().user;
      
      if (analytics.studentAnalytics == null) {
        await analytics.loadStudentAnalytics(widget.studentId);
      }

      final data = analytics.studentAnalytics;
      final studentName = user?.name ?? "Student";
      
      // Build a data-rich context for the AI
      String contextString = "Generate a Learning DNA mindmap for $studentName. ";
      if (data != null) {
        final avgScore = data['avg_score'] ?? 0;
        final attendance = data['attendance'] ?? 0;
        final subjects = (data['subject_avg'] as Map?)?.entries.map((e) => "${e.key}: ${e.value}%").join(", ") ?? "No subject data";
        
        contextString += "Performance Summary: Average Score ${avgScore}%, Attendance ${attendance}%. "
            "Subject Breakdown: $subjects. "
            "Goals: Identify strengths, areas for improvement, and a futuristic academic growth path.";
      } else {
        contextString += "No performance data available yet. Generate a discovery path based on potential and curiosity.";
      }

      final result = await AIService().generateMindMap(contextString);
      setState(() {
        _dnaData = result['mindmap'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Unable to sequence Learning DNA. Tap to retry.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Floating particles effect (simulated with containers)
          ...List.generate(10, (i) => Positioned(
            left: (i * 40).toDouble(),
            top: (i * 80).toDouble(),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: 100, duration: (5 + i).seconds).fadeOut(),
          )),

          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverFillRemaining(
                child: _isLoading 
                  ? _buildLoading()
                  : _error != null
                    ? _buildError()
                    : _buildDNATree(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 120,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "Learning DNA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        background: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Sequencing AI Learning Path...",
            style: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 1.2),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GestureDetector(
        onTap: _loadDNA,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildDNATree() {
    if (_dnaData == null) return const SizedBox();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        children: [
          _buildNode(_dnaData!, index: 0, isRoot: true),
        ],
      ),
    );
  }

  Widget _buildNode(Map<String, dynamic> node, {int index = 0, bool isRoot = false}) {
    final title = node['title'] ?? "Unknown";
    final children = node['children'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine icon based on keywords
    IconData iconData = _getIconForNode(title);
    Color nodeColor = isRoot ? AppTheme.primary : _getColorForNode(title, index);

    return Column(
      children: [
        // Node Card
        GestureDetector(
          onTap: () => _showNodeDetails(title),
          child: Container(
            constraints: const BoxConstraints(minWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  nodeColor.withOpacity(isDark ? 0.4 : 0.8),
                  nodeColor.withOpacity(isDark ? 0.2 : 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, color: Colors.white, size: isRoot ? 28 : 20),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isRoot ? FontWeight.w900 : FontWeight.w700,
                    fontSize: isRoot ? 16 : 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ).animate().scale(delay: (200 + (index * 100)).ms, curve: Curves.easeOutBack).fadeIn(),
        ),

        // Connector & Children
        if (children.isNotEmpty) ...[
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [nodeColor.withOpacity(0.5), Colors.white.withOpacity(0.1)],
              ),
            ),
          ).animate().scaleY(begin: 0, end: 1, delay: (400 + (index * 100)).ms),
          
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: children.asMap().entries.map((entry) => Container(
              constraints: const BoxConstraints(maxWidth: 160),
              child: _buildNode(
                Map<String, dynamic>.from(entry.value as Map), 
                index: index + entry.key + 1,
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  IconData _getIconForNode(String title) {
    final t = title.toLowerCase();
    if (t.contains('math') || t.contains('calc')) return Icons.functions_rounded;
    if (t.contains('science') || t.contains('phys') || t.contains('chem')) return Icons.science_rounded;
    if (t.contains('strength')) return Icons.auto_awesome_rounded;
    if (t.contains('weak') || t.contains('improv')) return Icons.trending_up_rounded;
    if (t.contains('path') || t.contains('future')) return Icons.rocket_launch_rounded;
    if (t.contains('creative') || t.contains('art')) return Icons.palette_rounded;
    if (t.contains('goal')) return Icons.flag_rounded;
    return Icons.bubble_chart_rounded;
  }

  Color _getColorForNode(String title, int index) {
    final t = title.toLowerCase();
    if (t.contains('strength')) return AppTheme.success;
    if (t.contains('weak') || t.contains('improv')) return AppTheme.warning;
    if (t.contains('goal') || t.contains('path')) return AppTheme.accent;
    
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.info,
      AppTheme.accent,
      const Color(0xFFF43F5E),
      const Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  void _showNodeDetails(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Stack(
            children: [
              // Decorative background
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.1),
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.5, 1.5), duration: 5.seconds, curve: Curves.easeInOut).fadeOut(),
              ),
              
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Icon(_getIconForNode(title), color: AppTheme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "AI INSIGHT",
                      style: TextStyle(
                        color: AppTheme.primary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: AIService().chat(
                          "Explain this learning path node in context of student growth: $title",
                          context: 'student',
                          studentId: widget.studentId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 2),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Sequencing deep insights...",
                                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return SingleChildScrollView(
                            child: Text(
                              snapshot.data ?? "No detailed insights available for this node.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ).animate().fadeIn(duration: 600.ms).moveY(begin: 10, end: 0),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
