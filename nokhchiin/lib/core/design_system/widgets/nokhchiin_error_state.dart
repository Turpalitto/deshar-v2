import 'package:flutter/material.dart';

import '../design_system.dart';
// temporary until full port

/// Error state in premium iOS/Figma style.
/// Replaces old ErrorState. Uses tokens, Semantics, NokhchiinButton.
class NokhchiinErrorState extends StatelessWidget {
  const NokhchiinErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(IosSpacing.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconImage(
                asset: 'assets/icons/state_error.svg',
                size: 48,
                color: tokens.textSecondary,
              ),
              const SizedBox(height: IosSpacing.x4),
              Text(
                message,
                style: IosTypography.of(
                  context,
                  tokens,
                ).bodyLarge?.copyWith(color: tokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: IosSpacing.x6),
                NokhchiinButton(
                  label: 'Повторить',
                  onPressed: onRetry,
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
