import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/word_exercise_card.dart';
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
              child: AppCard(
                child: GestureDetector(
                  onTap: () => setState(() => _showTranslation = !_showTranslation),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        WordExerciseCard(
                          word: w,
                          categoryId: widget.unitId,
                          showRussian: _showTranslation,
                        ),
                        if (!_showTranslation)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              'Нажми — перевод · свайп влево/вправо',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Ещё учу',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _swipeController.swipeLeft(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Знаю ✓',
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
