import 'package:flutter/material.dart';

import '../design_system.dart';
// temporary

/// Empty state in premium style. Replaces old EmptyState.
class NokhchiinEmptyState extends StatelessWidget {
  const NokhchiinEmptyState({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return Semantics(
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(IosSpacing.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconAsset != null)
                AppIconImage(
                  asset: iconAsset!,
                  size: 56,
                  color: tokens.textSecondary,
                )
              else
                Text(emoji!, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: IosSpacing.x4),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: IosSpacing.x2),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: IosSpacing.x6),
                NokhchiinButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  fullWidth: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
