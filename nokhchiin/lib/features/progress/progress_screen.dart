import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/progress_ring.dart';
import '../../core/design/widgets/streak_badge.dart';
import '../../core/providers/providers.dart';
import 'package:go_router/go_router.dart';
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
    final weekXp = profile.weeklyXp.fold<int>(0, (a, b) => a + b);

    return AppScaffold(
      title: 'Прогресс SRS',
      body: FutureBuilder(
        future: progressRepo.getAllProgress(),
        builder: (context, snap) {
          final wordsStudied = snap.data?.length ?? 0;
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Row(
                  children: [
                    ProgressRing(
                      percent: mastery.valueOrNull ?? 0,
                      label: 'язык',
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreakBadge(days: profile.streakDays),
                          const SizedBox(height: AppSpacing.md),
                          Text('Уровень ${profile.level}', style: Theme.of(context).textTheme.titleLarge),
                          Text('${profile.xp} XP · 🪙 ${profile.coins}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сегодня', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    _Row('Слов', '${profile.wordsLearnedToday} / ${profile.dailyGoalWords}'),
                    _Row('Уроков всего', '${profile.lessonsCompletedTotal}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!profile.isPremium)
                AppCard(
                  onTap: () => context.push('/paywall?return=/progress'),
                  child: const Text('Premium — полная статистика и достижения'),
                ),
              if (!profile.isPremium) const SizedBox(height: AppSpacing.md),
              if (profile.isPremium) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Неделя', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    _StreakCalendar(weeklyXp: profile.weeklyXp),
                    const SizedBox(height: AppSpacing.md),
                    _Row('XP за неделю', '$weekXp'),
                    _Row('Слов в работе', '$wordsStudied'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Достижения', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    ..._achievements.entries.map((e) {
                      final unlocked = profile.achievements.contains(e.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          unlocked ? e.value : '🔒 ${e.value.split(' ').skip(1).join(' ')}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: unlocked ? null : Theme.of(context).disabledColor,
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  const _StreakCalendar({required this.weeklyXp});
  final List<int> weeklyXp;

  @override
  Widget build(BuildContext context) {
    final data = weeklyXp.length == 7 ? weeklyXp : List.filled(7, 0);
    final max = data.reduce((a, b) => a > b ? a : b).clamp(1, 9999);
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = (data[i] / max * 48).clamp(6.0, 48.0);
          final active = data[i] > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: h,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(days[i], style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
