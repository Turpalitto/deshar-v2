import 'package:flutter/material.dart';
import '../design_system.dart';

/// Статистическая плитка профиля (Figma Make).
class NokhchiinStatTile extends StatelessWidget {
  const NokhchiinStatTile({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.value,
    required this.label,
    this.iconColor,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String value;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final color = iconColor ?? tokens.accent;

    return NokhchiinSurfaceCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          if (iconAsset != null)
            AppIconImage(asset: iconAsset!, size: 22, color: color)
          else
            Text(emoji!, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: tokens.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill стрик / монеты в шапке (Figma Make).
class NokhchiinStatPill extends StatelessWidget {
  const NokhchiinStatPill({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.value,
    required this.color,
    required this.background,
    this.onTap,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String value;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null)
            AppIconImage(asset: iconAsset!, size: 15, color: color)
          else
            Text(emoji!, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
