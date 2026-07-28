import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/router/app_router.dart';

class KidsGamesScreen extends StatelessWidget {
  const KidsGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      ('Карточки', AppIcons.navDictionary, '/flashcards/$kFirstLessonUnitId'),
      ('Викторина', AppIcons.gamePlay, '/quiz/$kFirstLessonUnitId'),
      ('Пары', AppIcons.gamePuzzle, '/match/$kFirstLessonUnitId'),
    ];
    return AppScaffold(
      title: 'Игры',
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final game = games[index];
          return NokhchiinSurfaceCard(
            onTap: () => context.push(game.$3),
            child: Row(
              children: [
                AppIconImage(asset: game.$2, size: 42),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    game.$1,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
      ),
    );
  }
}
