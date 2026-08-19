import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/analytics_service.dart';
import '../../core/widgets/chechen_audio_controls.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/word_entity.dart';

class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(conversationCategoriesProvider);
    return AppScaffold(
      title: 'Фразы и истории',
      body: categories.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('Короткие истории'),
              subtitle: const Text('Фразы в понятном контексте'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/stories'),
            ),
            const Divider(),
            ...items.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NokhchiinSurfaceCard(
                  onTap: category.enabled && category.entries.isNotEmpty
                      ? () => context.push('/phrases/${category.id}')
                      : null,
                  child: Row(
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              category.enabled
                                  ? '${category.entries.length} фраз из учебной подборки'
                                  : 'Материал проходит проверку',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        category.enabled
                            ? Icons.chevron_right_rounded
                            : Icons.schedule_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(conversationCategoriesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ),
      ),
    );
  }
}

class ConversationDetailScreen extends ConsumerWidget {
  const ConversationDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(conversationCategoriesProvider);
    return AppScaffold(
      title: categories.valueOrNull
          ?.where((item) => item.id == categoryId)
          .firstOrNull
          ?.title,
      body: categories.when(
        data: (items) {
          final category = items
              .where((item) => item.id == categoryId)
              .firstOrNull;
          if (category == null || !category.enabled) {
            return const Center(child: Text('Материал проходит проверку'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final word in category.entries) ...[
                NokhchiinSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.chechen,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.russian,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ChechenAudioControls(
                        audioId: word.audioId,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (category.entries.length >= 2)
                FilledButton.icon(
                  onPressed: () => context.push('/phrases/$categoryId/quiz'),
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Короткая викторина'),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Не удалось открыть фразы')),
      ),
    );
  }
}

class ConversationQuizScreen extends ConsumerStatefulWidget {
  const ConversationQuizScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<ConversationQuizScreen> createState() =>
      _ConversationQuizScreenState();
}

class _ConversationQuizScreenState
    extends ConsumerState<ConversationQuizScreen> {
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _busy = false;
  bool _completionTracked = false;

  Future<void> _answer(WordEntity current, String option) async {
    if (_busy || _selected != null) return;
    final correct = option == current.chechen;
    setState(() => _busy = true);
    try {
      await ref.read(reviewWordUseCaseProvider)(current.id, correct ? 4 : 1);
      try {
        await ref
            .read(analyticsServiceProvider)
            .track(
              AnalyticsEventName.answerSubmitted,
              properties: {
                'word_id': current.id,
                'correct': correct.toString(),
                'exercise': 'conversation',
              },
            );
      } catch (_) {
        // Analytics must not interrupt the exercise.
      }
      if (!mounted) return;
      setState(() {
        _selected = option;
        if (correct) _score++;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить ответ')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _trackCompletion(int total) {
    if (_completionTracked) return;
    _completionTracked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await ref
            .read(analyticsServiceProvider)
            .track(
              AnalyticsEventName.conversationCompleted,
              properties: {
                'category_id': widget.categoryId,
                'score': _score.toString(),
                'total': total.toString(),
              },
            );
      } catch (_) {
        // Analytics must not interrupt navigation.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(conversationCategoriesProvider);
    return AppScaffold(
      title: 'Викторина',
      body: categories.when(
        data: (items) {
          final category = items
              .where((item) => item.id == widget.categoryId)
              .firstOrNull;
          if (category == null || category.entries.length < 2) {
            return const Center(child: Text('Недостаточно фраз для викторины'));
          }
          final words = category.entries;
          final current = words[_index % words.length];
          final options = [...words.map((word) => word.chechen)]
            ..sort((a, b) => a.compareTo(b));
          final finished = _index >= words.length;
          if (finished) {
            _trackCompletion(words.length);
            return Center(
              child: FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Готово'),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: (_index + 1) / words.length),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Выберите подходящую фразу',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  current.russian,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: OutlinedButton(
                      onPressed: _selected == null && !_busy
                          ? () => _answer(current, option)
                          : null,
                      child: Text(option),
                    ),
                  ),
                if (_selected != null) ...[
                  Text(
                    _selected == current.chechen
                        ? 'Верно'
                        : 'Правильный ответ: ${current.chechen}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => setState(() {
                      _index++;
                      _selected = null;
                    }),
                    child: const Text('Дальше'),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Не удалось открыть викторину')),
      ),
    );
  }
}
