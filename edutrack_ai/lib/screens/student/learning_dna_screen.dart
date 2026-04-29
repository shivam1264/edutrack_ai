import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_card.dart';

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
    _loadDNA();
  }

  Future<void> _loadDNA() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For DNA, we use a fixed prompt to get an overview of learning profile
      final result = await AIService().generateMindMap("Student performance and learning path overview");
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildNode(_dnaData!, isRoot: true),
        ],
      ),
    );
  }

  Widget _buildNode(Map<String, dynamic> node, {bool isRoot = false}) {
    final title = node['title'] ?? "Unknown";
    final children = node['children'] as List? ?? [];

    return Column(
      children: [
        // Node Card
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          borderRadius: 16,
          color: isRoot ? AppTheme.primary.withOpacity(0.3) : null,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isRoot ? FontWeight.w900 : FontWeight.bold,
              fontSize: isRoot ? 18 : 14,
            ),
          ),
        ).animate().scale(delay: 200.ms).fadeIn(),

        // Connector & Children
        if (children.isNotEmpty) ...[
          Container(
            width: 2,
            height: 30,
            color: Colors.white.withOpacity(0.2),
          ).animate().scaleY(begin: 0, end: 1),
          
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: children.map((child) => Container(
              constraints: const BoxConstraints(maxWidth: 160),
              child: _buildNode(Map<String, dynamic>.from(child as Map)),
            )).toList(),
          ),
        ],
      ],
    );
  }
}
