import 'package:flutter/material.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design_system/design_system.dart';

/// Прогресс упражнения + опциональный combo-streak (Duolingo-style).
class ExerciseProgressHeader extends StatelessWidget {
  const ExerciseProgressHeader({
    super.key,
    required this.step,
    required this.total,
    this.combo = 0,
    this.label,
  });

  final int step;
  final int total;
  final int combo;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: NokhchiinSegmentProgress(
                step: step.clamp(1, total),
                total: total.clamp(1, total),
              ),
            ),
            if (combo >= 2) ...[
              const SizedBox(width: AppSpacing.sm),
              AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 200),
                child: NokhchiinChip(
                  label: '×$combo',
                  color: DesignTokens.gold,
                  background: DesignTokens.goldMuted,
                ),
              ),
            ],
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            label!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

/// Счётчик серии правильных ответов подряд.
class GameComboTracker {
  int _streak = 0;

  int get streak => _streak;

  /// +1 при верном ответе, возвращает новый streak.
  int recordCorrect() => ++_streak;

  void reset() => _streak = 0;
}