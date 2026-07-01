import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/glass_card.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Прогресс')),
      body: FutureBuilder(
        future: progressRepo.getAllProgress(),
        builder: (context, snap) {
          final wordsStudied = snap.data?.length ?? 0;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сегодня', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    _Row('Слов', '${profile.wordsLearnedToday} / ${profile.dailyGoalWords}'),
                    _Row('XP', '${profile.xp}'),
                    _Row('Уровень', '${profile.level}'),
                    _Row('Монеты', '🪙 ${profile.coins}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Неделя · Месяц', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    _Row('XP за неделю', '$weekXp'),
                    _Row('Слов в работе', '$wordsStudied'),
                    _Row('Словарь', '${mastery.valueOrNull ?? 0}%'),
                    _Row('Уроков', '${profile.lessonsCompletedTotal}'),
                    _Row('Серия', '${profile.streakDays} дн.'),
                    _Row(
                      'Активность',
                      (profile.lastActiveDate ?? '').isEmpty ? '—' : profile.lastActiveDate!,
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Достижения', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                ..._achievements.entries.map((e) {
                  final unlocked = profile.achievements.contains(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(unlocked ? e.value : '🔒 ${e.value.split(' ').skip(1).join(' ')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: unlocked ? null : Colors.grey,
                            )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
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
