import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Role-based Brand Colors ───────────────────────────────
  static const Color primary        = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight   = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryDark    = Color(0xFF4338CA); // Indigo 700

  static const Color secondary      = Color(0xFF10B981); // Emerald 500
  static const Color secondaryLight = Color(0xFFECFDF5); // Emerald 50

  static const Color parentColor    = Color(0xFFF59E0B); // Amber 500
  static const Color parentLight    = Color(0xFFFFFBEB); // Amber 50

  static const Color adminColor     = Color(0xFF334155); // Slate 700
  static const Color adminLight     = Color(0xFFF1F5F9); // Slate 50

  static const Color accent         = Color(0xFFF43F5E); // Rose 500
  static const Color danger         = Color(0xFFEF4444); // Red 500
  static const Color warning        = Color(0xFFF59E0B); // Amber 500
  static const Color success        = Color(0xFF22C55E); // Green 500
  static const Color info           = Color(0xFF3B82F6); // Blue 500

  static const Color bgLight        = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight   = Color(0xFFFFFFFF);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color muted          = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimary    = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary  = Color(0xFF475569); // Slate 600
  static const Color textHint       = Color(0xFF94A3B8); // Slate 400
  static const Color borderLight    = Color(0xFFE2E8F0); // Slate 200
  static const Color borderStrong   = Color(0xFFCBD5E1); // Slate 300

  static const List<Color> subjectColors = [
    Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444),
    Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFFEC4899),
  ];

  static const LinearGradient meshGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studentGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> softShadow(Color color) => [
    BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, spreadRadius: 0, offset: const Offset(0, 2)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 20, spreadRadius: 0, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 6, spreadRadius: 0, offset: Offset(0, 1)),
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, secondary: secondary, brightness: Brightness.light),
    scaffoldBackgroundColor: bgLight,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: textPrimary),
      titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: textPrimary),
      bodyLarge: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 16),
      bodyMedium: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 14),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white.withOpacity(0.84),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: textPrimary,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 22,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: textPrimary,
      unselectedLabelColor: textHint,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      dividerColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 2)),
      hintStyle: const TextStyle(color: textHint),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF11111B),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white70),
    ),
  );
}
