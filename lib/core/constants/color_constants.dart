import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Main Colors ────────────────────────────────
  static const Color primary = Color(0xFF6A7C7E);
  static const Color ivory = Color(0xFFF3ECD9);

  // ── Backgrounds ────────────────────────────────
  static const Color cardDark = Color(0xFF3E4E56);
  static const Color cardElevated = Color(0xFF2D3940);
  static const Color cardBorder = Color(0x33FDFBF7);

  // ── Text ───────────────────────────────────────
  static const Color textHint = Color(0xFF9BA5AB);

  // ── Legacy aliases (old files) ─────────────────
  static const Color backgroundPrimary = Color(0xFF3E4E56);
  static const Color backgroundSecondary = Color(0xFF2D3940);
  static const Color backgroundTertiary = Color(0xFF1F2B33);
  static const Color textPrimary = Color(0xFFFDFBF7);
  static const Color textSecondary = Color(0xFFE5DFD3);
  static const Color slateBackground = Color(0xFF3E4E56);

  // ── Glassmorphism ──────────────────────────────
  static const Color glassFill = Color(0x592D3940);
  static const Color glassSurface = Color(0x1AFDFBF7);
  static const Color glassBorder = Color(0x26FDFBF7);
  static const Color glassHighlight = Color(0x1AFFFFFF);
  static const Color glassBorder20 = Color(0x33FDFBF7);

  // ── Semantic ───────────────────────────────────
  static const Color accentGreen = Color(0xFF7EC8A0);
  static const Color starYellow = Color(0xFFFFD54F);
  static const Color starRed = Color(0xFFEF5350);
  static const Color accentOrange = Color(0xFFFFAB76);
  static const Color accentBlue = Color(0xFF81B4D8);
  static const Color goldAccent = Color(0xFFE2B93B);

  // ── Prayer Colors ──────────────────────────────
  static const Color fajr = Color(0xFF1A237E);
  static const Color sunrise = Color(0xFFFFB74D);
  static const Color dhuhr = Color(0xFF4FC3F7);
  static const Color asr = Color(0xFFFF8A65);
  static const Color maghrib = Color(0xFFE57373);
  static const Color isha = Color(0xFF5C6BC0);
  static const Color night = Color(0xFF283593);

  // ── Card Shadow ────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.primary,
    fontFamily: 'Milan',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.ivory,
      surface: AppColors.cardDark,
    ),
  );
}
