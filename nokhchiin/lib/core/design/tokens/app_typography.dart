import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nokhchiin_colors.dart';

/// Manrope — единая семья с design_system/typography.dart (Noto Sans был
/// вторым, рассинхронным шрифтом в Material-теме). Кириллица + cyrillic-ext
/// (Ӏ, къ, гӏ, хь, аь) покрыты.
abstract final class AppTypography {
  static String get _fontFamily => GoogleFonts.manrope().fontFamily!;

  static TextTheme textTheme({
    required bool isDark,
    required double scale,
  }) {
    final primary = isDark ? NokhchiinColors.textPrimaryDark : NokhchiinColors.textPrimaryLight;
    final secondary =
        isDark ? NokhchiinColors.textSecondaryDark : NokhchiinColors.textSecondaryLight;

    TextStyle base({
      required double size,
      required FontWeight weight,
      Color? color,
      double? height,
      FontStyle? style,
    }) =>
        TextStyle(
          fontFamily: _fontFamily,
          fontSize: size * scale,
          fontWeight: weight,
          color: color ?? primary,
          height: height,
          fontStyle: style,
        );

    return TextTheme(
      displayLarge: base(size: 36, weight: FontWeight.w800, height: 1.15),
      displayMedium: base(size: 30, weight: FontWeight.w700, height: 1.2),
      headlineLarge: base(size: 26, weight: FontWeight.w700),
      headlineMedium: base(size: 22, weight: FontWeight.w700),
      headlineSmall: base(size: 18, weight: FontWeight.w600),
      titleLarge: base(size: 18, weight: FontWeight.w600),
      titleMedium: base(size: 16, weight: FontWeight.w600),
      titleSmall: base(size: 14, weight: FontWeight.w600),
      bodyLarge: base(size: 16, weight: FontWeight.w500),
      bodyMedium: base(size: 14, weight: FontWeight.w400, color: secondary),
      bodySmall: base(size: 12, weight: FontWeight.w400, color: secondary),
      labelLarge: base(size: 14, weight: FontWeight.w600, color: secondary),
      labelMedium: base(size: 12, weight: FontWeight.w500, color: secondary),
      labelSmall: base(size: 11, weight: FontWeight.w500, color: secondary),
    );
  }

  /// Транскрипция / чеченское слово.
  static TextStyle chechenWord(BuildContext context, {bool large = false}) {
    final theme = Theme.of(context).textTheme;
    return (large ? theme.displayLarge : theme.headlineMedium)!.copyWith(
      fontStyle: FontStyle.normal,
      letterSpacing: 0.5,
    );
  }

  static TextStyle pronunciation(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.primary,
        );
  }
}
