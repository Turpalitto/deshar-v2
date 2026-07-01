import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/word_entity.dart';

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unitId});
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(learningUnitsProvider);
    return units.when(
      data: (list) {
        final unit = list.firstWhere((u) => u.id == unitId);
        return Scaffold(
          appBar: AppBar(title: Text(unit.titleRu)),
          body: FutureBuilder<List<WordEntity>>(
            future: ref.read(dictionaryRepoProvider).getWordsByCategory(unitId),
            builder: (context, snap) {
              final words = snap.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(unit.titleCe, style: Theme.of(context).textTheme.displayLarge),
                  Text('${words.length} слов · ${unit.masteryPercent}% освоено',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  _GameButton(
                    emoji: '🎴',
                    title: 'Карточки',
                    subtitle: 'Слушай и запоминай',
                    onTap: () => context.push('/flashcards/$unitId'),
                  ),
                  _GameButton(
                    emoji: '❓',
                    title: 'Угадай перевод',
                    subtitle: 'Выбери правильный ответ',
                    onTap: () => context.push('/quiz/$unitId'),
                  ),
                  _GameButton(
                    emoji: '🧩',
                    title: 'Найди пару',
                    subtitle: 'Соедини слова',
                    onTap: () => context.push('/match/$unitId'),
                  ),
                  _GameButton(
                    emoji: '👹',
                    title: 'Босс-уровень',
                    subtitle: 'Проверка на время',
                    onTap: () => context.push('/boss/$unitId'),
                  ),
                  const SizedBox(height: 24),
                  Text('Слова темы', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  ...words.map((w) => ListTile(
                        leading: Text(w.emoji ?? '📖', style: const TextStyle(fontSize: 28)),
                        title: Text(w.chechen, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(w.russian),
                      )),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String emoji, title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 32)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF1A73E8)),
          onTap: onTap,
        ),
      ),
    );
  }
}
