import 'package:flutter/material.dart';
import '../../../domain/entities/enums.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../tokens/nokhchiin_colors.dart';

/// Material 3 темы: светлая/тёмная × kids/adult.
abstract final class NokhchiinTheme {
  static ThemeData light({
    AppMode mode = AppMode.kids,
    KidsAgeGroup age = KidsAgeGroup.age6to9,
  }) => _build(Brightness.light, mode, age);

  static ThemeData dark({
    AppMode mode = AppMode.kids,
    KidsAgeGroup age = KidsAgeGroup.age6to9,
  }) => _build(Brightness.dark, mode, age);

  static ThemeData _build(
    Brightness brightness,
    AppMode mode,
    KidsAgeGroup age,
  ) {
    final isDark = brightness == Brightness.dark;
    final isKids = mode == AppMode.kids;
    final scale = _scale(mode, age);

    final bg = isDark
        ? NokhchiinColors.darkBackground
        : NokhchiinColors.lightBackground;
    final surface = isDark
        ? NokhchiinColors.darkSurface
        : NokhchiinColors.lightSurface;
    final primary = isKids ? NokhchiinColors.meadow : NokhchiinColors.accent;
    final onPrimary = Colors.white;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: NokhchiinColors.accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: isDark
          ? NokhchiinColors.textPrimaryDark
          : NokhchiinColors.textPrimaryLight,
      error: NokhchiinColors.error,
      onError: Colors.white,
    );

    final radius = AppRadii.card(isKids);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: AppTypography.textTheme(isDark: isDark, scale: scale),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.textTheme(
          isDark: isDark,
          scale: scale,
        ).titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isDark
                ? NokhchiinColors.darkSurfaceAlt
                : NokhchiinColors.lightSurfaceAlt,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: isKids ? AppSpacing.lg : AppSpacing.md,
          ),
          minimumSize: Size(0, isKids ? 52 : 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button(isKids)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: isKids ? AppSpacing.lg : AppSpacing.md,
          ),
          minimumSize: Size(0, isKids ? 52 : 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button(isKids)),
          ),
          side: BorderSide(color: primary.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? NokhchiinColors.darkSurfaceAlt
            : NokhchiinColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip(isKids)),
        ),
      ),
      extensions: [
        NokhchiinSkin(
          isKids: isKids,
          cardRadius: radius,
          touchTarget: isKids ? 52.0 : 44.0,
          heroGradient: isKids
              ? [NokhchiinColors.meadow, NokhchiinColors.mountain]
              : [NokhchiinColors.stoneDark, NokhchiinColors.mountain],
        ),
      ],
    );
  }

  static double _scale(AppMode mode, KidsAgeGroup age) {
    if (mode == AppMode.adult) return 0.95;
    return switch (age) {
      KidsAgeGroup.age3to6 => 1.12,
      KidsAgeGroup.age6to9 => 1.0,
      KidsAgeGroup.age9to12 => 0.96,
    };
  }
}

/// Расширение темы для kids/adult скинов.
class NokhchiinSkin extends ThemeExtension<NokhchiinSkin> {
  const NokhchiinSkin({
    required this.isKids,
    required this.cardRadius,
    required this.touchTarget,
    required this.heroGradient,
  });

  final bool isKids;
  final double cardRadius;
  final double touchTarget;
  final List<Color> heroGradient;

  static NokhchiinSkin of(BuildContext context) =>
      Theme.of(context).extension<NokhchiinSkin>() ??
      const NokhchiinSkin(
        isKids: true,
        cardRadius: AppRadii.xxl,
        touchTarget: 52,
        heroGradient: [NokhchiinColors.meadow, NokhchiinColors.mountain],
      );

  @override
  NokhchiinSkin copyWith({
    bool? isKids,
    double? cardRadius,
    double? touchTarget,
    List<Color>? heroGradient,
  }) => NokhchiinSkin(
    isKids: isKids ?? this.isKids,
    cardRadius: cardRadius ?? this.cardRadius,
    touchTarget: touchTarget ?? this.touchTarget,
    heroGradient: heroGradient ?? this.heroGradient,
  );

  @override
  NokhchiinSkin lerp(ThemeExtension<NokhchiinSkin>? other, double t) {
    if (other is! NokhchiinSkin) return this;
    return NokhchiinSkin(
      isKids: t < 0.5 ? isKids : other.isKids,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      touchTarget: touchTarget + (other.touchTarget - touchTarget) * t,
      heroGradient: [
        Color.lerp(heroGradient[0], other.heroGradient[0], t)!,
        Color.lerp(heroGradient[1], other.heroGradient[1], t)!,
      ],
    );
  }
}
