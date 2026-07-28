import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/chechen_audio_controls.dart';
import '../../core/widgets/word_illustration.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/word_entity.dart';

class KidsSessionScreen extends ConsumerStatefulWidget {
  const KidsSessionScreen({super.key});

  @override
  ConsumerState<KidsSessionScreen> createState() => _KidsSessionScreenState();
}

class _KidsSessionScreenState extends ConsumerState<KidsSessionScreen> {
  int _step = 0;
  String? _answer;

  int _wordCount(UserProfileEntity profile) => switch (profile.ageGroup) {
    KidsAgeGroup.age3to6 => 3,
    KidsAgeGroup.age6to9 => 4,
    KidsAgeGroup.age9to12 => 5,
  };

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final daily = ref.watch(todayContentProvider);
    return AppScaffold(
      body: daily.when(
        data: (content) {
          if (content == null) {
            return const Center(child: Text('Занятие пока недоступно'));
          }
          final words = content.newWords.take(_wordCount(profile)).toList();
          final phrase = content.phraseOfTheDay;
          final quizIndex = words.length + (phrase == null ? 0 : 1);
          if (_step < words.length) {
            return _WordStep(
              word: words[_step],
              progress: (_step + 1) / (quizIndex + 1),
              onNext: () => setState(() => _step++),
            );
          }
          if (phrase != null && _step == words.length) {
            return _WordStep(
              word: phrase,
              progress: (_step + 1) / (quizIndex + 1),
              phrase: true,
              onNext: () => setState(() => _step++),
            );
          }
          if (_step == quizIndex && words.length >= 2) {
            final target = words.first;
            final options = words.map((word) => word.russian).toList()..sort();
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: (_step + 1) / (quizIndex + 1)),
                  const Spacer(),
                  Text(
                    target.chechen,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final option in options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: OutlinedButton(
                        onPressed: _answer == null
                            ? () => setState(() => _answer = option)
                            : null,
                        child: Text(option),
                      ),
                    ),
                  if (_answer != null) ...[
                    Text(
                      _answer == target.russian
                          ? 'Верно!'
                          : 'Правильный ответ: ${target.russian}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => setState(() => _step++),
                      child: const Text('Завершить'),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            );
          }
          return Center(
            child: FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('Занятие завершено'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Не удалось начать занятие')),
      ),
    );
  }
}

class _WordStep extends StatelessWidget {
  const _WordStep({
    required this.word,
    required this.progress,
    required this.onNext,
    this.phrase = false,
  });

  final WordEntity word;
  final double progress;
  final VoidCallback onNext;
  final bool phrase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const Spacer(),
          if (!phrase)
            Center(
              child: WordIllustration(
                category: word.category,
                emoji: word.emoji,
                size: 150,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            word.chechen,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            word.russian,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: ChechenAudioControls(audioId: word.audioId)),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            child: Text(phrase ? 'К викторине' : 'Дальше'),
          ),
        ],
      ),
    );
  }
}
