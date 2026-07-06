import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/providers/providers.dart';

import '../../core/services/audio_service.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/entities/content_entities.dart';

final _audioProvider = Provider((_) => AudioService());
final _rng = Random();

class BossScreen extends ConsumerStatefulWidget {
  const BossScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<BossScreen> createState() => _BossScreenState();
}

class _BossScreenState extends ConsumerState<BossScreen> {
  List<WordEntity> _words = [];
  BossEntity? _boss;
  bool _loading = true;
  int _index = 0;
  int _score = 0;
  int _secondsLeft = 120;
  Timer? _timer;
  bool _finished = false;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = ref.read(contentSourceProvider);
    final boss = await content.loadBossForUnit(widget.unitId);
    if (boss == null) {
      // Нет контента босса для этого юнита — не вешаем экран навсегда
      // (аудит logic §6: раньше тут был бесконечный LoadingState без
      // кнопки назад), а честно показываем, что тут ловить нечего.
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    _boss = boss;
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.length < 5) {
      // Раньше .take(10) без shuffle пула — всегда один и тот же набор
      // первых 10 слов словаря (аудит §7). Копируем перед shuffle —
      // репозиторий отдаёт общий закэшированный список. Curated вместо
      // полного словаря: там проверенные слова и нет парсинга 23 МБ.
      final all = [...await ref.read(dictionaryRepoProvider).getCuratedWords()]..shuffle(_rng);
      words = all.take(10).toList();
    }
    words.shuffle(_rng);
    if (!mounted) return;
    setState(() {
      _words = words.take(boss.questionsCount).toList();
      _secondsLeft = boss.timeLimitSec;
      _loading = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _finish();
      } else if (mounted) setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Возвращает true, только если реально разблокирован новый мир —
  /// вызывающий код честно показывает "Новый мир открыт!" только тогда.
  Future<bool> _unlockNextWorld() async {
    final worlds = await ref.read(worldsProvider.future);
    if (!mounted) return false; // аудит §2: экран может быть закрыт до завершения await
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
      // Ждём запись награды перед диалогом — раньше это было "выстрелил и
      // забыл" (аудит §2). Плюс единый фирменный RewardCelebration вместо
      // голого AlertDialog (аудит §2/§3) — и честная подпись: раньше
      // "Новый мир открыт!" показывалось всегда, даже когда открывать
      // было нечего (последний юнит в последнем мире).
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
      return const AppScaffold(body: LoadingState(message: 'Босс готовится…'));
    }
    if (_index >= _words.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const AppScaffold(body: LoadingState());
    }

    final target = _words[_index];
    final others = [..._words]..removeAt(_index);
    others.shuffle(_rng);
    // Дедупликация по переводу — см. quiz_screen.dart, тот же баг
    // (аудит §7): без неё узкая категория даёт неотвечаемый вопрос.
    final seen = <String>{target.russian.trim().toLowerCase()};
    final distractors = <WordEntity>[];
    for (final o in others) {
      final key = o.russian.trim().toLowerCase();
      if (seen.add(key)) distractors.add(o);
      if (distractors.length == 3) break;
    }
    final options = [target, ...distractors]..shuffle(_rng);

    return AppScaffold(
      title: 'Босс: ${_boss!.titleRu}',
      actions: [
        Padding(
          padding: const EdgeInsets.all(16),
          // Иконка вместо сырого эмодзи "⏱" в проде (аудит §low).
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
            Text('★ $_score', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            WordExerciseCard(word: target, categoryId: widget.unitId)
                .animate(key: ValueKey(target.id))
                .fadeIn(),
            if (FeatureFlags.audioEnabled)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 36),
                onPressed: () => ref.read(_audioProvider).speakChechen(target.chechen),
              ),
            const Spacer(),
            ...options.asMap().entries.map((entry) {
              final i = entry.key;
              final o = entry.value;
              final isCorrectAnswer = o.id == target.id;
              final answered = _selectedOption == i;
              // Раньше и верный, и неверный выбор красились в один и тот же
              // variant.primary (btnColor считался, но никуда не применялся)
              // — реальной разницы между "верно"/"неверно" не было вовсе.
              // Плюс иконка, а не только цвет — WCAG 1.4.1 (аудит §medium).
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppButton(
                  label: o.russian,
                  icon: answered
                      ? (isCorrectAnswer ? Icons.check_circle_rounded : Icons.cancel_rounded)
                      : null,
                  variant: answered && isCorrectAnswer
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: _selectedOption != null
                      ? null
                      : () async {
                          final correct = o.id == target.id;
                          setState(() {
                            _selectedOption = i;
                          });
                          if (correct) {
                            _score++;
                            await ref.read(reviewWordUseCaseProvider)(target.id, 5);
                          } else {
                            await ref.read(reviewWordUseCaseProvider)(target.id, 1);
                          }
                          await Future.delayed(AppDurations.normal);
                          if (!mounted) return;
                          setState(() {
                            _selectedOption = null;
                            _index++;
                          });
                        },
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
