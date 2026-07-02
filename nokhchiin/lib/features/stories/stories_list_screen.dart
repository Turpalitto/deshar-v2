import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/providers/providers.dart';

import '../../core/widgets/word_illustration.dart';

class StoriesListScreen extends ConsumerWidget {
  const StoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);

    return AppScaffold(
      title: 'Награды — истории',
      body: stories.when(
        data: (list) => FutureBuilder(
          future: _storyAccess(ref, list),
          builder: (context, snap) {
            if (!snap.hasData) return const LoadingState();
            final access = snap.data!;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppCard(
                  child: Text(
                    'Истории открываются после уроков — награда за прогресс',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...List.generate(list.length, (i) {
                  final s = list[i];
                  final unlocked = access[i];
                  final panels = (s['panels'] as List?)?.length ?? 0;
                  final required = s['requiredMastery'] as int? ?? 50;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: unlocked ? () => context.push('/story/${s['id']}') : null,
                      child: Row(
                        children: [
                          WordIllustration(
                            category: s['unitId'] as String?,
                            emoji: s['emoji'] as String?,
                            size: 80,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['titleRu'] as String, style: Theme.of(context).textTheme.titleLarge),
                                Text(
                                  unlocked ? '$panels сцен · награда' : 'Нужно $required% юнита',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (unlocked)
                            AppIconImage(asset: AppIcons.navDictionary, size: 24)
                          else
                            AppIconImage(asset: AppIcons.stateLocked, size: 24),
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

  Future<List<bool>> _storyAccess(WidgetRef ref, List<Map<String, dynamic>> list) async {
    final mastery = ref.read(unitMasteryUseCaseProvider);
    final result = <bool>[];
    for (final s in list) {
      final unitId = s['unitId'] as String?;
      final required = s['requiredMastery'] as int? ?? 50;
      if (unitId == null) {
        result.add(false);
        continue;
      }
      final pct = await mastery(unitId);
      result.add(pct >= required);
    }
    return result;
  }
}
