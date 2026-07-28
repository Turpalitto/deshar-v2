import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/chechen_audio_controls.dart';
import '../../core/utils/dictionary_labels.dart';
import '../../domain/entities/content_metadata.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/entities/entry_type.dart';
import 'dictionary_card.dart';

/// Экран детали записи словаря.
///
/// Большой заголовок, перевод, категория, источники, связанные записи,
/// favorite, copy.
class DictionaryDetailScreen extends ConsumerWidget {
  const DictionaryDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(dictionaryEntryProvider(id));
    final related = ref.watch(dictionaryRelatedProvider(id));
    final e = entry.valueOrNull;

    // Единый шелл AppScaffold вместо голого Scaffold+SliverAppBar — раньше
    // в приложении было 4 несовместимых системы шапки экрана (аудит §3/§8).
    return AppScaffold(
      actions: e == null
          ? null
          : [
              IconButton(
                icon: Icon(
                  e.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: e.favorite ? Colors.redAccent : null,
                ),
                onPressed: () async {
                  await ref
                      .read(dictionarySearchRepoProvider)
                      .toggleFavorite(e.id);
                  ref.invalidate(dictionaryEntryProvider(e.id));
                  ref.invalidate(dictionaryRelatedProvider(id));
                },
                tooltip: 'Избранное',
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Копировать',
                onPressed: () => _onCopy(context, e),
              ),
            ],
      body: entry.when(
        data: (e) => e == null
            ? _NotFound(onBack: () => context.pop())
            : _DetailContent(
                entry: e,
                related: related.valueOrNull ?? const [],
                onAddToCards: () => _showDeckPicker(context, ref, e.id),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _NotFound(onBack: () => context.pop()),
      ),
    );
  }

  void _onCopy(BuildContext context, DictionaryEntry entry) {
    Clipboard.setData(
      ClipboardData(text: '${entry.chechen} — ${entry.russian}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Скопировано'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showDeckPicker(
    BuildContext context,
    WidgetRef ref,
    String wordId,
  ) async {
    final repository = ref.read(deckRepoProvider);
    var decks = await repository.getDecks();
    final memberships = await repository.getDeckIdsForWord(wordId);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final editable = decks
              .where(
                (deck) => !deck.isSystem || deck.id == SystemDeckIds.dictionary,
              )
              .toList();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.iosTokens.separator,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Добавить в карточки',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined),
                        tooltip: 'Создать колоду',
                        onPressed: () async {
                          final deck = await _createDeck(context, ref);
                          if (deck == null) return;
                          await repository.addWord(wordId, deck.id);
                          memberships.add(deck.id);
                          decks = await repository.getDecks();
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final deck in editable)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(deck.title),
                            onTap: () async {
                              final selected = !memberships.contains(deck.id);
                              if (selected) {
                                await repository.addWord(wordId, deck.id);
                                memberships.add(deck.id);
                              } else {
                                await repository.removeWord(wordId, deck.id);
                                memberships.remove(deck.id);
                              }
                              setSheetState(() {});
                            },
                            trailing: Switch.adaptive(
                              value: memberships.contains(deck.id),
                              onChanged: (selected) async {
                                if (selected) {
                                  await repository.addWord(wordId, deck.id);
                                  memberships.add(deck.id);
                                } else {
                                  await repository.removeWord(wordId, deck.id);
                                  memberships.remove(deck.id);
                                }
                                setSheetState(() {});
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    ref.invalidate(wordDeckMembershipProvider(wordId));
    ref.invalidate(wordProgressProvider(wordId));
    ref.invalidate(decksProvider);
    for (final deck in decks) {
      ref.invalidate(deckWordsProvider(deck.id));
    }
  }

  Future<DeckEntity?> _createDeck(BuildContext context, WidgetRef ref) async {
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
    if (title == null || title.trim().isEmpty) return null;
    return ref.read(deckRepoProvider).createDeck(title);
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.entry,
    required this.related,
    required this.onAddToCards,
  });

  final DictionaryEntry entry;
  final List<DictionaryEntry> related;
  final VoidCallback onAddToCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.iosTokens;
    final progress = ref.watch(wordProgressProvider(entry.id)).valueOrNull;
    final categoryLabel = DictionaryLabels.categoryLabel(
      entry.category,
      sources: entry.sources,
    );
    final transcription = DictionaryLabels.displayTranscription(
      entry.chechen,
      entry.pronunciation,
    );
    final infoRows = <Widget>[
      _InfoRow(label: 'Проверка', value: entry.reviewStatus.labelRu),
      if (entry.frequencyTier != null)
        _InfoRow(
          label: 'Частотность',
          value: _frequencyLabel(entry.frequencyTier!),
        ),
      _InfoRow(
        label: 'Источник',
        value: DictionaryLabels.sourcesLabel(entry.sources),
      ),
      if (entry.languageRegister != null)
        _InfoRow(
          label: 'Стиль речи',
          value: _registerLabel(entry.languageRegister!),
        ),
      if (entry.region != null) _InfoRow(label: 'Регион', value: entry.region!),
      _InfoRow(
        label: 'Изучение',
        value: progress?.mastery.labelRu ?? 'Не изучалось',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeBadge(type: entry.type),
          const SizedBox(height: 12),
          Text(
            entry.chechen,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
              height: 1.2,
            ),
          ),
          if (transcription != null) ...[
            const SizedBox(height: 8),
            Text(
              '[$transcription]',
              style: TextStyle(fontSize: 15, color: tokens.textTertiary),
            ),
          ],
          const SizedBox(height: 10),
          ChechenAudioControls(audioId: entry.audioId),
          const SizedBox(height: 20),
          const _SectionLabel('Перевод'),
          const SizedBox(height: 6),
          _GroupedSection(
            rows: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.russian,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    if (categoryLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (entry.examples.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel('Пример'),
            const SizedBox(height: 6),
            _GroupedSection(
              rows: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.examples.first.chechen,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.examples.first.russian,
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const _SectionLabel('Сведения'),
          const SizedBox(height: 6),
          _GroupedSection(rows: infoRows),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.accentOn,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAddToCards,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Добавить в карточки'),
            ),
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionLabel('Связанные слова'),
            const SizedBox(height: 6),
            _GroupedSection(
              rows: [
                for (final relatedEntry in related)
                  DictionaryCard(
                    entry: relatedEntry,
                    onTap: () => context.push('/dictionary/${relatedEntry.id}'),
                    onFavorite: () async {
                      await ref
                          .read(dictionarySearchRepoProvider)
                          .toggleFavorite(relatedEntry.id);
                      ref.invalidate(dictionaryEntryProvider(relatedEntry.id));
                      ref.invalidate(dictionaryRelatedProvider(entry.id));
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final EntryType type;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final color = switch (type) {
      EntryType.word => DesignTokens.meadow,
      EntryType.phrase => DesignTokens.terracotta,
      EntryType.idiom => DesignTokens.coral,
      EntryType.expression => DesignTokens.gold,
      EntryType.sentence => DesignTokens.sky,
      EntryType.unknown => tokens.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_entryTypeIcon(type), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.iosTokens.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.separator),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              rows[index],
              if (index < rows.length - 1)
                Divider(height: 1, indent: 14, color: tokens.separator),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: tokens.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _entryTypeIcon(EntryType type) => switch (type) {
  EntryType.word => Icons.text_fields_rounded,
  EntryType.phrase => Icons.format_quote_rounded,
  EntryType.idiom => Icons.forum_outlined,
  EntryType.expression => Icons.translate_rounded,
  EntryType.sentence => Icons.subject_rounded,
  EntryType.unknown => Icons.help_outline_rounded,
};

String _frequencyLabel(FrequencyTier tier) => switch (tier) {
  FrequencyTier.common => 'Частое слово',
  FrequencyTier.uncommon => 'Менее частое',
  FrequencyTier.rare => 'Редкое слово',
};

String _registerLabel(LanguageRegister register) => switch (register) {
  LanguageRegister.modern => 'Современная речь',
  LanguageRegister.archaic => 'Устаревшее',
  LanguageRegister.dialect => 'Диалектное',
  LanguageRegister.technical => 'Специальный термин',
};

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Запись не найдена', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          TextButton(onPressed: onBack, child: const Text('Назад')),
        ],
      ),
    );
  }
}
