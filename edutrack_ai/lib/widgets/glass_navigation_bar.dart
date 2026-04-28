import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GlassNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Color accentColor;
  final Color secondaryColor;

  const GlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final panelColor = Color.alphaBlend(
      accentColor.withOpacity(0.08),
      Colors.white.withOpacity(0.88),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.78),
                  panelColor,
                  secondaryColor.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.16),
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 80,
                backgroundColor: Colors.transparent,
                indicatorColor: accentColor.withOpacity(0.16),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    );
                  }
                  return const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHint,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(
                      color: accentColor,
                      size: 26,
                    );
                  }
                  return const IconThemeData(
                    color: AppTheme.textHint,
                    size: 24,
                  );
                }),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
