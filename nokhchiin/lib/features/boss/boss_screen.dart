import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_flags.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/empty_state.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/exercise_word_pool.dart';
import '../../core/utils/gameplay_difficulty.dart';
import '../../domain/entities/content_entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/word_entity.dart';
import '../games/widgets/exercise_presentation.dart';
import '../games/widgets/game_session_widgets.dart';

final _audioProvider = Provider((_) => AudioService());
final _rng = Random();

class BossScreen extends ConsumerStatefulWidget {
  const BossScreen({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<BossScreen> createState() => _BossScreenState();
}

class _BossScreenState extends ConsumerState<BossScreen> {
  final _combo = GameComboTracker();

  List<WordEntity> _words = [];
  List<List<WordEntity>> _optionsPerQuestion = [];
  BossEntity? _boss;
  bool _loading = true;
  int _index = 0;
  int _score = 0;
  int _secondsLeft = 120;
  Timer? _timer;
  bool _finished = false;
  int? _selectedOption;
  bool _revealing = false;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = ref.read(contentSourceProvider);
    final boss = await content.loadBossForUnit(widget.unitId);
    if (boss == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    _boss = boss;

    final profile = ref.read(userProfileProvider).value;
    final optionCount = GameplayDifficulty.quizOptionCount(
      mode: profile?.mode ?? AppMode.kids,
      age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
    );
    final words = await ExerciseWordPool.loadForUnit(
      ref.read(dictionaryRepoProvider),
      widget.unitId,
      minCount: optionCount,
      take: boss.questionsCount,
      rng: _rng,
    );

    final options = words
        .map(
          (w) => ExerciseWordPool.buildQuizOptions(
            pool: words,
            target: w,
            optionCount: optionCount,
            rng: _rng,
          ),
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _words = words;
      _optionsPerQuestion = options;
      _secondsLeft = boss.timeLimitSec;
      _loading = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _finish();
      } else if (mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _unlockNextWorld() async {
    final worlds = await ref.read(worldsProvider.future);
    if (!mounted) return false;
    final idx = worlds.indexWhere((w) => w.units.contains(widget.unitId));
    if (idx >= 0 && idx < worlds.length - 1) {
      final nextId = worlds[idx + 1].id;
      await ref.read(userProfileProvider.notifier).unlockWorld(nextId);
      return true;
    }
    return false;
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();

    final pass = _boss?.passScore ?? 8;
    final won = _score >= pass;
    var unlockedWorld = false;

    if (won) {
      await ref.read(userProfileProvider.notifier).addXp(
            _boss?.rewardXp ?? 100,
            _boss?.rewardStars ?? 25,
          );
      unlockedWorld = await _unlockNextWorld();
      await ref.read(userProfileProvider.notifier).unlockAchievement('collector');
    }
    if (!mounted) return;

    await RewardCelebration.show(
      context,
      iconAsset: won ? AppIcons.rewardTrophy : AppIcons.stateEmpty,
      title: won ? 'Победа!' : 'Попробуй ещё',
      subtitle: won
          ? 'Счёт: $_score / ${_words.length}'
              '${unlockedWorld ? '\nНовый мир открыт!' : ''}'
          : 'Счёт: $_score / ${_words.length}',
      dismissLabel: 'OK',
      onDismiss: () {
        Navigator.of(context).pop();
        context.pop();
      },
    );
  }

  Future<void> _answer(int optionIndex) async {
    if (_selectedOption != null || _index >= _words.length) return;

    final target = _words[_index];
    final options = _optionsPerQuestion[_index];
    final picked = options[optionIndex];
    final correct = picked.id == target.id;

    setState(() {
      _selectedOption = optionIndex;
      _revealing = true;
      _lastCorrect = correct;
    });

    if (correct) {
      _score++;
      _combo.recordCorrect();
      await ref.read(reviewWordUseCaseProvider)(target.id, 5);
    } else {
      _combo.reset();
      await ref.read(reviewWordUseCaseProvider)(target.id, 1);
    }

    await Future.delayed(correct ? AppDurations.normal : AppDurations.slow);
    if (!mounted) return;

    setState(() {
      _selectedOption = null;
      _revealing = false;
      _lastCorrect = null;
      _index++;
    });

    if (_index >= _words.length) {
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(body: LoadingState(message: 'Босс готовится…'));
    }
    if (_boss == null) {
      return AppScaffold(
        title: 'Босс недоступен',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_empty_rounded, size: 56),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Для этого юнита пока нет босса. Загляни сюда позже.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_words.isEmpty) {
      return const AppScaffold(
        body: EmptyState(
          iconAsset: AppIcons.stateEmpty,
          title: 'Недостаточно слов для босса',
        ),
      );
    }
    if (_index >= _words.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const AppScaffold(body: LoadingState());
    }

    final target = _words[_index];
    final options = _optionsPerQuestion[_index];

    return AppScaffold(
      title: 'Босс: ${_boss!.titleRu}',
      actions: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 4),
              Text('$_secondsLeft'),
            ],
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            ExerciseProgressHeader(
              step: _index + 1,
              total: _words.length,
              combo: _combo.streak,
              label: '★ $_score · ${_boss!.emoji ?? '⚔️'} ${_boss!.titleCe}',
            ),
            const SizedBox(height: AppSpacing.md),
            AnswerFeedbackAnimator(
              feedback: _lastCorrect,
              child: WordExerciseCard(
                word: target,
                categoryId: widget.unitId,
              ),
            ).animate(key: ValueKey(target.id)).fadeIn(),
            if (FeatureFlags.audioEnabled)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 36),
                onPressed: () =>
                    ref.read(_audioProvider).speakChechen(target.chechen),
              ),
            const Spacer(),
            ...options.asMap().entries.map((entry) {
              final i = entry.key;
              final o = entry.value;
              final isTarget = o.id == target.id;
              final wasSelected = _selectedOption == i;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NokhchiinQuizOption(
                  label: o.emoji != null ? '${o.emoji}  ${o.russian}' : o.russian,
                  letter: String.fromCharCode(65 + i),
                  selected: wasSelected ? true : null,
                  correct: wasSelected ? isTarget : null,
                  revealAsCorrect: _revealing && isTarget && !wasSelected,
                  enabled: _selectedOption == null,
                  onTap: () => _answer(i),
                ),
              );
            }),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}