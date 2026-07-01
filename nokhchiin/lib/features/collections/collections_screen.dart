import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/content_providers.dart';
import '../../core/widgets/word_illustration.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final content = ref.read(contentSourceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Коллекции')),
      body: collections.when(
        data: (list) => FutureBuilder(
          future: content.loadChests(),
          builder: (context, chestSnap) {
            final chests = chestSnap.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Row(
                  children: [
                    FoxMascot(size: 56),
                    SizedBox(width: 12),
                    Expanded(child: Text('Собирай карточки и открывай сундучки!')),
                  ],
                ),
                const SizedBox(height: 20),
                ...chests.map((c) => Card(
                      child: ListTile(
                        leading: const Text('🎁', style: TextStyle(fontSize: 32)),
                        title: Text(c['titleRu'] as String),
                        subtitle: Text('${c['starsRequired']} ⭐'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Открыть'),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                Text('Альбомы', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                ...list.map((col) {
                  final rarity = col['rarity'] as String? ?? 'common';
                  return Card(
                    child: ListTile(
                      leading: Text(col['icon'] as String? ?? '📘', style: const TextStyle(fontSize: 32)),
                      title: Text(col['titleRu'] as String),
                      subtitle: Text('${col['titleCe']} · ${col['totalCards']} карточек · $rarity'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  );
                }),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
