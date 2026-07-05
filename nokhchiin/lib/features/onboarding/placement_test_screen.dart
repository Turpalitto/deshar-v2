import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/word_entity.dart';

final _rng = Random();

/// Стартовые юниты (requiredMastery: 0 в learning_path.json) — те самые,
/// с которых сейчас начинают все взрослые независимо от реального уровня.
const _starterUnitIds = ['greetings', 'colors', 'numbers', 'body', 'animals'];

/// Сколько правильных ответов из вопросов юнита достаточно, чтобы
/// засчитать его пройденным — мягкий порог (не оба из двух), т.к. аудитория
/// часто знает язык частично, а не идеально.
const _passThreshold = 1;

class _Question {
  const _Question({required this.unitId, required this.target, required this.options});
  final String unitId;
  final WordEntity target;
  final List<WordEntity> options;
}

/// Короткий placement-тест при онбординге взрослых: 2 вопроса на каждый
/// стартовый юнит. Пройденные юниты сразу засчитываются освоенными —
/// пользователь не должен заново учить то, что уже знает.
class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  List<_Question> _questions = [];
  final Map<String, int> _correctByUnit = {};
  int _index = 0;
  bool _loading = true;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dictionaryRepo = ref.read(dictionaryRepoProvider);
    final allWords = await dictionaryRepo.getAllWords();
    final questions = <_Question>[];

    for (final unitId in _starterUnitIds) {
      var words = await dictionaryRepo.getWordsByCategory(unitId);
      if (words.isEmpty) continue;
      _correctByUnit[unitId] = 0;

      final shuffled = [...words]..shuffle(_rng);
      final targets = shuffled.take(2).toList();

      for (final target in targets) {
        final pool = [...words]..removeWhere((w) => w.id == target.id);
        pool.shuffle(_rng);
        var distractors = pool.take(3).toList();
        if (distractors.length < 3) {
          // Категория слишком маленькая — добираем дистракторы из всего словаря.
          final usedIds = {target.id, ...distractors.map((w) => w.id)};
          final extra = allWords.where((w) => !usedIds.contains(w.id)).toList()..shuffle(_rng);
          distractors = [...distractors, ...extra.take(3 - distractors.length)];
        }
        final options = [target, ...distractors]..shuffle(_rng);
        questions.add(_Question(unitId: unitId, target: target, options: options));
      }
    }

    if (!mounted) return;
    setState(() {
      _questions = questions;
      _loading = false;
    });
  }

  Future<void> _finish() async {
    for (final entry in _correctByUnit.entries) {
      if (entry.value >= _passThreshold) {
        await ref.read(seedUnitMasteryUseCaseProvider)(entry.key);
      }
    }
    await _completeAndLeave();
  }

  Future<void> _completeAndLeave() async {
    await ref.read(userProfileProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  Future<void> _answer(_Question q, WordEntity option, int optionIndex) async {
    if (_selectedOption != null) return;
    final correct = option.id == q.target.id;
    setState(() {
      _selectedOption = optionIndex;
    });
    if (correct) {
      _correctByUnit[q.unitId] = (_correctByUnit[q.unitId] ?? 0) + 1;
    }

    await Future.delayed(AppDurations.normal);
    if (!mounted) return;

    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selectedOption = null;
      });
    } else {
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    if (_loading) {
      return AppScaffold(body: const LoadingState());
    }
    if (_questions.isEmpty) {
      // Словарь ещё не наполнен ни для одного стартового юнита — не блокируем
      // онбординг, просто идём дальше без сидинга.
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeAndLeave());
      return AppScaffold(body: const LoadingState());
    }

    final q = _questions[_index];

    return AppScaffold(
      title: 'Проверим, что ты уже знаешь',
      actions: [
        TextButton(
          onPressed: _completeAndLeave,
          child: const Text('Пропустить'),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              'Вопрос ${_index + 1} из ${_questions.length}',
              style: TextStyle(color: tokens.textTertiary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              q.target.chechen,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Как это переводится?',
              style: TextStyle(color: tokens.textSecondary),
            ),
            const Spacer(),
            ...q.options.asMap().entries.map((entry) {
              final i = entry.key;
              final o = entry.value;
              final isTarget = o.id == q.target.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: NokhchiinQuizOption(
                  label: o.emoji != null ? '${o.emoji}  ${o.russian}' : o.russian,
                  letter: String.fromCharCode(65 + i),
                  selected: _selectedOption == i ? true : null,
                  correct: _selectedOption == i ? isTarget : null,
                  enabled: _selectedOption == null,
                  onTap: () => _answer(q, o, i),
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
