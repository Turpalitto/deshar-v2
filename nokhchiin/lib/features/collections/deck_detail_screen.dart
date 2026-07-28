import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/entities/word_entity.dart';

class DeckDetailScreen extends ConsumerStatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  int _shuffleSeed = 0;

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider(widget.deckId));
    final words = ref.watch(deckWordsProvider(widget.deckId));
    return AppScaffold(
      title: deck.valueOrNull?.title ?? 'Колода',
      body: deck.when(
        data: (deck) {
          if (deck == null) {
            return const NokhchiinEmptyState(
              iconAsset: 'assets/icons/state_empty.svg',
              title: 'Колода не найдена',
            );
          }
          return words.when(
            data: (items) => _content(context, deck, items),
            loading: () => const NokhchiinLoadingState(),
            error: (_, _) => NokhchiinErrorState(
              message: 'Не удалось загрузить записи',
              onRetry: () => ref.invalidate(deckWordsProvider(widget.deckId)),
            ),
          );
        },
        loading: () => const NokhchiinLoadingState(),
        error: (_, _) => const NokhchiinEmptyState(
          iconAsset: 'assets/icons/state_empty.svg',
          title: 'Колода не найдена',
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    DeckEntity deck,
    List<WordEntity> source,
  ) {
    final words = [...source];
    if (_shuffleSeed > 0) words.shuffle(Random(_shuffleSeed));
    final editable = !deck.isSystem || deck.id == SystemDeckIds.dictionary;

    if (words.isEmpty) {
      return _emptyState(context, deck);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${words.length} записей',
                style: TextStyle(color: context.iosTokens.textSecondary),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _shuffleSeed++),
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: const Text('Перемешать'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DeckActions(deckId: deck.id),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'СЛОВА',
          style: TextStyle(
            color: context.iosTokens.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: context.iosTokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: context.iosTokens.separator),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < words.length; index++) ...[
                _WordRow(
                  word: words[index],
                  editable: editable,
                  onRemove: () => _remove(words[index].id),
                ),
                if (index < words.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    color: context.iosTokens.separator,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, DeckEntity deck) {
    final copy = switch (deck.id) {
      SystemDeckIds.favorites => (
        title: 'Пока ничего не отмечено',
        subtitle: 'Нажимайте на сердце у важных слов — они появятся здесь.',
        action: 'Открыть словарь',
        route: '/dictionary',
      ),
      SystemDeckIds.mistakes => (
        title: 'Ошибок пока нет',
        subtitle:
            'Продолжайте заниматься, а сложные слова соберутся здесь сами.',
        action: 'Перейти к обучению',
        route: '/path',
      ),
      SystemDeckIds.dictionary => (
        title: 'Ваша подборка пуста',
        subtitle:
            'Добавляйте нужные слова из словаря, чтобы учить их отдельно.',
        action: 'Открыть словарь',
        route: '/dictionary',
      ),
      SystemDeckIds.due => (
        title: 'Сегодня всё повторено',
        subtitle: 'Новые повторения появятся здесь по расписанию.',
        action: 'На экран «Сегодня»',
        route: '/',
      ),
      SystemDeckIds.newWords => (
        title: 'Все карточки уже в работе',
        subtitle: 'Продолжайте обучение и возвращайтесь к повторениям.',
        action: 'На экран «Сегодня»',
        route: '/',
      ),
      _ when !deck.isSystem => (
        title: 'Колода ждёт первые слова',
        subtitle: 'Откройте словарь и добавьте сюда нужные карточки.',
        action: 'Открыть словарь',
        route: '/dictionary',
      ),
      _ => (
        title: 'Здесь пока нет карточек',
        subtitle: 'Откройте словарь и выберите слова для изучения.',
        action: 'Открыть словарь',
        route: '/dictionary',
      ),
    };

    return NokhchiinEmptyState(
      iconAsset: 'assets/icons/state_empty.svg',
      title: copy.title,
      subtitle: copy.subtitle,
      actionLabel: copy.action,
      onAction: () => context.go(copy.route),
    );
  }

  Future<void> _remove(String wordId) async {
    await ref.read(deckRepoProvider).removeWord(wordId, widget.deckId);
    ref.invalidate(deckWordsProvider(widget.deckId));
    ref.invalidate(wordDeckMembershipProvider(wordId));
  }
}

class _DeckActions extends StatelessWidget {
  const _DeckActions({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    final encoded = Uri.encodeComponent(deckId);
    return Material(
      color: context.iosTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.iosTokens.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _Action(
              icon: Icons.school_outlined,
              label: 'Учить новые',
              onTap: () => context.push('/deck/$encoded/flashcards?filter=new'),
            ),
          ),
          Expanded(
            child: _Action(
              icon: Icons.replay_outlined,
              label: 'Повторить',
              onTap: () => context.push('/deck/$encoded/flashcards?filter=due'),
            ),
          ),
          Expanded(
            child: _Action(
              icon: Icons.quiz_outlined,
              label: 'Викторина',
              onTap: () => context.push('/deck/$encoded/quiz'),
            ),
          ),
          Expanded(
            child: _Action(
              icon: Icons.grid_view_outlined,
              label: 'Пары',
              onTap: () => context.push('/deck/$encoded/match'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: tokens.accent),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordRow extends ConsumerWidget {
  const _WordRow({
    required this.word,
    required this.editable,
    required this.onRemove,
  });

  final WordEntity word;
  final bool editable;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(wordProgressProvider(word.id)).valueOrNull;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 6),
      minVerticalPadding: 10,
      title: Text(word.chechen),
      subtitle: Text(
        '${word.russian} · ${progress?.mastery.labelRu ?? 'Не изучалось'}',
      ),
      onTap: () => context.push('/dictionary/${word.id}'),
      trailing: editable
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Удалить из колоды',
              onPressed: onRemove,
            )
          : Icon(
              Icons.chevron_right_rounded,
              color: context.iosTokens.textTertiary,
            ),
    );
  }
}
