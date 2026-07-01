import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';

final _audio = Provider((_) => AudioService());

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(dueWordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Повторение')),
      body: due.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('Нет слов для повторения 🎉'));
          }
          final w = words[_index % words.length];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Интервальное повторение', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(w.chechen, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
                if (_showAnswer) ...[
                  const SizedBox(height: 16),
                  Text(w.russian, style: Theme.of(context).textTheme.headlineMedium),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref.read(reviewWordUseCaseProvider)(w.id, 1);
                          _next(words.length);
                        },
                        child: const Text('Не помню'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_showAnswer) {
                            setState(() => _showAnswer = true);
                            ref.read(_audio).speakChechen(w.chechen);
                          } else {
                            await ref.read(reviewWordUseCaseProvider)(w.id, 4);
                            _next(words.length);
                          }
                        },
                        child: Text(_showAnswer ? 'Помню ✓' : 'Показать'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _next(int total) {
    setState(() {
      _showAnswer = false;
      _index = (_index + 1) % total;
    });
  }
}
