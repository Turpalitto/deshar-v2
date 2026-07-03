import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/widgets/mastery_progress_bar.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/content_entities.dart';
import '../../domain/usecases/access_usecases.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    return AppScaffold(
      title: 'Коллекции',
      body: collections.when(
        data: (list) => FutureBuilder(
          future: _loadAlbumStats(ref, list),
          builder: (context, snap) {
            if (!snap.hasData) return const LoadingState();
            final stats = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text('Собери 100%', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                ...List.generate(list.length, (i) {
                  final col = list[i];
                  final owned = stats[i].$1;
                  final total = stats[i].$2;
                  final pct = total > 0 ? (owned / total * 100).round() : 0;
                  final legendary = col.rarity == 'legendary';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: () => _openAlbum(context, ref, legendary),
                      child: Row(
                        children: [
                          Text(col.icon ?? '📘', style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(col.titleRu, style: Theme.of(context).textTheme.titleLarge),
                                Text('$owned / $total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                const SizedBox(height: AppSpacing.sm),
                                MasteryProgressBar(percent: pct),
                              ],
                            ),
                          ),
                          if (pct >= 100)
                            AppIconImage(asset: AppIcons.rewardCelebration, size: 24, color: DesignTokens.gold)
                          else if (legendary)
                            const AppIconImage(asset: AppIcons.rewardCrown, size: 24)
                          else
                            Text(col.icon ?? '📗', style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<List<(int, int)>> _loadAlbumStats(WidgetRef ref, List<CollectionEntity> list) async {
    final progress = await ref.read(progressRepoProvider).getAllProgress();
    final dict = ref.read(dictionaryRepoProvider);
    final result = <(int, int)>[];
    for (final col in list) {
      final cat = col.category;
      final words = await dict.getWordsByCategory(cat);
      final total = col.totalCards > 0 ? col.totalCards : words.length;
      var owned = 0;
      for (final w in words) {
        final p = progress[w.id];
        if (p != null && p.mastery.value >= MasteryLevel.remembering.value) owned++;
      }
      result.add((owned.clamp(0, total), total));
    }
    return result;
  }

  Future<void> _openAlbum(BuildContext context, WidgetRef ref, bool legendary) async {
    if (legendary) {
      final ok = await ref.read(canAccessFeatureUseCaseProvider)(PremiumFeature.fullCollections);
      if (!ok && context.mounted) {
        context.push('/paywall?return=/collections');
        return;
      }
    }
  }
}
