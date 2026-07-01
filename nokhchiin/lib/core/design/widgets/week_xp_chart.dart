import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// Мини-график XP за 7 дней.
class WeekXpChart extends StatelessWidget {
  const WeekXpChart({super.key, required this.weeklyXp, this.height = 72});

  final List<int> weeklyXp;
  final double height;

  static const _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final data = weeklyXp.length == 7 ? weeklyXp : List.filled(7, 0);
    final max = data.fold<int>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final v = data[i];
          final barH = v == 0 ? 4.0 : (v / max * (height - 20)).clamp(8.0, height - 20);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barH,
                    decoration: BoxDecoration(
                      color: i == 6
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _days[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
