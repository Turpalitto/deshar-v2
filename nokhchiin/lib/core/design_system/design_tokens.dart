import 'package:flutter/material.dart';

/// Акцентные палитры — выберите одну для продакшена (см. комментарии).
enum IosAccentVariant {
  /// Вариант A — «Горный луг» (Caucasus meadow pine).
  /// Ассоциация: горы, весна, рост. Спокойный, премиальный, хорош для edtech.
  meadow,

  /// Вариант B — «Терракота» (Vainakh clay & stone).
  /// Ассоциация: традиционная архитектура, тепло, земля. Более «культурный» характер.
  terracotta,

  /// Вариант C — «Солнечное золото» (hospitality & ornament).
  /// Ассоциация: солнце, гостеприимство, орнамент. Ярче, для наград и CTA.
  sunGold,
}

/// Нейтральные и акцентные токены iOS-style (без Material elevation-стиля).
@immutable
class DesignTokens {
  const DesignTokens({
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceMuted,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentMuted,
    required this.accentOn,
    required this.success,
    required this.warning,
    required this.error,
    required this.isDark,
  });

  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceMuted;
  final Color separator;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentMuted;
  final Color accentOn;
  final Color success;
  final Color warning;
  final Color error;
  final bool isDark;

  /// Культурные цвета чеченской идентичности (орнаменты, раздел «Культура»).
  /// Сохраняются поверх deshar-палитры как акценты наследия.
  static const meadow = Color(0xFF1B6B4A);
  static const meadowMuted = Color(0xFFD4F0E0);
  static const gold = Color(0xFFD4A84B);
  static const goldMuted = Color(0xFFFFF4D4);
  static const cultureDark = Color(0xFF1E1510);
  static const cultureAccent = Color(0xFFE8A87C);

  /// Палитра adult-трека перенесена из визуального языка Deshar (Manus):
  /// чистый светлый фон, национальный зелёный primary, мягкие семантические
  /// цвета. Kids-трек использует [NokhchiinColors] (тёплая кремовая палитра).
  static DesignTokens light({IosAccentVariant accent = IosAccentVariant.meadow}) {
    final a = _accentPair(accent, isDark: false);
    return DesignTokens(
      background: const Color(0xFFFAFBFC),
      backgroundElevated: const Color(0xFFFFFFFF),
      surface: const Color(0xFFFFFFFF),
      surfaceMuted: const Color(0xFFF0F2F5),
      separator: const Color(0xFFE8ECF0),
      textPrimary: const Color(0xFF1A1A2E),
      textSecondary: const Color(0xFF6B7280),
      textTertiary: const Color(0xFF9CA3AF),
      accent: a.$1,
      accentMuted: a.$2,
      accentOn: const Color(0xFFFFFFFF),
      success: const Color(0xFF10B981),
      warning: const Color(0xFFF59E0B),
      error: const Color(0xFFEF4444),
      isDark: false,
    );
  }

  static DesignTokens dark({IosAccentVariant accent = IosAccentVariant.meadow}) {
    final a = _accentPair(accent, isDark: true);
    return DesignTokens(
      background: const Color(0xFF0F1419),
      backgroundElevated: const Color(0xFF131A22),
      surface: const Color(0xFF1A2332),
      surfaceMuted: const Color(0xFF2F3B4A),
      separator: const Color(0xFF2F3B4A),
      textPrimary: const Color(0xFFF0F4F8),
      textSecondary: const Color(0xFF8899A6),
      textTertiary: const Color(0xFF6B7280),
      accent: a.$1,
      accentMuted: a.$2,
      accentOn: const Color(0xFF0F1419),
      success: const Color(0xFF34D399),
      warning: const Color(0xFFFBBF24),
      error: const Color(0xFFF87171),
      isDark: true,
    );
  }

  /// accent, accentMuted
  static (Color, Color) _accentPair(IosAccentVariant variant, {required bool isDark}) {
    return switch (variant) {
      // Чеченский национальный зелёный (Deshar primary).
      IosAccentVariant.meadow => isDark
          ? (const Color(0xFF2ECC71), const Color(0xFF1A3A28))
          : (const Color(0xFF1B6B4A), const Color(0xFFD4F0E0)),
      // Терракота — культурный акцент (орнамент, heritage).
      IosAccentVariant.terracotta => isDark
          ? (const Color(0xFFE8A87C), const Color(0xFF5C3D2E))
          : (const Color(0xFFC4724E), const Color(0xFFF5E0D4)),
      IosAccentVariant.sunGold => isDark
          ? (const Color(0xFFF0D78C), const Color(0xFF5C4A20))
          : (const Color(0xFFD4A84B), const Color(0xFFF8ECD0)),
    };
  }

  DesignTokens copyWith({IosAccentVariant? accentVariant}) {
    if (accentVariant == null) return this;
    final a = _accentPair(accentVariant, isDark: isDark);
    return DesignTokens(
      background: background,
      backgroundElevated: backgroundElevated,
      surface: surface,
      surfaceMuted: surfaceMuted,
      separator: separator,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      accent: a.$1,
      accentMuted: a.$2,
      accentOn: accentOn,
      success: success,
      warning: warning,
      error: error,
      isDark: isDark,
    );
  }
}
