import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/widgets/week_xp_chart.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/learning_entities.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();

    return Scaffold(
      appBar: AppBar(title: const Text('Кабинет родителя')),
      body: FutureBuilder(
        future: ref.read(progressRepoProvider).getAllProgress(),
        builder: (context, snap) {
          final all = snap.data ?? {};
          final mastered =
              all.values.where((p) => p.mastery.isMastered && !p.seededFromPlacement).length;
          final learning = all.values.where((p) => p.mastery.isLearned && !p.mastery.isMastered).length;
          final struggling = all.values.where((p) => p.wrongCount > 2).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatCard('Время сегодня', '${profile.todayMinutes} мин'),
              _StatCard('Серия дней', '${profile.streakDays}'),
              _StatCard('Освоено слов', '$mastered'),
              _StatCard('В процессе', '$learning'),
              _StatCard('Нужно повторить', '$struggling'),
              const SizedBox(height: 24),
              Text('Отчёт за неделю', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              // Реальный график недельного XP вместо заглушки "в следующем
              // обновлении" — данные уже собираются (используются в
              // home_screen.dart/progress_screen.dart), теперь родитель тоже
              // видит реальную картину, а не пустое обещание (аудит §low).
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: WeekXpChart(weeklyXp: profile.weeklyXp),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
