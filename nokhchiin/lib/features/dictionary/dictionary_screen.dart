import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../domain/entities/word_entity.dart';

final _audioProvider = Provider((_) => AudioService());

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dict = ref.watch(dictionaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Словарь'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Поиск: чеченский или русский',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: dict.when(
        data: (words) {
          final filtered = _query.isEmpty
              ? words.take(100).toList()
              : words
                  .where((w) =>
                      w.chechen.toLowerCase().contains(_query.toLowerCase()) ||
                      w.russian.toLowerCase().contains(_query.toLowerCase()))
                  .take(80)
                  .toList();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${words.length} слов · Мациев + Алироев + учебник',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return _WordTile(
                word: filtered[i - 1],
                onSpeak: () => ref.read(_audioProvider).speakChechen(filtered[i - 1].chechen),
                onFavorite: () => ref.read(progressRepoProvider).toggleFavorite(filtered[i - 1].id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, required this.onSpeak, required this.onFavorite});
  final WordEntity word;
  final VoidCallback onSpeak;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final verified = word.tags.contains('verified') || word.sources.contains('curated');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(word.emoji ?? '📖', style: const TextStyle(fontSize: 28)),
        title: Text(word.chechen, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word.russian),
            if (verified)
              const Text('✓ проверено', style: TextStyle(color: Color(0xFF0D904F), fontSize: 11)),
          ],
        ),
        trailing: IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: onSpeak),
        onTap: onSpeak,
      ),
    );
  }
}
