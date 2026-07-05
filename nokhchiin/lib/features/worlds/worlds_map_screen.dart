import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/error_state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';

import '../../core/utils/world_progress_util.dart';
import '../../domain/entities/learning_entities.dart';

/// Карта миров — layout из Figma Make.
class WorldsMapScreen extends ConsumerWidget {
  const WorldsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = ref.watch(worldsProvider);
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final units = ref.watch(learningUnitsProvider);
    final tokens = context.iosTokens;

    return AppScaffold(
      showOrnament: true,
      body: worlds.when(
        data: (list) => units.when(
          data: (unitList) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text(
                  'Миры',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ).animate().fadeIn();
              }

              final w = list[i - 1];
              final unlocked = isWorldUnlocked(
                w,
                isPremium: profile.isPremium,
                unlockedWorlds: profile.unlockedWorlds,
                coins: profile.coins,
              );
              final pct = worldProgressPercent(w, unitList);
              final color = Color(int.parse(w.gradient.first.replaceFirst('#', '0xFF')));

              return NokhchiinWorldCard(
                index: i,
                title: w.titleRu,
                description: w.subtitleRu ?? w.titleCe,
                emoji: w.emoji,
                iconAsset: w.emoji == null ? AppIcons.navWorlds : null,
                progressPercent: pct,
                lessonCount: w.units.length,
                color: color,
                unlocked: unlocked,
                onTap: unlocked
                    ? () {
                        ref.read(userProfileProvider.notifier).setCurrentWorld(w.id);
                        if (w.units.isNotEmpty) context.push('/unit/${w.units.first}');
                      }
                    : FeatureFlags.premiumEnabled
                        ? () => context.push('/paywall?return=/worlds')
                        : null,
              ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.06);
            },
          ),
          loading: () => const NokhchiinLoadingState(),
          error: (_, __) => ErrorState(
            message: 'Не удалось загрузить юниты',
            onRetry: () => ref.invalidate(learningUnitsProvider),
          ),
        ),
        loading: () => const NokhchiinLoadingState(),
        error: (_, __) => ErrorState(
          message: 'Не удалось загрузить миры',
          onRetry: () => ref.invalidate(worldsProvider),
        ),
      ),
    );
  }
}
