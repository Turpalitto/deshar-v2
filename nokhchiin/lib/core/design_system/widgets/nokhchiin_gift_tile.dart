import 'package:flutter/material.dart';
import '../../design/widgets/app_icon_image.dart';
import '../design_system.dart';

/// Плитка «Капсула / Подарок / Словарь» на главной (Figma Make).
class NokhchiinGiftTile extends StatelessWidget {
  const NokhchiinGiftTile({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.gradient,
    this.lightText = false,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? tokens.surface : null,
            borderRadius: BorderRadius.circular(16),
            border: gradient == null ? Border.all(color: tokens.separator) : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (iconAsset != null)
                AppIconImage(
                  asset: iconAsset!,
                  size: 22,
                  color: lightText ? Colors.white : tokens.accent,
                )
              else
                Text(emoji!, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: lightText ? Colors.white : tokens.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: lightText ? Colors.white.withValues(alpha: 0.6) : tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
