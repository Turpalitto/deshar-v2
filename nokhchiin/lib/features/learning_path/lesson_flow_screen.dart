import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';

/// Урок: слова → игра → тест → награда (3–5 мин).
class LessonFlowScreen extends ConsumerStatefulWidget {
  const LessonFlowScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  int _step = 0; // 0 cards intro, 1 quiz, 2 reward

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Урок · шаг ${_step + 1}/3')),
      body: Center(
        child: switch (_step) {
          0 => _StepCard(
              emoji: '🎴',
              title: 'Изучи слова',
              subtitle: '5–8 карточек с картинками',
              onStart: () => context.push('/flashcards/${widget.unitId}').then((_) => setState(() => _step = 1)),
            ),
          1 => _StepCard(
              emoji: '❓',
              title: 'Мини-тест',
              subtitle: 'Проверь себя',
              onStart: () => context.push('/quiz/${widget.unitId}').then((_) => setState(() => _step = 2)),
            ),
          _ => _StepCard(
              emoji: '🏆',
              title: 'Награда!',
              subtitle: 'Урок завершён',
              onStart: () async {
                await ref.read(userProfileProvider.notifier).addXp(40, 10);
                await ref.read(userProfileProvider.notifier).completeLesson();
                await ref.read(userProfileProvider.notifier).unlockAchievement('first_lesson');
                if (context.mounted) context.pop();
              },
              buttonLabel: 'Забрать награду',
            ),
        },
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onStart,
    this.buttonLabel = 'Начать',
  });

  final String emoji, title, subtitle, buttonLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          FilledButton(onPressed: onStart, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
