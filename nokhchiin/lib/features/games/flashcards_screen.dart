import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/design_system.dart';
import '../../core/design/tokens/app_spacing.dart'; // intentional-mix: spacing tokens; Figma widgets from design_system
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart'; // intentional-mix: reward dialog actions
import '../../core/design/widgets/empty_state.dart'; // intentional-mix: empty list fallback
import '../../core/design/widgets/loading_state.dart'; // intentional-mix: shared loading placeholder
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../core/utils/exercise_word_pool.dart';
import '../../core/utils/gameplay_difficulty.dart';
import '../../domain/entities/word_entity.dart';
import 'widgets/game_session_widgets.dart';
import 'widgets/spring_swipe_card.dart';

final _rng = Random();

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({
    super.key,
    required this.unitId,
    this.embedded = false,
    this.onComplete,
  });
  final String unitId;
  final bool embedded;
  final VoidCallback? onComplete;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final _swipeController = SpringSwipeCardController();
  final _combo = GameComboTracker();

  List<WordEntity> _words = [];
  int _index = 0;
  bool _showTranslation = false;
  bool _loading = true;
  bool _showFlipNudge = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = ref.read(userProfileProvider).value;
    final limit = GameplayDifficulty.flashcardCount(
      mode: profile?.mode ?? AppMode.kids,
      age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
    );
    final words = await ExerciseWordPool.loadForUnit(
      ref.read(dictionaryRepoProvider),
      widget.unitId,
      minCount: 1,
      take: limit,
      rng: _rng,
    );
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
    }
  }

  bool _needsFlipFirst(WidgetRef ref) {
    final profile = ref.read(userProfileProvider).value;
    return profile?.mode == AppMode.kids &&
        profile?.ageGroup == KidsAgeGroup.age3to6;
  }

  Future<void> _known(bool yes) async {
    if (yes && _needsFlipFirst(ref) && !_showTranslation) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showFlipNudge = true);
      return;
    }

    final w = _words[_index];
    await ref.read(reviewWordUseCaseProvider)(w.id, yes ? 5 : 2);
    if (yes) {
      _combo.recordCorrect();
      await ref.read(userProfileProvider.notifier).recordWordLearned();
    } else {
      _combo.reset();
    }
    if (!mounted) return; // аудит §2: раньше проверялось только в ветке "последняя карточка"

    if (_index < _words.length - 1) {
      setState(() {
        _index++;
        _showTranslation = false;
        _showFlipNudge = false;
      });
    } else {
      if (widget.embedded) {
        widget.onComplete?.call();
      } else {
        await ref.read(userProfileProvider.notifier).addXp(25, 5);
        if (mounted) unawaited(_showReward());
      }
    }
  }

  // Единый фирменный RewardCelebration вместо голого AlertDialog — раньше
  // в приложении было три разных диалога "успех" (аудит §2/§3).
  Future<void> _showReward() async {
    await RewardCelebration.show(
      context,
      iconAsset: AppIcons.rewardCelebration,
      title: 'Урок пройден!',
      subtitle: '+25 XP · +5 монет',
      primaryAction: 'Ввод по-чеченски',
      onPrimary: () {
        Navigator.of(context).pop();
        context.push('/typing/${widget.unitId}');
      },
      onDismiss: () {
        Navigator.of(context).pop();
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      if (widget.embedded) return const Center(child: LoadingState(message: 'Готовим карточки…'));
      return const AppScaffold(body: LoadingState(message: 'Готовим карточки…'));
    }
    if (_words.isEmpty) {
      const empty = EmptyState(
        iconAsset: AppIcons.stateEmpty,
        title: 'Недостаточно слов',
        subtitle: 'Вернись позже — мы добавим слова для этого урока',
      );
      if (widget.embedded) return empty;
      return const AppScaffold(body: empty);
    }

    final w = _words[_index];
    final isKids = ref.watch(userProfileProvider).value?.mode == AppMode.kids;
    final flipFirst = _needsFlipFirst(ref);
    final canMarkKnown = !flipFirst || _showTranslation;

    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          ExerciseProgressHeader(
            step: _index + 1,
            total: _words.length,
            combo: _combo.streak,
            label: 'Слова · ${_index + 1} / ${_words.length}',
          ),
          const SizedBox(height: AppSpacing.md),
          if (_showFlipNudge && flipFirst && !_showTranslation) ...[
            NokhchiinChip(
              label: 'Сначала переверните карточку',
              color: context.iosTokens.accent,
              background: context.iosTokens.accentMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(
            child: SpringSwipeCard(
              key: ValueKey(w.id),
              controller: _swipeController,
              onSwipeLeft: () {
                HapticFeedback.heavyImpact();
                _known(false);
              },
              onSwipeRight: () {
                if (!canMarkKnown) {
                  HapticFeedback.mediumImpact();
                  setState(() => _showFlipNudge = true);
                  return;
                }
                HapticFeedback.lightImpact();
                _known(true);
              },
              child: NokhchiinFlipCard(
                flipped: _showTranslation,
                onTap: () => setState(() {
                  _showTranslation = !_showTranslation;
                  if (_showTranslation) _showFlipNudge = false;
                }),
                front: NokhchiinFlashcardFace(
                  child: _FlashcardContent(word: w, showRussian: false, unitId: widget.unitId),
                ),
                back: NokhchiinFlashcardFace(
                  accent: true,
                  child: _FlashcardContent(word: w, showRussian: true, unitId: widget.unitId, onAccent: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: NokhchiinButton(
                  label: 'Повторить',
                  color: context.iosTokens.accentMuted,
                  textColor: context.iosTokens.accent,
                  onPressed: () => _swipeController.swipeLeft(),
                  // Иконка вместо сырого юникод-символа "↻" (аудит §low).
                  child: _ButtonLabel(
                    iconAsset: AppIcons.actionReview,
                    label: 'Повторить',
                    color: context.iosTokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: NokhchiinButton(
                  label: 'Знаю',
                  onPressed: canMarkKnown
                      ? () => _swipeController.swipeRight()
                      : () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showFlipNudge = true);
                        },
                  // Иконка вместо сырого юникод-символа "✓" (аудит §low).
                  child: _ButtonLabel(
                    iconAsset: AppIcons.stateSuccess,
                    label: 'Знаю',
                    color: context.iosTokens.accentOn,
                  ),
                ),
              ),
            ],
          ),
          if (!widget.embedded && !isKids) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push('/typing/${widget.unitId}'),
              child: const Text('Режим ввода CE → RU'),
            ),
          ],
        ],
      ),
    );

    if (widget.embedded) return body;

    return AppScaffold(
      title: '${_index + 1} / ${_words.length}',
      body: body,
    );
  }
}

class _FlashcardContent extends StatelessWidget {
  const _FlashcardContent({
    required this.word,
    required this.showRussian,
    required this.unitId,
    this.onAccent = false,
  });

  final WordEntity word;
  final bool showRussian;
  final String unitId;
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final fg = onAccent ? Colors.white : tokens.textPrimary;
    final fgMuted = onAccent ? Colors.white.withValues(alpha: 0.7) : tokens.textTertiary;

    return Semantics(
      label: showRussian
          ? 'Карточка: ${word.russian}'
          : 'Карточка: ${word.chechen}',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (word.emoji != null)
                  Text(word.emoji!, style: const TextStyle(fontSize: 80))
                else
                  const AppIconImage(asset: AppIcons.navDictionary, size: 80),
                const SizedBox(height: 16),
                Text(
                  showRussian ? word.russian : word.chechen,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: showRussian ? 34 : 30,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: showRussian ? 0 : 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                if (word.pronunciation != null && word.pronunciation!.isNotEmpty)
                  Text('[${word.pronunciation}]', style: TextStyle(fontSize: 14, color: fgMuted, letterSpacing: 0.5)),
                if (word.hint != null && showRussian) ...[
                  const SizedBox(height: 12),
                  Text(
                    word.hint!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: fgMuted, height: 1.4),
                  ),
                ],
                if (!showRussian) ...[
                  const SizedBox(height: 16),
                  NokhchiinChip(
                    label: word.category ?? 'Слово',
                    color: tokens.textTertiary,
                    background: onAccent ? Colors.white.withValues(alpha: 0.15) : tokens.surfaceMuted,
                  ),
                ],
              ],
            ),
          ),
          if (!showRussian)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: onAccent ? Colors.white.withValues(alpha: 0.15) : tokens.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.touch_app_outlined, size: 12, color: fgMuted),
                  ),
                  const SizedBox(width: 6),
                  Text('Нажми, чтобы перевернуть', style: TextStyle(fontSize: 11, color: fgMuted)),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Иконка + текст с той же типографикой, что NokhchiinButton рисует для
/// обычного [label] — сохраняет визуальную согласованность при передаче
/// кастомного [child] ради иконки.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.iconAsset,
    required this.label,
    required this.color,
  });

  final String iconAsset;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = IosTypography.of(context, context.iosTokens);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconImage(asset: iconAsset, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
