import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/widgets/app_scaffold.dart'; // intentional-mix: app shell scaffold
import '../../core/design/widgets/loading_state.dart'; // intentional-mix: shared loading placeholder
import '../../core/design/widgets/week_xp_chart.dart'; // intentional-mix: chart widget not yet in design_system
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _achievements = {
    'first_lesson': ('Первый урок', AppIcons.rewardTrophy),
    'streak_3': ('Серия 3 дня', AppIcons.progressStreak),
    'streak_7': ('Серия 7 дней', AppIcons.progressStar),
    'collector': ('Коллекционер', AppIcons.navDictionary),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final mastery = ref.watch(languageMasteryProvider);
    final progressRepo = ref.watch(progressRepoProvider);
    final tokens = context.iosTokens;
    final accent = profile.mode == AppMode.kids ? DesignTokens.meadow : tokens.accent;
    final accentMuted = profile.mode == AppMode.kids ? DesignTokens.meadowMuted : tokens.accentMuted;

    return AppScaffold(
      body: FutureBuilder(
        future: progressRepo.getAllProgress(),
        builder: (context, snap) {
          final wordsStudied =
              snap.data?.values.where((p) => !p.seededFromPlacement).length ?? 0;
          final alreadyKnown =
              snap.data?.values.where((p) => p.seededFromPlacement).length ?? 0;
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              NokhchiinPageHeader(title: 'Прогресс SRS', onBack: () => context.pop()),
              const SizedBox(height: 20),
              Row(
                children: [
                  NokhchiinStatTile(iconAsset: AppIcons.progressStreak, value: '${profile.streakDays}', label: 'Стрик'),
                  const SizedBox(width: 10),
                  NokhchiinStatTile(iconAsset: AppIcons.progressStar, value: '${profile.xp}', label: 'XP'),
                  const SizedBox(width: 10),
                  NokhchiinStatTile(iconAsset: AppIcons.navDictionary, value: '$wordsStudied', label: 'Слов'),
                ],
              ),
              const SizedBox(height: 14),
              NokhchiinSurfaceCard(
                radius: 22,
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    NokhchiinArcProgress(
                      progress: (mastery.valueOrNull ?? 0) / 100,
                      size: 90,
                      strokeWidth: 7,
                      color: accent,
                      trackColor: accentMuted,
                      center: Text(
                        '${mastery.valueOrNull ?? 0}%',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Уровень ${profile.level}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${profile.xp} XP · ',
                                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                              ),
                              AppIconImage(asset: AppIcons.progressCoin, size: 14, color: DesignTokens.gold),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.coins}',
                                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            'Слов сегодня: ${profile.wordsLearnedToday}/${profile.dailyGoalWords}',
                            style: TextStyle(fontSize: 13, color: tokens.textTertiary),
                          ),
                          if (alreadyKnown > 0)
                            Text(
                              'Уже знал: $alreadyKnown слов',
                              style: TextStyle(fontSize: 13, color: tokens.textTertiary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              NokhchiinSurfaceCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: WeekXpChart(
                  weeklyXp: profile.weeklyXp,
                  accent: accent,
                  accentMuted: accentMuted,
                ),
              ),
              if (FeatureFlags.premiumEnabled && !profile.isPremium) ...[
                const SizedBox(height: 14),
                NokhchiinSurfaceCard(
                  onTap: () => context.push('/paywall?return=/progress'),
                  child: Text(
                    'Premium — полная статистика и достижения',
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ),
              ],
              if (!FeatureFlags.premiumEnabled || profile.isPremium) ...[
                const SizedBox(height: 14),
                NokhchiinSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Достижения',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._achievements.entries.map((e) {
                        final unlocked = profile.achievements.contains(e.key);
                        final (label, icon) = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              if (unlocked)
                                AppIconImage(asset: icon, size: 18, color: accent)
                              else
                                AppIconImage(asset: AppIcons.stateLocked, size: 18, color: tokens.textTertiary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: unlocked ? tokens.textPrimary : tokens.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
