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
          child: Row(
            children: [
              AppIconImage(asset: AppIcons.progressStar, size: 28, color: DesignTokens.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Слово дня',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.textTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.chechen,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      e.russian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
