import 'package:flutter/material.dart';
import 'nokhchiin_colors.dart';

abstract final class AppShadows {
  static List<BoxShadow> soft(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevated(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.22),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> card(bool isDark) =>
      soft(isDark ? NokhchiinColors.stoneDark : NokhchiinColors.stone);
}
