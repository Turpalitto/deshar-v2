import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// Мини-график XP за 7 дней — стиль Figma Home.
class WeekXpChart extends StatelessWidget {
  const WeekXpChart({
    super.key,
    required this.weeklyXp,
    this.height = 64,
    this.accent,
    this.accentMuted,
    this.todayIndex,
  });

  final List<int> weeklyXp;
  final double height;
  final Color? accent;
  final Color? accentMuted;
  final int? todayIndex;

  // weeklyXp — скользящее окно: индекс 6 = сегодня, 0 = 6 дней назад.
  // Подсветка и метки соответствуют этому порядку, а не календарной
  // неделе (аудит week_xp_chart).
  static const _days = ['6дн', '5дн', '4дн', '3дн', '2дн', 'Вчера', 'Сегодня'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final active = accent ?? tokens.accent;
    final muted = accentMuted ?? tokens.accentMuted;
    final today = todayIndex ?? 6;

    final data = weeklyXp.length == 7 ? weeklyXp : List.filled(7, 0);
    final max = data.fold<int>(1, (a, b) => a > b ? a : b);
    final totalXp = data.fold<int>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP за неделю',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
            ),
            NokhchiinChip(label: '$totalXp XP', color: active, background: muted),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final v = data[i];
              final barH = v == 0 ? 4.0 : (v / max * (height - 20)).clamp(8.0, height - 20);
              final isToday = i == today;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: IosMotion.reveal,
                        curve: IosMotion.curveGentle,
                        width: double.infinity,
                        height: barH,
                        decoration: BoxDecoration(
                          color: isToday ? active : muted,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _days[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isToday ? active : tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
