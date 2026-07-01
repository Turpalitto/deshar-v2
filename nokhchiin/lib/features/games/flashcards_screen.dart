import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/widgets/word_illustration.dart';
import '../../domain/entities/word_entity.dart';

final _audio = Provider((_) => AudioService());
final _rng = Random();

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  List<WordEntity> _words = [];
  int _index = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.isEmpty) {
      final all = await ref.read(dictionaryRepoProvider).getAllWords();
      setState(() => _words = all.take(10).toList());
    } else {
      setState(() => _words = words);
    }
    _speak();
  }

  void _speak() {
    if (_words.isEmpty) return;
    ref.read(_audio).speakChechen(_words[_index].chechen);
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = _words[_index];
    return Scaffold(
      appBar: AppBar(title: Text('Карточки ${_index + 1}/${_words.length}')),
      body: GestureDetector(
        onTap: () => setState(() => _flipped = !_flipped),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _flipped
                ? _CardFace(
                    key: const ValueKey('back'),
                    category: widget.unitId,
                    emoji: w.emoji ?? '📖',
                    main: w.russian,
                    sub: w.hint ?? '',
                    color: const Color(0xFF0D904F),
                  )
                : _CardFace(
                    key: const ValueKey('front'),
                    category: widget.unitId,
                    emoji: w.emoji ?? '📖',
                    main: w.chechen,
                    sub: w.pronunciation ?? '',
                    color: const Color(0xFF1A73E8),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            IconButton(
              onPressed: _index > 0
                  ? () => setState(() {
                        _index--;
                        _flipped = false;
                        _speak();
                      })
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _speak,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Слушать'),
              ),
            ),
            IconButton(
              onPressed: () async {
                if (_index < _words.length - 1) {
                  await ref.read(reviewWordUseCaseProvider)(w.id, 4);
                  setState(() {
                    _index++;
                    _flipped = false;
                  });
                  _speak();
                } else {
                  await ref.read(reviewWordUseCaseProvider)(w.id, 5);
                  await ref.read(userProfileProvider.notifier).addXp(30, 3);
                  if (context.mounted) context.pop();
                }
              },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    this.category,
    required this.emoji,
    required this.main,
    required this.sub,
    required this.color,
  });
  final String? category;
  final String emoji, main, sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 420,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WordIllustration(category: category, emoji: emoji, size: 120),
          const SizedBox(height: 24),
          Text(main, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(sub, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
