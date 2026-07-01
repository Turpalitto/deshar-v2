import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/providers/content_providers.dart';
import '../../core/widgets/word_illustration.dart';
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
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(won ? 'Победа! 🏆' : 'Попробуй ещё'),
        content: Text('Счёт: $_score / ${_words.length}'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); context.pop(); }, child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty || _boss == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_index >= _words.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const Scaffold(body: Center(child: Text('Завершение...')));
    }

    final target = _words[_index];
    final others = [..._words]..removeAt(_index);
    others.shuffle(_rng);
    final options = [target, ...others.take(3)]..shuffle(_rng);

    return Scaffold(
      appBar: AppBar(
        title: Text('Босс: ${_boss!['titleRu']}'),
        actions: [Padding(padding: const EdgeInsets.all(16), child: Text('⏱ $_secondsLeft'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const FoxMascot(size: 64, emotion: FoxEmotion.thinking),
            Text('★ $_score', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            WordIllustration(category: widget.unitId, emoji: target.emoji, size: 140),
            const SizedBox(height: 16),
            Text(target.chechen, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 36),
              onPressed: () => ref.read(_audioProvider).speakChechen(target.chechen),
            ),
            const Spacer(),
            ...options.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      onPressed: () async {
                        if (o.id == target.id) {
                          _score++;
                          await ref.read(reviewWordUseCaseProvider)(target.id, 5);
                        } else {
                          await ref.read(reviewWordUseCaseProvider)(target.id, 1);
                        }
                        setState(() => _index++);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(o.russian, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                )),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
