import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/knowledge_node.dart';
import '../utils/app_theme.dart';

class BrainDNAVisualizer extends StatefulWidget {
  final List<KnowledgeNode> nodes;
  final double size;

  const BrainDNAVisualizer({
    super.key,
    required this.nodes,
    this.size = 300,
  });

  @override
  State<BrainDNAVisualizer> createState() => _BrainDNAVisualizerState();
}

class _BrainDNAVisualizerState extends State<BrainDNAVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DNAPainter(
            nodes: widget.nodes,
            rotation: _controller.value,
          ),
        );
      },
    );
  }
}

class _DNAPainter extends CustomPainter {
  final List<KnowledgeNode> nodes;
  final double rotation;

  _DNAPainter({required this.nodes, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.5;

    // 1. Draw central "Core" (The Brain)
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.8),
          AppTheme.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 40));
    
    canvas.drawCircle(center, 40, corePaint);
    
    // Draw core icon/glow
    final innerCorePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 15, innerCorePaint);

    // 2. Draw Nodes on orbital paths
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      
      // Calculate orbital angle
      final angleStep = (2 * math.pi) / nodes.length;
      final angle = (angleStep * i) + (rotation * 2 * math.pi);
      
      // Variation in radius for a more natural "organic" look
      final orbitRadius = baseRadius + (math.sin(rotation * 2 * math.pi + i) * 10);
      
      final nodePos = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      // Node Color based on Mastery
      Color nodeColor;
      if (node.retentionFactor < 0.5) {
        nodeColor = Colors.grey.shade400; // Fading
      } else if (node.masteryScore >= 0.8) {
        nodeColor = const Color(0xFF10B981); // Mastered (Emerald)
      } else if (node.masteryScore >= 0.5) {
        nodeColor = const Color(0xFFF59E0B); // Learning (Amber)
      } else {
        nodeColor = const Color(0xFFEF4444); // Struggling (Ruby)
      }

      // Draw Connection Line to Center
      final linePaint = Paint()
        ..color = nodeColor.withOpacity(0.15)
        ..strokeWidth = 1;
      canvas.drawLine(center, nodePos, linePaint);

      // Draw Orbital Ring (Subtle)
      final ringPaint = Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(center, orbitRadius, ringPaint);

      // Draw Node Glow
      final glowPaint = Paint()
        ..color = nodeColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(nodePos, 8 + (node.masteryScore * 6), glowPaint);

      // Draw Node Core
      final nodeCorePaint = Paint()..color = nodeColor;
      canvas.drawCircle(nodePos, 4 + (node.masteryScore * 4), nodeCorePaint);
      
      // Draw Label (Subtle)
      if (node.masteryScore > 0.2) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.name,
            style: TextStyle(
              color: nodeColor.withOpacity(0.8),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(
          canvas,
          Offset(nodePos.dx - textPainter.width / 2, nodePos.dy + 12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DNAPainter oldDelegate) => true;
}
