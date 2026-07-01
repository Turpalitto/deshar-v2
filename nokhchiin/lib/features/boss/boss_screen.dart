import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/providers/content_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/design/widgets/app_button.dart';
import '../../domain/entities/word_entity.dart';

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
  Map<String, dynamic>? _boss;
  int _index = 0;
  int _score = 0;
  int _secondsLeft = 120;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = ref.read(contentSourceProvider);
    _boss = await content.loadBossForUnit(widget.unitId);
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.length < 5) {
      words = (await ref.read(dictionaryRepoProvider).getAllWords()).take(10).toList();
    }
    words.shuffle(_rng);
    if (!mounted) return;
    setState(() {
      _words = words.take(_boss?['questionsCount'] as int? ?? 10).toList();
      _secondsLeft = _boss?['timeLimitSec'] as int? ?? 120;
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

  Future<void> _unlockNextWorld() async {
    final worlds = await ref.read(worldsProvider.future);
    final idx = worlds.indexWhere((w) => (w['units'] as List).contains(widget.unitId));
    if (idx >= 0 && idx < worlds.length - 1) {
      final nextId = worlds[idx + 1]['id'] as String;
      await ref.read(userProfileProvider.notifier).unlockWorld(nextId);
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    final pass = _boss?['passScore'] as int? ?? 8;
    final won = _score >= pass;
    if (won) {
      ref.read(userProfileProvider.notifier).addXp(
            _boss?['rewardXp'] as int? ?? 100,
            _boss?['rewardStars'] as int? ?? 25,
          );
      _unlockNextWorld();
      ref.read(userProfileProvider.notifier).unlockAchievement('collector');
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(won ? 'Победа! 🏆' : 'Попробуй ещё'),
        content: Text(
          won
              ? 'Счёт: $_score / ${_words.length}\nНовый мир открыт!'
              : 'Счёт: $_score / ${_words.length}',
        ),
        actions: [
          AppButton(
            label: 'OK',
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
    if (_words.isEmpty || _boss == null) {
      return const AppScaffold(body: LoadingState(message: 'Босс готовится…'));
    }
    if (_index >= _words.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const AppScaffold(body: LoadingState());
    }

    final target = _words[_index];
    final others = [..._words]..removeAt(_index);
    others.shuffle(_rng);
    final options = [target, ...others.take(3)]..shuffle(_rng);

    return AppScaffold(
      title: 'Босс: ${_boss!['titleRu']}',
      actions: [Padding(padding: const EdgeInsets.all(16), child: Text('⏱ $_secondsLeft'))],
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
            ...options.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppButton(
                    label: o.russian,
                    variant: AppButtonVariant.secondary,
                    expanded: true,
                    onPressed: () async {
                      if (o.id == target.id) {
                        _score++;
                        await ref.read(reviewWordUseCaseProvider)(target.id, 5);
                      } else {
                        await ref.read(reviewWordUseCaseProvider)(target.id, 1);
                      }
                      setState(() => _index++);
                    },
                  ),
                )),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
