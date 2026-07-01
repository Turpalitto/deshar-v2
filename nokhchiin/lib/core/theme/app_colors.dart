import 'package:flutter/material.dart';

/// Премиальная палитра 2026 — без кислотных цветов, без Material «из коробки».
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1A73E8);
  static const primaryDark = Color(0xFF1557B0);
  static const primaryLight = Color(0xFFE8F0FE);

  // Surfaces
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFAFBFC);

  // Text
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);

  // Semantic
  static const success = Color(0xFF0D904F);
  static const successLight = Color(0xFFE6F4EA);
  static const warning = Color(0xFFE8710A);
  static const error = Color(0xFFD93025);
  static const errorLight = Color(0xFFFCE8E6);

  // Kids — мягкие пастельные акценты
  static const kidsSky = Color(0xFFB8D4F0);
  static const kidsMeadow = Color(0xFFC8E6C9);
  static const kidsSunset = Color(0xFFFFE0B2);
  static const kidsLavender = Color(0xFFE1D5F0);

  // Mastery gradient stops
  static const mastery0 = Color(0xFFE5E7EB);
  static const mastery3 = Color(0xFF93C5FD);
  static const mastery5 = Color(0xFF34D399);
}
