import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/word_illustration.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index = 0;
  bool _showAnswer = false;
  bool _finished = false;
  int _correct = 0;

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(dueWordsProvider);

    if (_finished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text('Отлично!', style: Theme.of(context).textTheme.headlineMedium),
              Text('Правильно: $_correct'),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.pop(), child: const Text('Готово')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Повторение')),
      body: due.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('Всё повторено 🎉'));
          }

          if (_index >= words.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(userProfileProvider.notifier).addXp(_correct * 5, _correct);
              setState(() => _finished = true);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final w = words[_index];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Text('Сегодня: ${words.length} слов', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Text('${_index + 1} / ${words.length}', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                const Spacer(),
                WordIllustration(category: w.category, emoji: w.emoji, size: 140),
                const SizedBox(height: 20),
                Text(w.chechen, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
                if (_showAnswer) ...[
                  const SizedBox(height: 12),
                  Text(w.russian, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xFF0D904F))),
                ],
                const Spacer(),
                if (!_showAnswer)
                  FilledButton(
                    onPressed: () => setState(() => _showAnswer = true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      child: Text('Показать'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref.read(reviewWordUseCaseProvider)(w.id, 1);
                            setState(() {
                              _showAnswer = false;
                              _index++;
                            });
                          },
                          child: const Text('Не помню'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await ref.read(reviewWordUseCaseProvider)(w.id, 5);
                            _correct++;
                            setState(() {
                              _showAnswer = false;
                              _index++;
                            });
                          },
                          child: const Text('Помню ✓'),
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
}
