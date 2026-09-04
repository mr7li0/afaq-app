import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../constants/color_constants.dart';

/// Afaq App Theme — iOS-style Minimalist Glassmorphism Design
class AppTheme {
  AppTheme._();

  // ── Light Theme (default — always dark-ish slate) ──
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      fontFamily: AppConstants.fontArabic,

      // ── Color Scheme ───────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
        surface: AppColors.backgroundSecondary,
        error: AppColors.starRed,
        onPrimary: AppColors.backgroundPrimary,
        onSecondary: AppColors.backgroundPrimary,
        onSurface: AppColors.textPrimary,
      ),

      // ── App Bar ────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Bottom Navigation ──────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.glassFill,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 11,
        ),
      ),

      // ── Cards ──────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusCards),
          side: const BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.defaultPaddingSmall,
        ),
      ),

      // ── Elevated Button ────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppConstants.fontArabic,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppConstants.fontArabic,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Input Decoration ───────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontFamily: AppConstants.fontArabic,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadiusStadium)),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadiusStadium)),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadiusStadium)),
          borderSide: BorderSide(color: AppColors.textPrimary, width: 1.5),
        ),
      ),

      // ── Icon Theme ─────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // ── Divider ────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Text Theme ─────────────────────────────────
      textTheme: const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        // Headlines
        headlineLarge: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Titles
        titleLarge: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        // Body
        bodyLarge: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
          height: 1.4,
        ),
        // Labels
        labelLarge: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: AppConstants.fontArabic,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
