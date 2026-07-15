import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/exercise_word_pool.dart';
import '../../core/utils/gameplay_difficulty.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/word_entity.dart';
import 'widgets/exercise_presentation.dart';
import 'widgets/game_session_widgets.dart';

final _rng = Random();

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({
    super.key,
    required this.unitId,
    this.embedded = false,
    this.onComplete,
  });
  final String unitId;
  final bool embedded;
  final VoidCallback? onComplete;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  final _combo = GameComboTracker();
  List<WordEntity> _words = [];
  List<WordEntity> _shuffledRu = [];
  String? _selCe;
  String? _selRu;
  final _matched = <String>{};
  bool _loading = true;
  bool? _lastMatchCorrect;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = ref.read(userProfileProvider).value;
    final pairCount = GameplayDifficulty.matchPairCount(
      mode: profile?.mode ?? AppMode.kids,
      age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
    );
    final words = await ExerciseWordPool.loadForUnit(
      ref.read(dictionaryRepoProvider),
      widget.unitId,
      minCount: pairCount,
      take: pairCount,
      rng: _rng,
    );
    if (mounted) {
      final ru = [...words]..shuffle(_rng);
      setState(() {
        _words = words;
        _shuffledRu = ru;
        _loading = false;
      });
    }
  }

  void _tapCe(String id) {
    if (_matched.contains(id)) return;
    setState(() => _selCe = id);
    _tryAutoCheck();
  }

  void _tapRu(String id) {
    if (_matched.contains(id)) return;
    setState(() => _selRu = id);
    _tryAutoCheck();
  }

  void _tryAutoCheck() {
    if (_selCe != null && _selRu != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
    }
  }

  Future<void> _check() async {
    if (_selCe == null || _selRu == null) return;
    final isMatch = _selCe == _selRu;
    setState(() => _lastMatchCorrect = isMatch);

    if (isMatch) {
      _matched.add(_selCe!);
      _combo.recordCorrect();
      await ref.read(reviewWordUseCaseProvider)(_selCe!, 4);
      unawaited(HapticFeedback.lightImpact());
    } else {
      _combo.reset();
      await ref.read(reviewWordUseCaseProvider)(_selCe!, 1);
      unawaited(HapticFeedback.heavyImpact());
    }

    await Future.delayed(isMatch ? AppDurations.fast : AppDurations.normal);
    if (!mounted) return;

    setState(() {
      _lastMatchCorrect = null;
      _selCe = null;
      _selRu = null;
    });

    if (_matched.length == _words.length && mounted) {
      if (widget.embedded) {
        widget.onComplete?.call();
      } else {
        await ref.read(userProfileProvider.notifier).addXp(60, 6);
        if (!mounted) return;
        await RewardCelebration.show(
          context,
          iconAsset: AppIcons.rewardCelebration,
          title: 'Все пары собраны!',
          subtitle: 'Комбо ×${_combo.streak} · +60 XP',
          onDismiss: () {
            Navigator.of(context).pop();
            context.pop();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.embedded
          ? const Center(child: NokhchiinLoadingState())
          : const AppScaffold(body: NokhchiinLoadingState());
    }
    if (_words.isEmpty) {
      final empty = NokhchiinEmptyState(
        iconAsset: AppIcons.stateEmpty,
        title: 'Недостаточно слов',
      );
      return widget.embedded ? empty : AppScaffold(body: empty);
    }

    final tokens = context.iosTokens;
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          ExerciseProgressHeader(
            step: _matched.length + 1,
            total: _words.length,
            combo: _combo.streak,
            label: 'Собери пары · ${_matched.length}/${_words.length}',
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AnswerFeedbackAnimator(
              feedback: _lastMatchCorrect,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      children: _words
                          .map(
                            (w) => _MatchTile(
                              label: w.chechen,
                              emoji: w.emoji,
                              selected: _selCe == w.id,
                              matched: _matched.contains(w.id),
                              accent: tokens.accent,
                              onTap: () => _tapCe(w.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ListView(
                      children: _shuffledRu
                          .map(
                            (w) => _MatchTile(
                              label: w.russian,
                              selected: _selRu == w.id,
                              matched: _matched.contains(w.id),
                              accent: tokens.accent,
                              onTap: () => _tapRu(w.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return AppScaffold(title: 'Пары', body: body);
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
    required this.accent,
    this.emoji,
  });

  final String label;
  final String? emoji;
  final bool selected;
  final bool matched;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedOpacity(
        opacity: matched ? 0.45 : 1,
        duration: AppDurations.fast,
        child: NokhchiinSurfaceCard(
          onTap: matched ? null : onTap,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: accent, width: 2) : null,
            ),
            child: Row(
              children: [
                if (emoji != null)
                  Text(emoji!, style: const TextStyle(fontSize: 20)),
                if (emoji != null) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: matched ? tokens.textTertiary : tokens.textPrimary,
                      decoration: matched ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
