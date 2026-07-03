import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'ios_design_system.dart';

/// Подключение design system к приложению без переписывания экранов.
abstract final class DesignSystemIntegration {
  /// Вызовите из [MaterialApp.builder] для Dynamic Type (textScaler из MediaQuery).
  static ThemeData enhanceWithContext(BuildContext context, ThemeData baseTheme) {
    return IosDesignSystem.enhance(
      baseTheme,
      accent: defaultAccent,
      textScaler: MediaQuery.textScalerOf(context),
    );
  }

  /// Статическое подключение (без Dynamic Type) — для theme / darkTheme.
  static ThemeData enhance(ThemeData baseTheme) {
    return IosDesignSystem.enhance(baseTheme, accent: defaultAccent);
  }

  /// Акцент по умолчанию — национальный зелёный (Deshar primary, основной бренд
  /// adult-трека). Терракота — культурный акцент, sunGold — для наград.
  static const IosAccentVariant defaultAccent = IosAccentVariant.meadow;
}
