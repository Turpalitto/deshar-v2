import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../domain/entities/word_entity.dart';

final _audio = Provider((_) => AudioService());
final _rng = Random();

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<WordEntity> _words = [];
  int _index = 0;
  int _score = 0;

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
    setState(() => _words = words);
    _speak();
  }

  void _speak() {
    if (_words.isNotEmpty) ref.read(_audio).speakChechen(_words[_index].chechen);
  }

  @override
  Widget build(BuildContext context) {
    if (_words.length < 4) {
      return const Scaffold(body: Center(child: Text('Недостаточно слов')));
    }
    final target = _words[_index];
    final others = [..._words]..removeAt(_index);
    others.shuffle(_rng);
    final options = [target, ...others.take(3)]..shuffle(_rng);

    return Scaffold(
      appBar: AppBar(title: Text('Викторина · ★ $_score')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(target.chechen, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            IconButton(onPressed: _speak, icon: const Icon(Icons.volume_up_rounded, size: 36)),
            const Spacer(),
            ...options.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C1C1E),
                        side: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      onPressed: () => _answer(o == target, target),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(o.emoji ?? '📖', style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(o.russian, style: const TextStyle(fontWeight: FontWeight.w700))),
                          ],
                        ),
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

  Future<void> _answer(bool correct, WordEntity target) async {
    await ref.read(reviewWordUseCaseProvider)(target.id, correct ? 4 : 1);
    if (correct) _score++;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_index < _words.length - 1) {
      setState(() => _index++);
      _speak();
    } else {
      await ref.read(userProfileProvider.notifier).addXp(50, 5);
      if (mounted) context.pop();
    }
  }
}
