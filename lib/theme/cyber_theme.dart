// lib/theme/cyber_theme.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — Design System
//  Dark obsidian base · Neon cyan/purple accents · Glow effects
//  Fonts: Orbitron (display/headings) · ShareTechMono (labels/terminal)
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────
//  COLOR PALETTE
// ──────────────────────────────────────────────────────────────
class CyberColors {
  CyberColors._();

  // ── Backgrounds ──
  static const Color bgDeep       = Color(0xFF040A0F);   // obsidian black
  static const Color bgBase       = Color(0xFF060D18);   // primary dark
  static const Color bgMid        = Color(0xFF0A1628);   // panel background
  static const Color bgCard       = Color(0xFF0C1A2E);   // card surface
  static const Color bgCardLight  = Color(0xFF112236);   // elevated card
  static const Color bgOverlay    = Color(0xFF060D18CC); // 80% overlay

  // ── Neon Accents ──
  static const Color neonCyan     = Color(0xFF00E5FF);
  static const Color neonPurple   = Color(0xFFBB86FC);
  static const Color neonBlue     = Color(0xFF448AFF);
  static const Color neonGreen    = Color(0xFF00E676);
  static const Color neonRed      = Color(0xFFFF1744);
  static const Color neonAmber    = Color(0xFFFFAB00);

  // ── Text ──
  static const Color textPrimary  = Color(0xFFD8EEF8);
  static const Color textSecondary= Color(0xFF7A9DB8);
  static const Color textMuted    = Color(0xFF3A5570);
  static const Color textOnNeon   = Color(0xFF040A0F);

  // ── Borders ──
  static const Color borderSubtle = Color(0xFF142030);
  static const Color borderGlow   = Color(0xFF00E5FF22);

  // ── Gradients ──
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF040A0F), Color(0xFF060D18), Color(0xFF040A0F)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF112236), Color(0xFF0A1628)],
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
    BoxShadow(color: CyberColors.neonCyan.withOpacity(0.32 * intensity), blurRadius: 18),
    BoxShadow(color: CyberColors.neonCyan.withOpacity(0.12 * intensity), blurRadius: 36, spreadRadius: 2),
  ];

  static List<BoxShadow> neonPurple({double intensity = 1.0}) => [
    BoxShadow(color: CyberColors.neonPurple.withOpacity(0.32 * intensity), blurRadius: 18),
    BoxShadow(color: CyberColors.neonPurple.withOpacity(0.10 * intensity), blurRadius: 36, spreadRadius: 2),
  ];

  static List<BoxShadow> card = [
    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: CyberColors.neonCyan.withOpacity(0.03), blurRadius: 20, spreadRadius: 1),
  ];

  static List<BoxShadow> danger({double intensity = 1.0}) => [
    BoxShadow(color: CyberColors.neonRed.withOpacity(0.35 * intensity), blurRadius: 18),
  ];

  static List<BoxShadow> success({double intensity = 1.0}) => [
    BoxShadow(color: CyberColors.neonGreen.withOpacity(0.35 * intensity), blurRadius: 18),
  ];
}

// ──────────────────────────────────────────────────────────────
//  TEXT STYLES
//  Orbitron  → display, headings, section titles
//  Inter → body text, labels, captions (readable sans-serif)
//  ShareTechMono → terminal/monospace data labels only
// ──────────────────────────────────────────────────────────────
class CyberText {
  CyberText._();

  // Display / Hero — Orbitron
  static TextStyle get displayLarge => GoogleFonts.orbitron(
    fontSize: 40, fontWeight: FontWeight.w700,
    color: CyberColors.neonCyan, letterSpacing: 2.0, height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.orbitron(
    fontSize: 30, fontWeight: FontWeight.w700,
    color: CyberColors.neonCyan, letterSpacing: 1.5,
  );

  static TextStyle get displaySmall => GoogleFonts.orbitron(
    fontSize: 22, fontWeight: FontWeight.w600,
    color: CyberColors.neonCyan, letterSpacing: 1.0,
  );

  // Section titles — Orbitron
  static TextStyle get sectionTitle => GoogleFonts.orbitron(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: CyberColors.neonCyan, letterSpacing: 1.0,
  );

  // Body — ShareTechMono for that terminal feel
  // Body — Inter for readability
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 15, color: CyberColors.textPrimary, height: 1.65,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 13, color: CyberColors.textPrimary, height: 1.55,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, color: CyberColors.textSecondary, height: 1.5,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 10.5, color: CyberColors.textMuted, letterSpacing: 0.2,
  );

  // Labels — ShareTechMono for terminal / monospace data labels only
  static TextStyle get label => GoogleFonts.shareTechMono(
    fontSize: 11, color: CyberColors.neonCyan, letterSpacing: 1.5,
    fontWeight: FontWeight.bold,
  );

  static TextStyle neonPurple({double size = 14}) => GoogleFonts.inter(
    fontSize: size, color: CyberColors.neonPurple, letterSpacing: 0.2,
  );
}

// ──────────────────────────────────────────────────────────────
//  BORDER RADIUS
// ──────────────────────────────────────────────────────────────
class CyberRadius {
  CyberRadius._();
  static const BorderRadius small  = BorderRadius.all(Radius.circular(6));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(10));
  static const BorderRadius large  = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pill   = BorderRadius.all(Radius.circular(999));
  static const BorderRadius cutTop = BorderRadius.only(
    topLeft: Radius.circular(12), topRight: Radius.circular(3),
    bottomLeft: Radius.circular(3), bottomRight: Radius.circular(12),
  );
}

// ──────────────────────────────────────────────────────────────
//  THEME DATA
// ──────────────────────────────────────────────────────────────
ThemeData buildCyberTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CyberColors.bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: CyberColors.neonCyan,
      secondary: CyberColors.neonPurple,
      surface: CyberColors.bgCard,
      onPrimary: CyberColors.textOnNeon,
      onSecondary: CyberColors.textOnNeon,
      onSurface: CyberColors.textPrimary,
      error: CyberColors.neonRed,
    ),
    textTheme: TextTheme(
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
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3),
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
      labelStyle: GoogleFonts.inter(color: CyberColors.textSecondary),
      hintStyle: GoogleFonts.inter(color: CyberColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: CyberColors.borderSubtle,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CyberColors.bgCardLight,
      contentTextStyle: GoogleFonts.inter(color: CyberColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: CyberRadius.medium),
      behavior: SnackBarBehavior.floating,
    ),
  );
}