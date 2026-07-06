import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/tokens/app_durations.dart'; // intentional-mix: motion tokens; Figma widgets from design_system
import '../../core/design/tokens/app_spacing.dart'; // intentional-mix: spacing tokens
import '../../core/design_system/design_system.dart';
import '../../core/design/widgets/app_scaffold.dart'; // intentional-mix: app shell scaffold
import '../../core/design/widgets/empty_state.dart'; // intentional-mix: empty list fallback
import '../../core/design/widgets/loading_state.dart'; // intentional-mix: shared loading placeholder
import '../../core/design/widgets/word_exercise_card.dart'; // intentional-mix: exercise card layout
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../domain/entities/word_entity.dart';
import 'widgets/exercise_presentation.dart';

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
  List<WordEntity> _options = [];
  int _index = 0;
  int _score = 0;
  bool _loading = true;
  bool? _lastCorrect;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.length < 4) {
      // Раньше .take(10) без shuffle — всегда одни и те же (зачастую худшие
      // по качеству) записи при каждом фолбэке (аудит §7). Копируем перед
      // shuffle — репозиторий отдаёт общий закэшированный список. Curated
      // вместо getAllWords(): фолбэк из полного словаря подсовывал сырые
      // записи датасета и парсил 23 МБ JSON в главном потоке (web).
      final all = [...await ref.read(dictionaryRepoProvider).getCuratedWords()]..shuffle(_rng);
      words = all.take(10).toList();
    }
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
      _buildOptions();
      if (FeatureFlags.audioEnabled) _speak();
    }
  }

  void _buildOptions() {
    if (_words.length < 4) return;
    final target = _words[_index];
    final others = [..._words]..removeAt(_index);
    others.shuffle(_rng);
    // Дедупликация по переводу — иначе при узкой/некачественной категории
    // (напр. "Глаголы", где почти все слова переводятся как "бежать")
    // на экране оказываются 3-4 одинаковые надписи, и вопрос физически
    // неотвечаем (аудит §7).
    final seen = <String>{target.russian.trim().toLowerCase()};
    final distractors = <WordEntity>[];
    for (final o in others) {
      final key = o.russian.trim().toLowerCase();
      if (seen.add(key)) distractors.add(o);
      if (distractors.length == 3) break;
    }
    _options = [target, ...distractors]..shuffle(_rng);
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
      if (widget.embedded) return EmptyState(iconAsset: AppIcons.stateEmpty, title: l10n.notEnoughWords);
      return AppScaffold(body: EmptyState(iconAsset: AppIcons.stateEmpty, title: l10n.notEnoughWords));
    }

    final questionLimit = widget.maxQuestions ?? _words.length;
    final totalQ = questionLimit.clamp(1, _words.length);

    final target = _words[_index];
    final options = _options;

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
            'ВОПРОС',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: context.iosTokens.textTertiary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quizTapHint,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (FeatureFlags.audioEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            IconButton(onPressed: _speak, icon: const Icon(Icons.volume_up_rounded, size: 32)),
          ],
          const Spacer(),
          ...options.asMap().entries.map((entry) {
            final i = entry.key;
            final o = entry.value;
            final isTarget = o == target;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: NokhchiinQuizOption(
                label: o.emoji != null ? '${o.emoji}  ${o.russian}' : o.russian,
                letter: String.fromCharCode(65 + i),
                selected: _selectedOption == i ? true : null,
                correct: _selectedOption == i ? isTarget : null,
                enabled: _selectedOption == null,
                onTap: () => _answer(isTarget, target, totalQ, i),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );

    if (widget.embedded) return body;
    return AppScaffold(title: l10n.quizTitle(_score), body: body);
  }

  Future<void> _answer(bool correct, WordEntity target, int totalQ, int optionIndex) async {
    setState(() {
      _lastCorrect = correct;
      _selectedOption = optionIndex;
    });
    if (correct) _score++;

    await ref.read(reviewWordUseCaseProvider)(target.id, correct ? 4 : 1);
    await Future.delayed(AppDurations.normal);
    if (!mounted) return;

    setState(() {
      _lastCorrect = null;
      _selectedOption = null;
    });

    if (_index < totalQ - 1) {
      setState(() => _index++);
      _buildOptions();
      if (FeatureFlags.audioEnabled) _speak();
    } else if (widget.embedded) {
      widget.onComplete?.call();
    } else {
      await ref.read(userProfileProvider.notifier).addXp(50, 5);
      if (mounted) context.pop();
    }
  }
}
