import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/week_xp_chart.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _achievements = {
    'first_lesson': '🏅 Первый урок',
    'streak_3': '🔥 Серия 3 дня',
    'streak_7': '💎 Серия 7 дней',
    'collector': '📚 Коллекционер',
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
          final wordsStudied = snap.data?.length ?? 0;
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
                  NokhchiinStatTile(emoji: '🔥', value: '${profile.streakDays}', label: 'Стрик'),
                  const SizedBox(width: 10),
                  NokhchiinStatTile(emoji: '⭐', value: '${profile.xp}', label: 'XP'),
                  const SizedBox(width: 10),
                  NokhchiinStatTile(emoji: '📚', value: '$wordsStudied', label: 'Слов'),
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
                          Text(
                            '${profile.xp} XP · 🪙 ${profile.coins}',
                            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                          ),
                          Text(
                            'Слов сегодня: ${profile.wordsLearnedToday}/${profile.dailyGoalWords}',
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
              if (!profile.isPremium) ...[
                const SizedBox(height: 14),
                NokhchiinSurfaceCard(
                  onTap: () => context.push('/paywall?return=/progress'),
                  child: Text(
                    'Premium — полная статистика и достижения',
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ),
              ],
              if (profile.isPremium) ...[
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            unlocked ? e.value : '🔒 ${e.value.split(' ').skip(1).join(' ')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: unlocked ? tokens.textPrimary : tokens.textTertiary,
                            ),
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
