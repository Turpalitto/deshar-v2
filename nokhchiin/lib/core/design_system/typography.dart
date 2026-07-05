import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// SF Pro–like метрики через Inter (лицензия Google Fonts, кириллица + Ӏ).
///
/// Dynamic Type: размеры здесь — настоящие, немасштабированные. Flutter's
/// `Text`/`RichText` сам применяет системный [TextScaler] поверх любого
/// переданного `fontSize` (по умолчанию — из ambient MediaQuery), поэтому
/// домножать размер здесь ещё раз нельзя: иначе масштаб применяется дважды
/// и при системном увеличении текста на 150-200% заголовок в 22pt
/// превращается в ~88pt вместо ожидаемых 44pt (аудит §3). Параметр
/// [textScaler] сохранён ради обратной совместимости вызывающего кода, но
/// намеренно не участвует в расчёте fontSize.
abstract final class IosTypography {
  /// Базовая семья — Inter (пропорции близки к SF Pro Text).
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  /// SF Pro Display–like для крупных заголовков.
  static String get displayFamily => GoogleFonts.inter().fontFamily!;

  static TextTheme textTheme({
    required DesignTokens tokens,
    TextScaler? textScaler,
  }) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      Color? color,
      double? height,
      double letterSpacing = 0,
      String? family,
    }) {
      return TextStyle(
        fontFamily: family ?? fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? tokens.textPrimary,
      );
    }

    return TextTheme(
      displayLarge: style(
        size: 34,
        weight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.4,
        family: displayFamily,
      ),
      displayMedium: style(
        size: 28,
        weight: FontWeight.w700,
        height: 1.16,
        letterSpacing: -0.3,
        family: displayFamily,
      ),
      headlineLarge: style(size: 22, weight: FontWeight.w600, height: 1.2, letterSpacing: -0.2),
      headlineMedium: style(size: 20, weight: FontWeight.w600, height: 1.22),
      headlineSmall: style(size: 17, weight: FontWeight.w600, height: 1.24),
      titleLarge: style(size: 17, weight: FontWeight.w600, height: 1.24),
      titleMedium: style(size: 15, weight: FontWeight.w600, height: 1.28),
      titleSmall: style(size: 13, weight: FontWeight.w600, height: 1.3),
      bodyLarge: style(size: 17, weight: FontWeight.w400, height: 1.35),
      bodyMedium: style(size: 15, weight: FontWeight.w400, height: 1.38, color: tokens.textSecondary),
      bodySmall: style(size: 13, weight: FontWeight.w400, height: 1.4, color: tokens.textSecondary),
      labelLarge: style(size: 15, weight: FontWeight.w600, height: 1.28, color: tokens.textSecondary),
      labelMedium: style(size: 13, weight: FontWeight.w500, height: 1.3, color: tokens.textTertiary),
      labelSmall: style(size: 11, weight: FontWeight.w500, height: 1.32, color: tokens.textTertiary),
    );
  }

  /// Удобный доступ с учётом Dynamic Type из контекста.
  static TextTheme of(BuildContext context, DesignTokens tokens) {
    return textTheme(
      tokens: tokens,
      textScaler: MediaQuery.textScalerOf(context),
    );
  }

  /// Чеченское слово — крупнее, чуть шире трекинг (как в SF Large Title).
  static TextStyle chechenWord(TextTheme theme, {bool large = false}) {
    final base = large ? theme.displayLarge! : theme.headlineLarge!;
    return base.copyWith(letterSpacing: 0.3, fontWeight: FontWeight.w700);
  }
}
