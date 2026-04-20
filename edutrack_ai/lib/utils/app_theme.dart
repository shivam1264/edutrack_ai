import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Role-based Brand Colors ───────────────────────────────
  // Student: Indigo/Violet (learning, calm, focused)
  static const Color primary        = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight   = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryDark    = Color(0xFF4338CA); // Indigo 700

  // Teacher: Emerald (growth, nature, health)
  static const Color secondary      = Color(0xFF10B981); // Emerald 500
  static const Color secondaryLight = Color(0xFFECFDF5); // Emerald 50

  // Parent: Amber (warmth, family, care)
  static const Color parentColor    = Color(0xFFF59E0B); // Amber 500
  static const Color parentLight    = Color(0xFFFFFBEB); // Amber 50

  // Admin: Slate (authority, enterprise)
  static const Color adminColor     = Color(0xFF334155); // Slate 700
  static const Color adminLight     = Color(0xFFF1F5F9); // Slate 50

  // System colors
  static const Color accent         = Color(0xFFF43F5E); // Rose 500
  static const Color danger         = Color(0xFFEF4444); // Red 500
  static const Color warning        = Color(0xFFF59E0B); // Amber 500
  static const Color success        = Color(0xFF22C55E); // Green 500
  static const Color info           = Color(0xFF3B82F6); // Blue 500

  // ─── Neutral Palette (8-shade system) ──────────────────────
  static const Color bgLight        = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight   = Color(0xFFFFFFFF);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color muted          = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimary    = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary  = Color(0xFF475569); // Slate 600
  static const Color textHint       = Color(0xFF94A3B8); // Slate 400
  static const Color borderLight    = Color(0xFFE2E8F0); // Slate 200
  static const Color borderStrong   = Color(0xFFCBD5E1); // Slate 300

  // ─── Subject Colors (for consistent coding) ────────────────
  static const List<Color> subjectColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
  ];

  // ─── Premium Gradients ─────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studentGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient teacherGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient parentGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Keep meshGradient for backward compatibility
  static const LinearGradient meshGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ───────────────────────────────────────────────
  static List<BoxShadow> softShadow(Color color) => [
    BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, spreadRadius: 0, offset: const Offset(0, 2)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 20, spreadRadius: 0, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 6, spreadRadius: 0, offset: Offset(0, 1)),
  ];

  // ─── Border Radius Scale ───────────────────────────────────
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radius2xl  = 24.0;
  static const double radius3xl  = 32.0;

  // ─── Material Theme ────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.light,
      surface: surfaceLight,
      background: bgLight,
    ),
    scaffoldBackgroundColor: bgLight,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge:  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: textPrimary),
      displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: textPrimary),
      displaySmall:  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textPrimary),
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 28),
      headlineMedium:GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 24),
      headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 20),
      titleLarge:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 18),
      titleMedium:   GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 16),
      titleSmall:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 14),
      bodyLarge:     GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: textPrimary, fontSize: 16),
      bodyMedium:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: textSecondary, fontSize: 14),
      bodySmall:     GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: textHint, fontSize: 12),
      labelLarge:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 14),
      labelMedium:   GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12),
      labelSmall:    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textHint, fontSize: 10),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceLight,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius2xl),
        side: const BorderSide(color: borderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: muted,
      labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
      hintStyle:  GoogleFonts.plusJakartaSans(color: textHint, fontSize: 14),
      prefixIconColor: primary,
      suffixIconColor: textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: surfaceLight,
      elevation: 0,
      indicatorColor: primaryLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: primary);
        }
        return GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12, color: textHint);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: Colors.grey, size: 22);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: muted,
      selectedColor: primaryLight,
      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
  );
}
