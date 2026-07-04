import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'typography.dart';

/// ThemeExtension: premium iOS design system (Cupertino-first, без Material elevation).
@immutable
class IosDesignSystem extends ThemeExtension<IosDesignSystem> {
  const IosDesignSystem({
    required this.tokens,
    required this.textTheme,
    required this.cupertinoTheme,
    this.accentVariant = IosAccentVariant.meadow,
  });

  final DesignTokens tokens;
  final TextTheme textTheme;
  final CupertinoThemeData cupertinoTheme;
  final IosAccentVariant accentVariant;

  factory IosDesignSystem.light({
    IosAccentVariant accent = IosAccentVariant.meadow,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final t = DesignTokens.light(accent: accent);
    final text = IosTypography.textTheme(tokens: t, textScaler: textScaler);
    return IosDesignSystem(
      tokens: t,
      textTheme: text,
      accentVariant: accent,
      cupertinoTheme: _cupertino(t, brightness: Brightness.light),
    );
  }

  factory IosDesignSystem.dark({
    IosAccentVariant accent = IosAccentVariant.meadow,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final t = DesignTokens.dark(accent: accent);
    final text = IosTypography.textTheme(tokens: t, textScaler: textScaler);
    return IosDesignSystem(
      tokens: t,
      textTheme: text,
      accentVariant: accent,
      cupertinoTheme: _cupertino(t, brightness: Brightness.dark),
    );
  }

  static CupertinoThemeData _cupertino(DesignTokens t, {required Brightness brightness}) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: t.accent,
      primaryContrastingColor: t.accentOn,
      scaffoldBackgroundColor: t.background,
      barBackgroundColor: t.surface.withValues(alpha: 0.92),
      textTheme: CupertinoTextThemeData(
        primaryColor: t.textPrimary,
        textStyle: TextStyle(
          fontFamily: IosTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: t.textPrimary,
          height: 1.35,
        ),
        actionTextStyle: TextStyle(
          fontFamily: IosTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: t.accent,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: IosTypography.displayFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: IosTypography.displayFamily,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: t.textPrimary,
        ),
      ),
    );
  }

  /// Подмешать extension + Cupertino override в существующую [ThemeData]
  /// (не ломает текущую архитектуру / NokhchiinTheme).
  static ThemeData enhance(
    ThemeData base, {
    IosAccentVariant accent = IosAccentVariant.meadow,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final isDark = base.brightness == Brightness.dark;
    final ds = isDark
        ? IosDesignSystem.dark(accent: accent, textScaler: textScaler)
        : IosDesignSystem.light(accent: accent, textScaler: textScaler);

    return base.copyWith(
      platform: TargetPlatform.iOS,
      cupertinoOverrideTheme: ds.cupertinoTheme,
      textTheme: ds.textTheme,
      scaffoldBackgroundColor: ds.tokens.background,
      extensions: _mergeExtensions(base, ds),
      // Без Material elevation — плоские поверхности.
      cardTheme: base.cardTheme.copyWith(elevation: 0, shadowColor: Colors.transparent),
      elevatedButtonTheme: null,
      filledButtonTheme: null,
    );
  }

  static List<ThemeExtension<dynamic>> _mergeExtensions(ThemeData base, IosDesignSystem ds) {
    final others = base.extensions.values.where((e) => e is! IosDesignSystem);
    return [ds, ...others];
  }

  /// Доступ из виджетов: `context.iosDesignSystem.tokens.accent`
  static IosDesignSystem of(BuildContext context) {
    return Theme.of(context).extension<IosDesignSystem>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? IosDesignSystem.dark()
            : IosDesignSystem.light());
  }


  @override
  IosDesignSystem copyWith({
    DesignTokens? tokens,
    TextTheme? textTheme,
    CupertinoThemeData? cupertinoTheme,
    IosAccentVariant? accentVariant,
  }) {
    return IosDesignSystem(
      tokens: tokens ?? this.tokens,
      textTheme: textTheme ?? this.textTheme,
      cupertinoTheme: cupertinoTheme ?? this.cupertinoTheme,
      accentVariant: accentVariant ?? this.accentVariant,
    );
  }

  @override
  IosDesignSystem lerp(IosDesignSystem? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

/// Shortcuts
extension IosDesignSystemContext on BuildContext {
  IosDesignSystem get iosDesignSystem => IosDesignSystem.of(this);
  DesignTokens get iosTokens => iosDesignSystem.tokens;
}
