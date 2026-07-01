import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';

/// Streak в духе iOS Health: крупное число + короткая подпись.
class IosStreakTile extends StatelessWidget {
  const IosStreakTile({
    super.key,
    required this.days,
    this.subtitle = 'дней подряд',
  });

  final int days;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$days',
          style: textTheme.displayLarge?.copyWith(
            fontSize: 56,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: IosSpacing.x1),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
