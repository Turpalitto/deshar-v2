import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/content_providers.dart';
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
              final gradient = (w['gradient'] as List).cast<String>();
              final color = Color(int.parse(gradient.first.replaceFirst('#', '0xFF')));
              final unitIds = (w['units'] as List).cast<String>();

              return NokhchiinWorldCard(
                index: i,
                title: w['titleRu'] as String,
                description: w['subtitleRu'] as String? ?? w['titleCe'] as String? ?? '',
                emoji: w['emoji'] as String? ?? '🌍',
                progressPercent: pct,
                lessonCount: unitIds.length,
                color: color,
                unlocked: unlocked,
                onTap: unlocked
                    ? () {
                        ref.read(userProfileProvider.notifier).setCurrentWorld(w['id'] as String);
                        if (unitIds.isNotEmpty) context.push('/unit/${unitIds.first}');
                      }
                    : () => context.push('/paywall?return=/worlds'),
              ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.06);
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
