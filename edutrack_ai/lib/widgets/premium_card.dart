import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.gradientColors,
    this.blur = 10.0,
    this.opacity = 0.8,
    this.borderRadius = 16.0,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: gradientColors == null
          ? (isDark ? const Color(0xFF1E293B).withOpacity(0.8) : AppTheme.surfaceLight.withOpacity(opacity))
          : null,
      gradient: gradientColors == null
          ? null
          : LinearGradient(
              colors: gradientColors!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : (gradientColors == null ? AppTheme.borderLight : Colors.white.withOpacity(0.18)),
      ),
      boxShadow: isDark ? [] : AppTheme.cardShadow,
    );

    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
