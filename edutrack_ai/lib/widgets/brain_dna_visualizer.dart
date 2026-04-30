import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/knowledge_node.dart';
import '../utils/app_theme.dart';

class BrainDNAVisualizer extends StatefulWidget {
  final List<KnowledgeNode> nodes;
  final double size;
  final bool enableInteractions;

  const BrainDNAVisualizer({
    super.key,
    required this.nodes,
    this.size = 300,
    this.enableInteractions = true,
  });

  @override
  State<BrainDNAVisualizer> createState() => _BrainDNAVisualizerState();
}

class _BrainDNAVisualizerState extends State<BrainDNAVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  KnowledgeNode? _hoveredNode;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enableInteractions) return;
    
    // Create painter and manually call paint to populate nodePositions
    final painter = _DNAPainter(
      nodes: widget.nodes,
      rotation: _rotationController.value,
      pulse: _pulseController.value,
      size: widget.size,
    );
    
    // Use a dummy canvas and size to trigger paint and populate nodePositions
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, Size(widget.size, widget.size));
    
    final localPosition = details.localPosition;
    for (final nodePos in painter.nodePositions) {
      final distance = (localPosition - nodePos.position).distance;
      if (distance < 25) {
        setState(() {
          _hoveredNode = nodePos.node;
          _tapPosition = nodePos.position;
        });
        return;
      }
    }
    setState(() {
      _hoveredNode = null;
      _tapPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return GestureDetector(
          onTapDown: _onTapDown,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _DNAPainter(
              nodes: widget.nodes,
              rotation: _rotationController.value,
              pulse: _pulseController.value,
              size: widget.size,
            ),
            foregroundPainter: _hoveredNode != null && _tapPosition != null
                ? _TooltipPainter(
                    node: _hoveredNode!,
                    position: _tapPosition!,
                    size: widget.size,
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _NodePosition {
  final KnowledgeNode node;
  final Offset position;
  final double orbitRadius;
  final Color color;

  _NodePosition({
    required this.node,
    required this.position,
    required this.orbitRadius,
    required this.color,
  });
}

class _DNAPainter extends CustomPainter {
  final List<KnowledgeNode> nodes;
  final double rotation;
  final double pulse;
  final double size;
  List<_NodePosition> nodePositions = [];

  _DNAPainter({
    required this.nodes,
    required this.rotation,
    required this.pulse,
    required this.size,
  });

  // Subject color mapping for distinct orbits
  final Map<String, Color> _subjectColors = {
    'Mathematics': const Color(0xFF6366F1), // Indigo
    'Science': const Color(0xFF10B981),     // Emerald
    'English': const Color(0xFFF59E0B),   // Amber
    'Computer Science': const Color(0xFFEC4899), // Pink
    'History': const Color(0xFF8B5CF6),     // Violet
    'Geography': const Color(0xFF06B6D4),   // Cyan
    'Physics': const Color(0xFF3B82F6),     // Blue
    'Chemistry': const Color(0xFF10B981),     // Emerald
    'Biology': const Color(0xFF84CC16),     // Lime
  };

  Color _getMasteryColor(KnowledgeNode node) {
    return AppTheme.primary; // Use a single consistent color as requested
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Clear previous positions
    nodePositions = [];
    
    if (nodes.isEmpty) return;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final baseRadius = canvasSize.width / 3;

    // Group nodes by subject for orbital organization
    final Map<String, List<KnowledgeNode>> subjectGroups = {};
    for (final node in nodes) {
      subjectGroups.putIfAbsent(node.subject, () => []).add(node);
    }

    // Draw background gradient rings
    _drawBackgroundRings(canvas, center, baseRadius);

    // Draw central "Neural Core"
    _drawNeuralCore(canvas, center);

    // Draw orbital paths and nodes by subject
    final subjects = subjectGroups.keys.toList();
    final double orbitStep = (baseRadius * 0.6) / math.max(subjects.length, 1);

    for (int s = 0; s < subjects.length; s++) {
      final subject = subjects[s];
      final subjectNodes = subjectGroups[subject]!;
      final orbitRadius = baseRadius * 0.4 + (orbitStep * s);
      final subjectBaseColor = _subjectColors[subject] ?? AppTheme.primary;

      // Draw orbital ring with subject color
      _drawOrbitalRing(canvas, center, orbitRadius, subjectBaseColor, s);

      // Draw connections between nodes in same subject (neural web)
      _drawNeuralConnections(canvas, center, subjectNodes, orbitRadius, s);

      // Draw nodes
      for (int i = 0; i < subjectNodes.length; i++) {
        final node = subjectNodes[i];
        final angleStep = (2 * math.pi) / subjectNodes.length;
        final angleOffset = (rotation * 2 * math.pi * (s % 2 == 0 ? 1 : -1)) + (s * 0.5);
        final angle = (angleStep * i) + angleOffset;

        // Add organic movement
        final wobble = math.sin(rotation * 2 * math.pi * 2 + i + s) * 5;
        final finalRadius = orbitRadius + wobble;

        final nodePos = Offset(
          center.dx + finalRadius * math.cos(angle),
          center.dy + finalRadius * math.sin(angle),
        );

        final nodeColor = _getMasteryColor(node);

        nodePositions.add(_NodePosition(
          node: node,
          position: nodePos,
          orbitRadius: finalRadius,
          color: nodeColor,
        ));

        // Draw connection to center (neural pathway)
        _drawNeuralPathway(canvas, center, nodePos, nodeColor, node.masteryScore);

        // Draw node with enhanced visuals
        _drawEnhancedNode(canvas, nodePos, node, nodeColor, subjectBaseColor);
      }
    }

    // Draw center glow overlay
    _drawCenterGlow(canvas, center);
  }

  void _drawBackgroundRings(Canvas canvas, Offset center, double baseRadius) {
    // Outer subtle rings
    for (int i = 3; i > 0; i--) {
      final ringPaint = Paint()
        ..color = AppTheme.primary.withOpacity(0.03 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(center, baseRadius * (0.3 + (i * 0.2)), ringPaint);
    }
  }

  void _drawNeuralCore(Canvas canvas, Offset center) {
    // Outer glow
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.4),
          AppTheme.primary.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 45));
    canvas.drawCircle(center, 45 + (pulse * 5), outerGlow);

    // Core body
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          AppTheme.primary.withOpacity(0.8),
          AppTheme.primary.withOpacity(0.4),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 25));
    canvas.drawCircle(center, 25, corePaint);

    // Inner pulse
    final innerPulse = Paint()
      ..color = Colors.white.withOpacity(0.6 + (pulse * 0.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 12 + (pulse * 3), innerPulse);

    // Center dot
    final centerDot = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, centerDot);
  }

  void _drawOrbitalRing(Canvas canvas, Offset center, double radius, Color color, int index) {
    final ringPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
          color.withOpacity(0.15),
        ],
        transform: GradientRotation(rotation * math.pi * 2 + index),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(center, radius, ringPaint);

    // Decorative arc segments
    final segmentPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final segmentLength = math.pi / 6;
    final segmentAngle = rotation * math.pi * 2 + (index * 1.2);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      segmentAngle,
      segmentLength,
      false,
      segmentPaint,
    );
  }

  void _drawNeuralConnections(Canvas canvas, Offset center, List<KnowledgeNode> nodes, 
      double orbitRadius, int subjectIndex) {
    if (nodes.length < 2) return;

    final connectionPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final angleStep = (2 * math.pi) / nodes.length;
        final angleOffset = (rotation * 2 * math.pi * (subjectIndex % 2 == 0 ? 1 : -1)) + 
            (subjectIndex * 0.5);
        
        final angle1 = (angleStep * i) + angleOffset;
        final angle2 = (angleStep * j) + angleOffset;

        final pos1 = Offset(
          center.dx + orbitRadius * math.cos(angle1),
          center.dy + orbitRadius * math.sin(angle1),
        );
        final pos2 = Offset(
          center.dx + orbitRadius * math.cos(angle2),
          center.dy + orbitRadius * math.sin(angle2),
        );

        // Only draw connections for nearby nodes
        if ((pos1 - pos2).distance < orbitRadius * 1.2) {
          canvas.drawLine(pos1, pos2, connectionPaint);
        }
      }
    }
  }

  void _drawNeuralPathway(Canvas canvas, Offset center, Offset nodePos, Color color, 
      double mastery) {
    final pathwayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment(nodePos.dx - center.dx, nodePos.dy - center.dy),
        colors: [
          color.withOpacity(0.3 * mastery),
          color.withOpacity(0.05),
        ],
      ).createShader(Rect.fromPoints(center, nodePos))
      ..strokeWidth = 1 + (mastery * 2)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, nodePos, pathwayPaint);

    // Add energy particles along the path
    final particleCount = (mastery * 3).ceil();
    for (int i = 0; i < particleCount; i++) {
      final t = (rotation * (i + 1) + (i * 0.3)) % 1.0;
      final particlePos = Offset.lerp(center, nodePos, t)!;
      final particlePaint = Paint()
        ..color = color.withOpacity(0.6 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(particlePos, 2, particlePaint);
    }
  }

  void _drawEnhancedNode(Canvas canvas, Offset position, KnowledgeNode node, 
      Color color, Color subjectColor) {
    final mastery = node.masteryScore;
    final retention = node.retentionFactor;

    // Outer glow (pulsing for high mastery)
    final glowIntensity = retention < 0.5 
        ? 0.2 
        : 0.3 + (mastery > 0.7 ? pulse * 0.2 : 0);
    
    final glowPaint = Paint()
      ..color = color.withOpacity(glowIntensity)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal, 
        6 + (mastery * 4) + (mastery > 0.7 ? pulse * 4 : 0),
      );
    canvas.drawCircle(position, 10 + (mastery * 8), glowPaint);

    // Ring indicator for retention
    if (retention < 1.0) {
      final retentionPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, 14 + (mastery * 6), retentionPaint);

      // Retention arc
      final retentionArcPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: position, radius: 14 + (mastery * 6)),
        -math.pi / 2,
        (2 * math.pi) * retention,
        false,
        retentionArcPaint,
      );
    }

    // Main node body
    final nodePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          color,
          color.withOpacity(0.8),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: 10));
    
    canvas.drawCircle(position, 6 + (mastery * 6), nodePaint);

    // Shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(position.dx - 2, position.dy - 2), 
      2 + (mastery * 2), 
      shinePaint,
    );

    // Label with better visibility
    if (mastery > 0.15) {
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: node.name,
              style: TextStyle(
                color: color.withOpacity(retention < 0.5 ? 0.5 : 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      // Position label below node
      textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2, position.dy + 16),
      );

      // Mastery percentage for high mastery nodes
      if (mastery >= 0.5) {
        final percentPainter = TextPainter(
          text: TextSpan(
            text: '${(mastery * 100).toInt()}%',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        percentPainter.paint(
          canvas,
          Offset(position.dx - percentPainter.width / 2, position.dy + 26),
        );
      }
    }
  }

  void _drawCenterGlow(Canvas canvas, Offset center) {
    // Final overlay glow
    final overlayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawCircle(center, 20, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _DNAPainter oldDelegate) => true;
}

// Tooltip painter for showing node details on tap
class _TooltipPainter extends CustomPainter {
  final KnowledgeNode node;
  final Offset position;
  final double size;

  _TooltipPainter({
    required this.node,
    required this.position,
    required this.size,
  });

  Color _getStatusColor() {
    return AppTheme.primary;
  }

  String _getStatusText() {
    if (node.retentionFactor < 0.5) return 'Fading - Review Needed';
    if (node.masteryScore >= 0.8) return 'Mastered';
    if (node.masteryScore >= 0.5) return 'Learning in Progress';
    return 'Needs Attention';
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final color = _getStatusColor();
    
    // Tooltip background
    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(position.dx, position.dy - 50),
        width: 140,
        height: 70,
      ),
      const Radius.circular(12),
    );

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(tooltipRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(tooltipRect, borderPaint);

    // Arrow
    final arrowPath = Path()
      ..moveTo(position.dx - 8, position.dy - 15)
      ..lineTo(position.dx + 8, position.dy - 15)
      ..lineTo(position.dx, position.dy - 8)
      ..close();
    
    final arrowPaint = Paint()..color = Colors.white.withOpacity(0.95);
    canvas.drawPath(arrowPath, arrowPaint);

    // Text: Node name
    final namePainter = TextPainter(
      text: TextSpan(
        text: node.name,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    namePainter.paint(
      canvas,
      Offset(position.dx - namePainter.width / 2, position.dy - 70),
    );

    // Text: Subject
    final subjectPainter = TextPainter(
      text: TextSpan(
        text: node.subject,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    subjectPainter.paint(
      canvas,
      Offset(position.dx - subjectPainter.width / 2, position.dy - 55),
    );

    // Text: Status
    final statusPainter = TextPainter(
      text: TextSpan(
        text: _getStatusText(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    statusPainter.paint(
      canvas,
      Offset(position.dx - statusPainter.width / 2, position.dy - 40),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
