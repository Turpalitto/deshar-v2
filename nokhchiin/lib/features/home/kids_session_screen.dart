import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/chechen_text_utils.dart';
import '../../core/widgets/chechen_audio_controls.dart';
import '../../core/widgets/word_illustration.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/constants/gameplay_constants.dart';

class KidsSessionScreen extends ConsumerStatefulWidget {
  const KidsSessionScreen({super.key});

  @override
  ConsumerState<KidsSessionScreen> createState() => _KidsSessionScreenState();
}

class _KidsSessionScreenState extends ConsumerState<KidsSessionScreen> {
  final _startedAt = DateTime.now();
  final _typingController = TextEditingController();
  final _seenWordIds = <String>{};

  int _step = 0;
  String? _answer;
  bool? _isCorrect;
  bool _busy = false;
  bool _sessionRecorded = false;
  bool _sessionStartedTracked = false;
  int _correctAnswers = 0;

  int _wordCount(UserProfileEntity profile) => switch (profile.ageGroup) {
    KidsAgeGroup.age3to6 => GameplayConstants.kidsAge3to6SessionWordCount,
    KidsAgeGroup.age6to9 => GameplayConstants.kidsAge6to9SessionWordCount,
    KidsAgeGroup.age9to12 => GameplayConstants.kidsAge9to12SessionWordCount,
  };

  Future<void> _track(
    AnalyticsEventName name, {
    Map<String, String> properties = const {},
  }) async {
    try {
      await ref
          .read(analyticsServiceProvider)
          .track(name, properties: properties);
    } catch (_) {
      // Analytics must never interrupt a learning session.
    }
  }

  void _trackSessionStarted(KidsAgeGroup ageGroup) {
    if (_sessionStartedTracked) return;
    _sessionStartedTracked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _track(
        AnalyticsEventName.sessionStarted,
        properties: {'mode': 'kids', 'age_group': ageGroup.name},
      );
    });
  }

  Future<void> _rememberWord(WordEntity word) async {
    if (_busy) return;
    setState(() => _busy = true);
    final isFirstExposure = _seenWordIds.add(word.id);
    try {
      if (isFirstExposure) {
        await ref.read(markWordSeenUseCaseProvider)(word.id);
        await _track(
          AnalyticsEventName.wordFirstSeen,
          properties: {'word_id': word.id, 'mode': 'kids'},
        );
      }
      if (mounted) setState(() => _step++);
    } catch (_) {
      if (isFirstExposure) _seenWordIds.remove(word.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить прогресс')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitAnswer(
    WordEntity target,
    String answer,
    bool isCorrect,
  ) async {
    if (_busy || _answer != null) return;
    setState(() => _busy = true);
    try {
      await ref.read(reviewWordUseCaseProvider)(target.id, isCorrect ? 4 : 1);
      await _track(
        AnalyticsEventName.answerSubmitted,
        properties: {
          'word_id': target.id,
          'correct': isCorrect.toString(),
          'mode': 'kids',
        },
      );
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _isCorrect = isCorrect;
        if (isCorrect) _correctAnswers++;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить ответ')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishSession(List<WordEntity> words) async {
    if (_busy || _sessionRecorded) return;
    setState(() => _busy = true);
    final learnedIds = words.map((word) => word.id).toSet();
    final learnedCount = _seenWordIds.intersection(learnedIds).length;
    final elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
    final minutes = ((elapsedSeconds + 59) ~/ 60).clamp(
      GameplayConstants.minimumRecordedSessionMinutes,
      GameplayConstants.maximumRecordedSessionMinutes,
    );
    try {
      await ref.read(recordDailyTaskUseCaseProvider)(
        date: _startedAt,
        taskId: 'kids_session',
        selectedWordIds: words.map((word) => word.id).toList(),
        quizScore: _correctAnswers,
        quizTotal: words.length,
        minutesSpent: minutes,
        finishedAt: DateTime.now(),
      );
      await ref
          .read(userProfileProvider.notifier)
          .recordKidsSession(
            wordsLearned: learnedCount,
            minutes: minutes,
            date: _startedAt,
          );
      await _track(
        AnalyticsEventName.sessionCompleted,
        properties: {
          'mode': 'kids',
          'words': learnedCount.toString(),
          'minutes': minutes.toString(),
        },
      );
      ref.invalidate(dailyHistoryProvider);
      if (!mounted) return;
      setState(() => _sessionRecorded = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось завершить занятие')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueQuiz({
    required List<WordEntity> words,
    required bool isLast,
  }) async {
    if (isLast) {
      await _finishSession(words);
      return;
    }
    setState(() {
      _step++;
      _answer = null;
      _isCorrect = null;
      _typingController.clear();
    });
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

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
          if (words.isEmpty) {
            return const Center(child: Text('Слова для занятия не найдены'));
          }
          final phrase = content.phraseOfTheDay;
          final quizStart = words.length + (phrase == null ? 0 : 1);
          final totalSteps = quizStart + words.length;
          _trackSessionStarted(profile.ageGroup);

          if (_step < words.length) {
            return _WordStep(
              word: words[_step],
              progress: (_step + 1) / totalSteps,
              busy: _busy,
              compactCopy: profile.ageGroup == KidsAgeGroup.age3to6,
              onNext: () => _rememberWord(words[_step]),
            );
          }
          if (phrase != null && _step == words.length) {
            return _WordStep(
              word: phrase,
              progress: (_step + 1) / totalSteps,
              phrase: true,
              busy: _busy,
              onNext: () => _rememberWord(phrase),
            );
          }
          final quizOffset = _step - quizStart;
          if (quizOffset >= 0 &&
              quizOffset < words.length &&
              words.length >= 2 &&
              !_sessionRecorded) {
            final target = words[quizOffset];
            final isLast = quizOffset == words.length - 1;
            final progress = (_step + 1) / totalSteps;
            return switch (profile.ageGroup) {
              KidsAgeGroup.age3to6 => _PictureChoiceQuiz(
                target: target,
                options: words,
                progress: progress,
                answer: _answer,
                isCorrect: _isCorrect,
                busy: _busy,
                onSelected: (word) =>
                    _submitAnswer(target, word.id, word.id == target.id),
                onContinue: () => _continueQuiz(words: words, isLast: isLast),
                continueLabel: isLast ? 'Завершить' : 'Дальше',
              ),
              KidsAgeGroup.age6to9 => _ChoiceQuiz(
                target: target,
                options: words,
                progress: progress,
                answer: _answer,
                isCorrect: _isCorrect,
                busy: _busy,
                onSelected: (answer) =>
                    _submitAnswer(target, answer, answer == target.russian),
                onContinue: () => _continueQuiz(words: words, isLast: isLast),
                continueLabel: isLast ? 'Завершить' : 'Дальше',
              ),
              KidsAgeGroup.age9to12 => _TypingQuiz(
                target: target,
                progress: progress,
                controller: _typingController,
                answer: _answer,
                isCorrect: _isCorrect,
                busy: _busy,
                onSubmit: (answer) => _submitAnswer(
                  target,
                  answer,
                  ChechenTextUtils.normalizeForSearch(answer) ==
                      ChechenTextUtils.normalizeForSearch(target.chechen),
                ),
                onContinue: () => _continueQuiz(words: words, isLast: isLast),
                continueLabel: isLast ? 'Завершить' : 'Дальше',
              ),
            };
          }
          if (!_sessionRecorded) {
            return _FinishSessionButton(
              busy: _busy,
              onPressed: () => _finishSession(words),
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
    required this.busy,
    this.phrase = false,
    this.compactCopy = false,
  });

  final WordEntity word;
  final double progress;
  final Future<void> Function() onNext;
  final bool busy;
  final bool phrase;
  final bool compactCopy;

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
                size: compactCopy ? 176 : 150,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            word.chechen,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            word.russian,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: ChechenAudioControls(audioId: word.audioId)),
          const Spacer(),
          FilledButton(
            onPressed: busy ? null : onNext,
            child: Text(phrase ? 'К заданию' : 'Дальше'),
          ),
        ],
      ),
    );
  }
}

class _PictureChoiceQuiz extends StatelessWidget {
  const _PictureChoiceQuiz({
    required this.target,
    required this.options,
    required this.progress,
    required this.answer,
    required this.isCorrect,
    required this.busy,
    required this.onSelected,
    required this.onContinue,
    required this.continueLabel,
  });

  final WordEntity target;
  final List<WordEntity> options;
  final double progress;
  final String? answer;
  final bool? isCorrect;
  final bool busy;
  final Future<void> Function(WordEntity) onSelected;
  final Future<void> Function() onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final hasAudio = target.audioId?.isNotEmpty ?? false;
    final visibleOptions = [
      target,
      ...options.where((word) => word.id != target.id),
    ].take(4).toList()..sort((a, b) => a.russian.compareTo(b.russian));
    return _QuizLayout(
      progress: progress,
      prompt: hasAudio
          ? 'Послушай и найди картинку'
          : 'Найди картинку для слова',
      clue: hasAudio ? 'Включи запись' : target.chechen,
      audioId: target.audioId,
      result: _resultText(isCorrect, target.russian),
      busy: busy,
      onContinue: onContinue,
      continueLabel: continueLabel,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.15,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final option in visibleOptions)
            OutlinedButton(
              onPressed: answer == null && !busy
                  ? () => onSelected(option)
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WordIllustration(
                    category: option.category,
                    emoji: option.emoji,
                    size: 64,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      option.russian,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceQuiz extends StatelessWidget {
  const _ChoiceQuiz({
    required this.target,
    required this.options,
    required this.progress,
    required this.answer,
    required this.isCorrect,
    required this.busy,
    required this.onSelected,
    required this.onContinue,
    required this.continueLabel,
  });

  final WordEntity target;
  final List<WordEntity> options;
  final double progress;
  final String? answer;
  final bool? isCorrect;
  final bool busy;
  final Future<void> Function(String) onSelected;
  final Future<void> Function() onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final labels = options.map((word) => word.russian).toList()..sort();
    return _QuizLayout(
      progress: progress,
      prompt: 'Что означает это слово?',
      clue: target.chechen,
      result: _resultText(isCorrect, target.russian),
      busy: busy,
      onContinue: onContinue,
      continueLabel: continueLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in labels)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: OutlinedButton(
                onPressed: answer == null && !busy
                    ? () => onSelected(option)
                    : null,
                child: Text(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingQuiz extends StatelessWidget {
  const _TypingQuiz({
    required this.target,
    required this.progress,
    required this.controller,
    required this.answer,
    required this.isCorrect,
    required this.busy,
    required this.onSubmit,
    required this.onContinue,
    required this.continueLabel,
  });

  final WordEntity target;
  final double progress;
  final TextEditingController controller;
  final String? answer;
  final bool? isCorrect;
  final bool busy;
  final Future<void> Function(String) onSubmit;
  final Future<void> Function() onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return _QuizLayout(
      progress: progress,
      prompt: 'Напиши по-чеченски',
      clue: target.russian,
      result: _resultText(isCorrect, target.chechen),
      busy: busy,
      onContinue: onContinue,
      continueLabel: continueLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            enabled: answer == null && !busy,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Твой ответ'),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) onSubmit(value.trim());
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: answer == null && !busy
                ? () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) onSubmit(value);
                  }
                : null,
            child: const Text('Проверить'),
          ),
        ],
      ),
    );
  }
}

class _QuizLayout extends StatelessWidget {
  const _QuizLayout({
    required this.progress,
    required this.prompt,
    required this.clue,
    required this.result,
    required this.busy,
    required this.onContinue,
    required this.continueLabel,
    required this.child,
    this.audioId,
  });

  final double progress;
  final String prompt;
  final String clue;
  final String? audioId;
  final String? result;
  final bool busy;
  final Future<void> Function() onContinue;
  final String continueLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              clue,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (audioId != null) ...[
              const SizedBox(height: AppSpacing.md),
              Center(child: ChechenAudioControls(audioId: audioId)),
            ],
            const SizedBox(height: AppSpacing.xl),
            child,
            if (result != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                result!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: busy ? null : onContinue,
                child: Text(continueLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinishSessionButton extends StatelessWidget {
  const _FinishSessionButton({required this.busy, required this.onPressed});

  final bool busy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: const Text('Завершить занятие'),
      ),
    );
  }
}

String? _resultText(bool? isCorrect, String correctAnswer) {
  if (isCorrect == null) return null;
  return isCorrect ? 'Верно!' : 'Правильный ответ: $correctAnswer';
}
