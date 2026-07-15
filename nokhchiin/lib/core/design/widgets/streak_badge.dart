import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import '../tokens/nokhchiin_colors.dart';
import '../app_icons.dart';
import 'app_icon_image.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.compact = false});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hot = days >= 7;
    final iconSize = compact ? 14.0 : 18.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hot
              ? [NokhchiinColors.accent, NokhchiinColors.accentDark]
              : [NokhchiinColors.warning, NokhchiinColors.accent],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconImage(
            asset: hot ? AppIcons.progressStar : AppIcons.progressStreak,
            size: iconSize,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$days',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 13 : 16,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            const Text(
              'дн.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
