import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/deck_entity.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  static const _learningDeckIds = {
    SystemDeckIds.core,
    SystemDeckIds.phrases,
    SystemDeckIds.rare,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider);
    return AppScaffold(
      showOrnament: false,
      maxContentWidth: 1080,
      body: decks.when(
        data: (items) {
          final learning = [
            for (final deck in items)
              if (_learningDeckIds.contains(deck.id)) deck,
          ];
          final personal = [
            for (final deck in items)
              if (!_learningDeckIds.contains(deck.id)) deck,
          ];
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CollectionsHeader(
                    onCreate: () => _createDeck(context, ref),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(child: _LearningSummary()),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Учебные наборы'),
                ),
              ),
              _DeckGrid(decks: learning),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Мои подборки'),
                ),
              ),
              _DeckGrid(decks: personal),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
        loading: () => const NokhchiinLoadingState(),
        error: (_, _) => NokhchiinErrorState(
          message: 'Не удалось загрузить колоды',
          onRetry: () => ref.invalidate(decksProvider),
        ),
      ),
    );
  }

  Future<void> _createDeck(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая колода'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Название'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    await ref.read(deckRepoProvider).createDeck(title);
    ref.invalidate(decksProvider);
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Карточки',
                style: TextStyle(
                  color: context.iosTokens.textPrimary,
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Учите слова в своём темпе',
                style: TextStyle(
                  color: context.iosTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.create_new_folder_outlined),
          tooltip: 'Создать колоду',
          style: IconButton.styleFrom(
            backgroundColor: DesignTokens.skyMuted,
            foregroundColor: DesignTokens.sky,
            minimumSize: const Size.square(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onCreate,
        ),
      ],
    );
  }
}

class _LearningSummary extends ConsumerWidget {
  const _LearningSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.iosTokens;
    final newCount = ref
        .watch(deckWordsProvider(SystemDeckIds.newWords))
        .valueOrNull
        ?.length;
    final dueCount = ref
        .watch(deckWordsProvider(SystemDeckIds.due))
        .valueOrNull
        ?.length;
    final sessionSize = newCount?.clamp(0, 10);
    final primaryText = newCount == null
        ? 'Готовим занятие'
        : newCount == 0
        ? 'Все карточки уже в работе'
        : 'Короткая сессия';
    final secondaryText = dueCount == null
        ? 'Проверяем расписание повторений'
        : '${sessionSize ?? 0} новых · $dueCount на повторение';

    return Material(
      color: tokens.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: tokens.isDark ? 0 : 2,
      shadowColor: tokens.accent.withValues(alpha: 0.18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    secondaryText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: 'Начать короткую сессию',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.goldMuted,
                  foregroundColor: const Color(0xFF755300),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final encoded = Uri.encodeComponent(SystemDeckIds.newWords);
                  context.push('/deck/$encoded/flashcards?filter=new');
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Учить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: context.iosTokens.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DeckGrid extends StatelessWidget {
  const _DeckGrid({required this.decks});

  final List<DeckEntity> decks;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 520
                ? 2
                : 1;
            const gap = AppSpacing.md;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final deck in decks)
                  SizedBox(
                    width: width,
                    child: _DeckTile(deck: deck),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeckTile extends ConsumerWidget {
  const _DeckTile({required this.deck});

  final DeckEntity deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.iosTokens;
    final words = ref.watch(deckWordsProvider(deck.id));
    final visual = _visualFor(deck.id, tokens);

    return SizedBox(
      height: 136,
      child: NokhchiinSurfaceCard(
        onTap: () => context.push('/deck/${Uri.encodeComponent(deck.id)}'),
        radius: 8,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tokens.isDark
                        ? visual.color.withValues(alpha: 0.2)
                        : visual.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(visual.icon, color: visual.color, size: 22),
                ),
                const Spacer(),
                words.when(
                  data: (items) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        color: visual.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(width: 24, height: 24),
                  error: (_, _) =>
                      Icon(Icons.error_outline, color: tokens.error, size: 18),
                ),
                if (!deck.isSystem) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить колоду',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _deleteDeck(context, ref),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              deck.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    words.when(
                      data: (_) => _descriptionFor(deck.id),
                      loading: () => 'Считаем карточки...',
                      error: (_, _) => 'Не удалось загрузить',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: visual.color,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDeck(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить колоду?'),
        content: const Text(
          'Слова останутся в словаре, а их учебный прогресс сохранится.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deckRepoProvider).deleteDeck(deck.id);
    ref.invalidate(decksProvider);
  }
}

_DeckVisual _visualFor(String id, DesignTokens tokens) => switch (id) {
  SystemDeckIds.core => const _DeckVisual(
    Icons.auto_stories_outlined,
    DesignTokens.meadow,
    DesignTokens.meadowMuted,
  ),
  SystemDeckIds.phrases => const _DeckVisual(
    Icons.chat_bubble_outline,
    DesignTokens.terracotta,
    DesignTokens.terracottaMuted,
  ),
  SystemDeckIds.rare => const _DeckVisual(
    Icons.diamond_outlined,
    DesignTokens.gold,
    DesignTokens.goldMuted,
  ),
  SystemDeckIds.favorites => const _DeckVisual(
    Icons.favorite_outline,
    DesignTokens.coral,
    DesignTokens.coralMuted,
  ),
  SystemDeckIds.mistakes => _DeckVisual(
    Icons.replay_circle_filled_outlined,
    tokens.error,
    DesignTokens.coralMuted,
  ),
  SystemDeckIds.dictionary => const _DeckVisual(
    Icons.bookmark_add_outlined,
    DesignTokens.sky,
    DesignTokens.skyMuted,
  ),
  SystemDeckIds.newWords => const _DeckVisual(
    Icons.fiber_new_outlined,
    DesignTokens.gold,
    DesignTokens.goldMuted,
  ),
  SystemDeckIds.due => const _DeckVisual(
    Icons.schedule_outlined,
    DesignTokens.terracotta,
    DesignTokens.terracottaMuted,
  ),
  _ => const _DeckVisual(
    Icons.folder_outlined,
    DesignTokens.sky,
    DesignTokens.skyMuted,
  ),
};

String _descriptionFor(String id) => switch (id) {
  SystemDeckIds.core => 'База для уверенного старта',
  SystemDeckIds.phrases => 'Готовые выражения для общения',
  SystemDeckIds.rare => 'Необычная и менее частая лексика',
  SystemDeckIds.favorites => 'Отмеченные вами слова',
  SystemDeckIds.mistakes => 'Слова, где нужен ещё один подход',
  SystemDeckIds.dictionary => 'Ваша подборка из словаря',
  SystemDeckIds.newWords => 'Ещё не начатые карточки',
  SystemDeckIds.due => 'Пора освежить в памяти',
  _ => 'Личная подборка',
};

class _DeckVisual {
  const _DeckVisual(this.icon, this.color, this.background);

  final IconData icon;
  final Color color;
  final Color background;
}
