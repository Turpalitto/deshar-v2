import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/widgets/word_illustration.dart';

class StoriesListScreen extends ConsumerWidget {
  const StoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Истории и комиксы')),
      body: stories.when(
        data: (list) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Row(
              children: [
                FoxMascot(size: 56),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Читай комиксы с Цхьогалом и учи слова в контексте!'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...list.map((s) {
              final panels = (s['panels'] as List?)?.length ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/story/${s['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        WordIllustration(
                          category: s['unitId'] as String?,
                          emoji: s['emoji'] as String?,
                          size: 72,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['titleCe'] as String, style: Theme.of(context).textTheme.labelLarge),
                              Text(s['titleRu'] as String, style: Theme.of(context).textTheme.titleLarge),
                              Text('$panels панелей · квиз в конце', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.auto_stories_rounded),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
