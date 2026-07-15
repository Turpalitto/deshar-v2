import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/exercise_word_pool.dart';
import '../../core/utils/gameplay_difficulty.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/word_entity.dart';
import 'widgets/exercise_presentation.dart';
import 'widgets/game_session_widgets.dart';

final _rng = Random();

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.unitId,
    this.embedded = false,
    this.maxQuestions,
    this.onComplete,
  });
  final String unitId;
  final bool embedded;
  final int? maxQuestions;
  final VoidCallback? onComplete;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _combo = GameComboTracker();
  List<WordEntity> _words = [];
  List<WordEntity> _options = [];
  int _index = 0;
  int _score = 0;
  bool _loading = true;
  bool? _lastCorrect;
  int? _selectedOption;
  bool _revealing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = ref.read(userProfileProvider).value;
    final optionCount = GameplayDifficulty.quizOptionCount(
      mode: profile?.mode ?? AppMode.kids,
      age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
    );
    final words = await ExerciseWordPool.loadForUnit(
      ref.read(dictionaryRepoProvider),
      widget.unitId,
      minCount: optionCount,
      take: 20,
      rng: _rng,
    );
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
      _buildOptions();
    }
  }

  int _optionCount() {
    final profile = ref.read(userProfileProvider).value;
    return GameplayDifficulty.quizOptionCount(
      mode: profile?.mode ?? AppMode.kids,
      age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
    );
  }

  void _buildOptions() {
    final target = _words[_index];
    _options = ExerciseWordPool.buildQuizOptions(
      pool: _words,
      target: target,
      optionCount: _optionCount(),
      rng: _rng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      if (widget.embedded) {
        return Center(child: NokhchiinLoadingState(message: l10n.loading));
      }
      return AppScaffold(body: NokhchiinLoadingState(message: l10n.loading));
    }
    if (_words.length < _optionCount()) {
      if (widget.embedded) {
        return NokhchiinEmptyState(
          iconAsset: AppIcons.stateEmpty,
          title: l10n.notEnoughWords,
        );
      }
      return AppScaffold(
        body: NokhchiinEmptyState(
          iconAsset: AppIcons.stateEmpty,
          title: l10n.notEnoughWords,
        ),
      );
    }

    final questionLimit = widget.maxQuestions ?? _words.length;
    final totalQ = questionLimit.clamp(1, _words.length);
    final target = _words[_index];

    final body = ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ExerciseProgressHeader(
          step: _index + 1,
          total: totalQ,
          combo: _combo.streak,
          label: widget.embedded ? 'Вопрос ${_index + 1} / $totalQ' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AnswerFeedbackAnimator(
          feedback: _lastCorrect,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: WordExerciseCard(
              key: ValueKey(target.id),
              word: target,
              categoryId: widget.unitId,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.quizTapHint,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (_revealing && !(_lastCorrect ?? true) && target.hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NokhchiinChip(
            label: target.hint!,
            color: context.iosTokens.textSecondary,
            background: context.iosTokens.surfaceMuted,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ..._options.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          final isTarget = o.id == target.id;
          final wasSelected = _selectedOption == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: NokhchiinQuizOption(
              label: o.emoji != null ? '${o.emoji}  ${o.russian}' : o.russian,
              letter: String.fromCharCode(65 + i),
              selected: wasSelected ? true : null,
              correct: wasSelected ? isTarget : null,
              revealAsCorrect: _revealing && isTarget && !wasSelected,
              enabled: _selectedOption == null,
              onTap: () => _answer(isTarget, target, totalQ, i),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
      ],
    );

    if (widget.embedded) return body;
    return AppScaffold(title: l10n.quizTitle(_score), body: body);
  }

  Future<void> _answer(
    bool correct,
    WordEntity target,
    int totalQ,
    int optionIndex,
  ) async {
    setState(() {
      _lastCorrect = correct;
      _selectedOption = optionIndex;
      _revealing = true;
    });
    if (correct) {
      _score++;
      _combo.recordCorrect();
    } else {
      _combo.reset();
    }

    await ref.read(reviewWordUseCaseProvider)(target.id, correct ? 4 : 1);
    final delay = correct ? AppDurations.normal : AppDurations.slow;
    await Future.delayed(delay);
    if (!mounted) return;

    setState(() {
      _lastCorrect = null;
      _selectedOption = null;
      _revealing = false;
    });

    if (_index < totalQ - 1) {
      setState(() => _index++);
      _buildOptions();
    } else if (widget.embedded) {
      widget.onComplete?.call();
    } else {
      await ref.read(userProfileProvider.notifier).addXp(50, 5);
      if (!mounted) return;
      await RewardCelebration.show(
        context,
        iconAsset: AppIcons.rewardCelebration,
        title: 'Викторина пройдена!',
        subtitle: 'Правильно: $_score / $totalQ · +50 XP',
        onDismiss: () {
          Navigator.of(context).pop();
          context.pop();
        },
      );
    }
  }
}
