import 'package:flutter/material.dart';
import '../design_system.dart';

/// Индикатор загрузки в стиле design_system (IosSpacing + токены).
class NokhchiinLoadingState extends StatelessWidget {
  const NokhchiinLoadingState({super.key, this.message = 'Загрузка…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tokens.accent),
            const SizedBox(height: IosSpacing.x6),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
