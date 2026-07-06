import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/widgets/app_icon_image.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/providers/word_of_the_day_provider.dart';

/// Карточка «Слово дня» на главном экране. Одно слово словаря, одинаковое
/// для всех пользователей в течение дня. Без аудио — только текст.
class WordOfTheDayCard extends ConsumerWidget {
  const WordOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(wordOfTheDayProvider);

    return entry.when(
      data: (e) {
        if (e == null) return const SizedBox.shrink();
        final tokens = context.iosTokens;
        return NokhchiinSurfaceCard(
          onTap: () => context.push('/dictionary/${e.id}'),
          semanticLabel: 'Слово дня: ${e.chechen} — ${e.russian}',
          radius: 18,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Звезда в золотом сквиркле — единый паттерн иконок-в-контейнере.
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.goldMuted,
                      DesignTokens.goldMuted.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DesignTokens.gold.withValues(alpha: 0.25)),
                ),
                alignment: Alignment.center,
                child: AppIconImage(asset: AppIcons.progressStar, size: 22, color: DesignTokens.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'СЛОВО ДНЯ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.gold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.chechen,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      e.russian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textSecondary),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
