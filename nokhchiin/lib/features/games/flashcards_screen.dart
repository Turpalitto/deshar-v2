import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/design_system.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/word_entity.dart';
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

  List<WordEntity> _words = [];
  int _index = 0;
  bool _showTranslation = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.isEmpty) {
      words = (await ref.read(dictionaryRepoProvider).getAllWords()).take(10).toList();
    }
    words.shuffle(_rng);
    if (mounted) {
      setState(() {
        _words = words.take(8).toList();
        _loading = false;
      });
    }
  }

  Future<void> _known(bool yes) async {
    final w = _words[_index];
    await ref.read(reviewWordUseCaseProvider)(w.id, yes ? 5 : 2);
    if (yes) await ref.read(userProfileProvider.notifier).recordWordLearned();

    if (_index < _words.length - 1) {
      setState(() {
        _index++;
        _showTranslation = false;
      });
    } else {
      if (widget.embedded) {
        widget.onComplete?.call();
      } else {
        await ref.read(userProfileProvider.notifier).addXp(25, 5);
        if (mounted) _showReward();
      }
    }
  }

  void _showReward() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Урок пройден! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('+25 XP · +5 монет'),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Ввод по-чеченски',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/typing/${widget.unitId}');
              },
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Отлично',
            expanded: false,
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      if (widget.embedded) return const Center(child: LoadingState(message: 'Готовим карточки…'));
      return const AppScaffold(body: LoadingState(message: 'Готовим карточки…'));
    }
    if (_words.isEmpty) {
      if (widget.embedded) return const Center(child: Text('Нет слов для урока'));
      return const AppScaffold(body: Center(child: Text('Нет слов для урока')));
    }

    final w = _words[_index];
    final isKids = ref.watch(userProfileProvider).value?.mode == AppMode.kids;

    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          NokhchiinSegmentProgress(
            step: _index + 1,
            total: _words.length.clamp(1, 8),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Слова · ${_index + 1} / ${_words.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.iosTokens.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SpringSwipeCard(
              key: ValueKey(w.id),
              controller: _swipeController,
              onSwipeLeft: () {
                HapticFeedback.heavyImpact();
                _known(false);
              },
              onSwipeRight: () {
                HapticFeedback.lightImpact();
                _known(true);
              },
              child: NokhchiinFlipCard(
                flipped: _showTranslation,
                onTap: () => setState(() => _showTranslation = !_showTranslation),
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
                  label: '↻ Повторить',
                  color: context.iosTokens.accentMuted,
                  textColor: context.iosTokens.accent,
                  onPressed: () => _swipeController.swipeLeft(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: NokhchiinButton(
                  label: '✓ Знаю',
                  onPressed: () => _swipeController.swipeRight(),
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(word.emoji ?? '📖', style: const TextStyle(fontSize: 80)),
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
          if (!showRussian) ...[
            const SizedBox(height: 16),
            NokhchiinChip(
              label: word.category ?? 'Слово',
              color: tokens.textTertiary,
              background: onAccent ? Colors.white.withValues(alpha: 0.15) : tokens.surfaceMuted,
            ),
            const Spacer(),
            Row(
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
          ],
        ],
      ),
    );
  }
}
