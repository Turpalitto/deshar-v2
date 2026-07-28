import 'package:flutter/material.dart';

/// Палитра с чеченским колоритом: горы, камень, зелень, один акцент.
abstract final class NokhchiinColors {
  // Природа / камень
  static const mountain = Color(0xFF4A5D4E);
  static const stone = Color(0xFF6B7280);
  static const stoneDark = Color(0xFF374151);
  static const meadow = Color(0xFF167D5A);
  static const meadowLight = Color(0xFFD9F2E5);
  static const sky = Color(0xFF2E6EAE);
  static const skyLight = Color(0xFFDDEBFA);

  // Акцент — терракотовый (орнамент, не кислотный)
  static const accent = Color(0xFFC95E3D);
  static const accentDark = Color(0xFFA9482D);
  static const accentLight = Color(0xFFFFE1D8);

  // Светлая тема
  static const lightBackground = Color(0xFFF4F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFE8EFEB);

  // Тёмная тема
  static const darkBackground = Color(0xFF1A1F1C);
  static const darkSurface = Color(0xFF252B27);
  static const darkSurfaceAlt = Color(0xFF2F3833);

  // Текст
  static const textPrimaryLight = Color(0xFF18211D);
  static const textSecondaryLight = Color(0xFF5F6D66);
  static const textPrimaryDark = Color(0xFFF0EDE8);
  static const textSecondaryDark = Color(0xFFA8B0AA);

  // Семантика
  static const success = Color(0xFF2D6A4F);
  static const successLight = Color(0xFFD8F0E4);
  static const warning = Color(0xFFB8860B);
  static const error = Color(0xFFB83B3B);
  static const errorLight = Color(0xFFFCE8E6);

  // Kids — живые, но приглушённые
  static const kidsSun = Color(0xFFFFD89B);
  static const kidsBerry = Color(0xFFE8B4CB);
  static const kidsLeaf = Color(0xFFA8D5BA);

  // Mastery
  static const masteryLow = Color(0xFFD1D5DB);
  static const masteryMid = Color(0xFF7EB8DA);
  static const masteryHigh = Color(0xFF5C8A6B);

  // Орнамент (тонкий декор)
  static const ornament = Color(0xFFC45C3E);
}
