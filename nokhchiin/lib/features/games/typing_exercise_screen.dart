import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/tokens/nokhchiin_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/empty_state.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/chechen_text_utils.dart';
import '../../domain/entities/word_entity.dart';

final _rng = Random();

/// Упражнение CE→RU: показ русского, ввод чеченского с кастомной клавиатурой.
class TypingExerciseScreen extends ConsumerStatefulWidget {
  const TypingExerciseScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<TypingExerciseScreen> createState() => _TypingExerciseScreenState();
}

class _TypingExerciseScreenState extends ConsumerState<TypingExerciseScreen> {
  final _controller = TextEditingController();
  List<WordEntity> _words = [];
  int _index = 0;
  int _score = 0;
  bool? _lastCorrect;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.length < 3) {
      // Раньше .take(10) без shuffle пула — всегда один и тот же набор
      // первых 10 слов словаря (аудит §7). Копируем перед shuffle —
      // getAllWords() отдаёт общий закэшированный список.
      final all = [...await ref.read(dictionaryRepoProvider).getAllWords()]..shuffle(_rng);
      words = all.take(10).toList();
    }
    words.shuffle(_rng);
    if (mounted) {
      setState(() {
        _words = words.take(6).toList();
        _loading = false;
      });
    }
  }

  Future<void> _check() async {
    if (_words.isEmpty) return;
    if (_lastCorrect != null) return; // блокируем повторный тап, пока идёт фидбек (аудит §2)
    final target = _words[_index];
    // Нормализуем палочку Ӏ и её ASCII-замены (1/I/i/l/|/!) тем же способом,
    // что и поиск словаря — иначе ввод "kIant" вместо "кӀант" (обычная
    // практика без чеченской раскладки) засчитывается как ошибка, хотя то
    // же самое прекрасно находится в поиске (аудит §7).
    final input = ChechenTextUtils.normalizeForSearch(_controller.text);
    final expected = ChechenTextUtils.normalizeForSearch(target.chechen);
    final correct = input == expected;

    setState(() => _lastCorrect = correct);
    HapticFeedback.mediumImpact();

    // Ждём запись в Hive перед переходом дальше — раньше это было
    // "выстрелил и забыл" на пути начисления награды (аудит §2).
    if (correct) {
      _score++;
      await ref.read(reviewWordUseCaseProvider)(target.id, 5);
      await ref.read(userProfileProvider.notifier).recordWordLearned();
    } else {
      await ref.read(reviewWordUseCaseProvider)(target.id, 1);
    }
    if (!mounted) return;

    Future.delayed(AppDurations.normal, () async {
      if (!mounted) return;
      if (_index < _words.length - 1) {
        setState(() {
          _index++;
          _controller.clear();
          _lastCorrect = null;
        });
      } else {
        await ref.read(userProfileProvider.notifier).addXp(30, 6);
        if (!mounted) return;
        await RewardCelebration.show(
          context,
          iconAsset: AppIcons.rewardCelebration,
          title: 'Отлично!',
          subtitle: 'Правильно: $_score / ${_words.length} · +30 XP',
          onDismiss: () {
            Navigator.of(context).pop();
            context.pop();
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(body: LoadingState());
    }
    if (_words.isEmpty) {
      // Общий EmptyState вместо голого Text — тот же паттерн, что уже
      // использует quiz_screen.dart (аудит §low).
      return const AppScaffold(
        body: EmptyState(iconAsset: AppIcons.stateEmpty, title: 'Недостаточно слов для упражнения'),
      );
    }

    final word = _words[_index];
    final feedbackColor = _lastCorrect == null
        ? null
        : _lastCorrect!
            ? NokhchiinColors.success
            : NokhchiinColors.error;

    return AppScaffold(
      title: 'Ввод · ${_index + 1}/${_words.length}',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              decoration: BoxDecoration(
                color: feedbackColor?.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Как будет по-чеченски?',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        // Иконка, а не только цвет фона — WCAG 1.4.1
                        // (аудит §medium).
                        if (_lastCorrect != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            _lastCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 16,
                            color: feedbackColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      word.russian,
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (word.hint != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(word.hint!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ).animate(key: ValueKey(_index)).fadeIn().slideY(begin: 0.05),
            const SizedBox(height: AppSpacing.xl),
            ChechenKeyboard(
              controller: _controller,
              onSubmit: _check,
              hintText: 'Маршалла, Цициг…',
            ),
            if (_lastCorrect == false) ...[
              const SizedBox(height: AppSpacing.md),
              WordExerciseCard(
                word: word,
                categoryId: widget.unitId,
                showRussian: true,
              ).animate().shake(),
            ],
            const Spacer(),
            AppButton(label: 'Проверить', onPressed: _check),
          ],
        ),
      ),
    );
  }
}
