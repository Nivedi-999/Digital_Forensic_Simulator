// lib/theme/cyber_theme.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — Design System
//  Dark navy base · Neon cyan/purple accents · Glow effects
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────
//  COLOR PALETTE
// ──────────────────────────────────────────────────────────────
class CyberColors {
  CyberColors._();

  // ── Backgrounds ──
  static const Color bgDeep       = Color(0xFF060D17);   // near-black navy
  static const Color bgBase       = Color(0xFF0B1C2D);   // primary dark navy
  static const Color bgMid        = Color(0xFF0F2540);   // panel background
  static const Color bgCard       = Color(0xFF112236);   // card surface
  static const Color bgCardLight  = Color(0xFF163050);   // elevated card
  static const Color bgOverlay    = Color(0xFF0B1C2Dcc); // 80% opacity overlay

  // ── Neon Accents ──
  static const Color neonCyan     = Color(0xFF00E5FF);   // primary accent
  static const Color neonPurple   = Color(0xFFBB86FC);   // secondary accent
  static const Color neonBlue     = Color(0xFF448AFF);   // tertiary accent
  static const Color neonGreen    = Color(0xFF00E676);   // success/confirmed
  static const Color neonRed      = Color(0xFFFF1744);   // danger/wrong
  static const Color neonAmber    = Color(0xFFFFAB00);   // warning/partial

  // ── Text ──
  static const Color textPrimary  = Color(0xFFE8F4FD);
  static const Color textSecondary= Color(0xFF8BAFC9);
  static const Color textMuted    = Color(0xFF4A6B8A);
  static const Color textOnNeon   = Color(0xFF060D17);   // text on bright buttons

  // ── Borders ──
  static const Color borderSubtle = Color(0xFF1A3A5C);
  static const Color borderGlow   = Color(0xFF00E5FF33); // 20% cyan border

  // ── Gradients ──
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF060D17), Color(0xFF0B1C2D), Color(0xFF071525)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF163050), Color(0xFF0F2540)],
  );

  static const LinearGradient neonCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
  );

  static const LinearGradient neonPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBB86FC), Color(0xFF7C4DFF)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
  );
}

// ──────────────────────────────────────────────────────────────
//  SHADOWS & GLOWS
// ──────────────────────────────────────────────────────────────
class CyberShadows {
  CyberShadows._();

  static List<BoxShadow> neonCyan({double intensity = 1.0}) => [
    BoxShadow(
      color: CyberColors.neonCyan.withOpacity(0.35 * intensity),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: CyberColors.neonCyan.withOpacity(0.15 * intensity),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> neonPurple({double intensity = 1.0}) => [
    BoxShadow(
      color: CyberColors.neonPurple.withOpacity(0.35 * intensity),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: CyberColors.neonPurple.withOpacity(0.12 * intensity),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: CyberColors.neonCyan.withOpacity(0.04),
      blurRadius: 24,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> danger({double intensity = 1.0}) => [
    BoxShadow(
      color: CyberColors.neonRed.withOpacity(0.35 * intensity),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> success({double intensity = 1.0}) => [
    BoxShadow(
      color: CyberColors.neonGreen.withOpacity(0.35 * intensity),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
}

// ──────────────────────────────────────────────────────────────
//  TEXT STYLES
// ──────────────────────────────────────────────────────────────
class CyberText {
  CyberText._();

  // Display / Hero
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'DotMatrix',
    fontSize: 42,
    color: CyberColors.neonCyan,
    letterSpacing: 2.0,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'DotMatrix',
    fontSize: 32,
    color: CyberColors.neonCyan,
    letterSpacing: 1.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'DotMatrix',
    fontSize: 24,
    color: CyberColors.neonCyan,
    letterSpacing: 1.0,
  );

  // Section titles
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'DotMatrix',
    fontSize: 18,
    color: CyberColors.neonCyan,
    letterSpacing: 1.2,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: CyberColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: CyberColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: CyberColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: CyberColors.textMuted,
    letterSpacing: 0.5,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontFamily: 'DotMatrix',
    fontSize: 12,
    color: CyberColors.neonCyan,
    letterSpacing: 1.5,
  );

  static TextStyle neonPurple({double size = 16}) => TextStyle(
    fontSize: size,
    color: CyberColors.neonPurple,
    letterSpacing: 0.5,
  );
}

// ──────────────────────────────────────────────────────────────
//  BORDER RADIUS CONSTANTS
// ──────────────────────────────────────────────────────────────
class CyberRadius {
  CyberRadius._();

  static const BorderRadius small  = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(14));
  static const BorderRadius large  = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pill   = BorderRadius.all(Radius.circular(999));

  // Asymmetric "cyber cut" corners
  static const BorderRadius cutTop = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(16),
  );
}

// ──────────────────────────────────────────────────────────────
//  THEME DATA
// ──────────────────────────────────────────────────────────────
ThemeData buildCyberTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CyberColors.bgBase,
    colorScheme: const ColorScheme.dark(
      primary: CyberColors.neonCyan,
      secondary: CyberColors.neonPurple,
      surface: CyberColors.bgCard,
      onPrimary: CyberColors.textOnNeon,
      onSecondary: CyberColors.textOnNeon,
      onSurface: CyberColors.textPrimary,
      error: CyberColors.neonRed,
    ),
    textTheme: const TextTheme(
      displayLarge: CyberText.displayLarge,
      bodyLarge: CyberText.bodyLarge,
      bodyMedium: CyberText.bodyMedium,
      bodySmall: CyberText.bodySmall,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CyberColors.neonCyan,
        foregroundColor: CyberColors.textOnNeon,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: CyberRadius.medium),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CyberColors.neonCyan,
        side: const BorderSide(color: CyberColors.neonCyan, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: CyberRadius.medium),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CyberColors.bgMid,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: CyberRadius.medium,
        borderSide: const BorderSide(color: CyberColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: CyberRadius.medium,
        borderSide: const BorderSide(color: CyberColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: CyberRadius.medium,
        borderSide: const BorderSide(color: CyberColors.neonCyan, width: 1.5),
      ),
      labelStyle: const TextStyle(color: CyberColors.textSecondary),
      hintStyle: const TextStyle(color: CyberColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: CyberColors.borderSubtle,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CyberColors.bgCardLight,
      contentTextStyle: const TextStyle(color: CyberColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: CyberRadius.medium),
      behavior: SnackBarBehavior.floating,
    ),
  );
}