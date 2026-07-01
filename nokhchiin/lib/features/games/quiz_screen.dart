import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/tokens/nokhchiin_colors.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/empty_state.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../domain/entities/word_entity.dart';

final _audio = Provider((_) => AudioService());
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
  List<WordEntity> _words = [];
  int _index = 0;
  int _score = 0;
  bool _loading = true;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.length < 4) {
      words = (await ref.read(dictionaryRepoProvider).getAllWords()).take(10).toList();
    }
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
      if (FeatureFlags.audioEnabled) _speak();
    }
  }

  void _speak() {
    if (!FeatureFlags.audioEnabled || _words.isEmpty) return;
    ref.read(_audio).speakChechen(_words[_index].chechen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      if (widget.embedded) return Center(child: LoadingState(message: l10n.loading));
      return AppScaffold(body: LoadingState(message: l10n.loading));
    }
    if (_words.length < 4) {
      if (widget.embedded) return EmptyState(emoji: '📭', title: l10n.notEnoughWords);
      return AppScaffold(body: EmptyState(emoji: '📭', title: l10n.notEnoughWords));
    }

    final questionLimit = widget.maxQuestions ?? _words.length;
    final totalQ = questionLimit.clamp(1, _words.length);

    final target = _words[_index];
    final others = [..._words]..removeAt(_index);
    others.shuffle(_rng);
    final options = [target, ...others.take(3)]..shuffle(_rng);

    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Вопрос ${_index + 1} / $totalQ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: _lastCorrect == null
                  ? Colors.transparent
                  : (_lastCorrect!
                      ? NokhchiinColors.successLight
                      : NokhchiinColors.errorLight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: WordExerciseCard(
              word: target,
              categoryId: widget.unitId,
            ).animate(key: ValueKey(target.id)).fadeIn(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.quizTapHint, style: Theme.of(context).textTheme.bodySmall),
          if (FeatureFlags.audioEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            IconButton(onPressed: _speak, icon: const Icon(Icons.volume_up_rounded, size: 32)),
          ],
          const Spacer(),
          ...options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppButton(
                  label: '${o.emoji ?? '📖'}  ${o.russian}',
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: () => _answer(o == target, target, totalQ),
                ),
              )),
          const Spacer(),
        ],
      ),
    );

    if (widget.embedded) return body;
    return AppScaffold(title: l10n.quizTitle(_score), body: body);
  }

  Future<void> _answer(bool correct, WordEntity target, int totalQ) async {
    setState(() => _lastCorrect = correct);
    if (correct) {
      HapticFeedback.lightImpact();
      _score++;
    } else {
      HapticFeedback.heavyImpact();
    }

    await ref.read(reviewWordUseCaseProvider)(target.id, correct ? 4 : 1);
    await Future.delayed(AppDurations.normal);
    if (!mounted) return;

    setState(() => _lastCorrect = null);

    if (_index < totalQ - 1) {
      setState(() => _index++);
      if (FeatureFlags.audioEnabled) _speak();
    } else if (widget.embedded) {
      widget.onComplete?.call();
    } else {
      await ref.read(userProfileProvider.notifier).addXp(50, 5);
      if (mounted) context.pop();
    }
  }
}
