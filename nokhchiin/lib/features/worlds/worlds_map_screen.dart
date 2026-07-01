import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_chip.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/progress_ring.dart';
import '../../core/providers/content_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/world_progress_util.dart';
import '../../core/widgets/mastery_progress_bar.dart';
import '../../domain/entities/learning_entities.dart';

/// Карта миров — основная навигация приключения.
class WorldsMapScreen extends ConsumerWidget {
  const WorldsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = ref.watch(worldsProvider);
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final units = ref.watch(learningUnitsProvider);

    return AppScaffold(
      title: 'Миры',
      showOrnament: true,
      actions: [
        AppChip(label: '${profile.coins}', emoji: '🪙'),
        const SizedBox(width: AppSpacing.sm),
      ],
      body: worlds.when(
        data: (list) => units.when(
          data: (unitList) => GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.88,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final w = list[i];
              final unlocked = isWorldUnlocked(
                w,
                isPremium: profile.isPremium,
                unlockedWorlds: profile.unlockedWorlds,
                coins: profile.coins,
              );
              final pct = worldProgressPercent(w, unitList);
              final gradient = (w['gradient'] as List).cast<String>();
              final colors = gradient.map((h) => Color(int.parse(h.replaceFirst('#', '0xFF')))).toList();
              final isActive = w['id'] == profile.currentWorldId;

              return AppCard(
                onTap: unlocked
                    ? () {
                        ref.read(userProfileProvider.notifier).setCurrentWorld(w['id'] as String);
                        final unitIds = (w['units'] as List).cast<String>();
                        if (unitIds.isNotEmpty) context.push('/unit/${unitIds.first}');
                      }
                    : () => context.push('/paywall?return=/worlds'),
                padding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: colors),
                        border: isActive
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(w['emoji'] as String? ?? '🌍', style: const TextStyle(fontSize: 36)),
                              ProgressRing(percent: pct, size: 40, strokeWidth: 4),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            w['titleRu'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1F2937)),
                          ),
                          Text(
                            w['titleCe'] as String,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          MasteryProgressBar(percent: pct),
                          Text('$pct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    if (!unlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(child: Text('🔒', style: TextStyle(fontSize: 32))),
                        ),
                      ),
                  ],
                ),
              ).animate(delay: (i * 40).ms).fadeIn().scale(begin: const Offset(0.96, 0.96));
            },
          ),
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
