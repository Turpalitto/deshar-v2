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

  /// Семантические цвета из Figma Make (не зависят от accent variant).
  static const meadow = Color(0xFF3D7A5C);
  static const meadowMuted = Color(0xFFD4EDE3);
  static const gold = Color(0xFFD4A84B);
  static const goldMuted = Color(0xFFFFF4D4);
  static const cultureDark = Color(0xFF1E1510);
  static const cultureAccent = Color(0xFFE8A87C);

  static DesignTokens light({IosAccentVariant accent = IosAccentVariant.terracotta}) {
    final a = _accentPair(accent, isDark: false);
    return DesignTokens(
      background: const Color(0xFFF7F4EF),
      backgroundElevated: const Color(0xFFFFFCF8),
      surface: const Color(0xFFFFFFFF),
      surfaceMuted: const Color(0xFFF0EBE4),
      separator: const Color(0x1A3D3832),
      textPrimary: const Color(0xFF1C1917),
      textSecondary: const Color(0xFF57534E),
      textTertiary: const Color(0xFF78716C),
      accent: a.$1,
      accentMuted: a.$2,
      accentOn: const Color(0xFFFFFFFF),
      success: const Color(0xFF3D7A5C),
      warning: const Color(0xFFB8860B),
      error: const Color(0xFFB54A4A),
      isDark: false,
    );
  }

  static DesignTokens dark({IosAccentVariant accent = IosAccentVariant.terracotta}) {
    final a = _accentPair(accent, isDark: true);
    return DesignTokens(
      background: const Color(0xFF121110),
      backgroundElevated: const Color(0xFF1A1816),
      surface: const Color(0xFF221F1C),
      surfaceMuted: const Color(0xFF2C2824),
      separator: const Color(0x33F5F0E8),
      textPrimary: const Color(0xFFF5F0E8),
      textSecondary: const Color(0xFFC9C2B8),
      textTertiary: const Color(0xFF9C948A),
      accent: a.$1,
      accentMuted: a.$2,
      accentOn: const Color(0xFF1C1917),
      success: const Color(0xFF6BBF8A),
      warning: const Color(0xFFE8C468),
      error: const Color(0xFFE88A8A),
      isDark: true,
    );
  }

  /// accent, accentMuted
  static (Color, Color) _accentPair(IosAccentVariant variant, {required bool isDark}) {
    return switch (variant) {
      IosAccentVariant.meadow => isDark
          ? (const Color(0xFF6BBF8A), const Color(0xFF2A4D38))
          : (const Color(0xFF3D7A5C), const Color(0xFFD4E8DC)),
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
