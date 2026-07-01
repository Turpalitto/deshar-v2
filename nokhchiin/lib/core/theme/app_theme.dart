import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/enums.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData theme({AppMode mode = AppMode.kids, KidsAgeGroup age = KidsAgeGroup.age6to9}) {
    final isKids = mode == AppMode.kids;
    final isAdult = mode == AppMode.adult;
    final scale = isKids
        ? switch (age) {
            KidsAgeGroup.age3to6 => 1.15,
            KidsAgeGroup.age6to9 => 1.0,
            KidsAgeGroup.age9to12 => 0.95,
          }
        : 0.92;

    final primary = isAdult ? const Color(0xFF1A73E8) : AppColors.primary;
    final scaffoldBg = isKids ? AppColors.background : const Color(0xFFF1F5F9);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: primary,
        barBackgroundColor: AppColors.surface,
      ),
      textTheme: _textTheme(scale),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isAdult ? scaffoldBg : AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isAdult ? 0 : 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isKids ? 24 : 14),
          side: const BorderSide(color: Color(0xFFE8EAED)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: (isKids ? 18 : 14) * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isKids ? 20 : 12),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 16 * scale,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isAdult ? 12 : 14),
          borderSide: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isAdult ? 12 : 14),
          borderSide: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isAdult ? 12 : 14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8EAED), thickness: 1),
    );
  }

  static TextTheme _textTheme(double scale) => TextTheme(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32 * scale,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 22 * scale,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 13 * scale,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );
}
