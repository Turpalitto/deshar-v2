import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/domain/entities/deck_entity.dart';
import 'package:nokhchiin/domain/entities/dictionary_entry.dart';
import 'package:nokhchiin/domain/entities/entry_type.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/dictionary_search_repository.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/features/dictionary/dictionary_detail_screen.dart';

const _entry = DictionaryEntry(
  id: 'word-1',
  chechen: 'Маршалла',
  russian: 'Привет',
  type: EntryType.word,
  preview: 'Привет',
  searchTokens: {'маршалла', 'привет'},
);

class _DictionarySearch implements DictionarySearchRepository {
  @override
  int get totalCount => 1;

  @override
  Future<DictionaryEntry?> getById(String id) async =>
      id == _entry.id ? _entry : null;

  @override
  Future<List<DictionaryEntry>> getFavorites() async => const [];

  @override
  Future<List<DictionaryEntry>> getRelated(String id, {int limit = 10}) async =>
      const [];

  @override
  Future<DictionarySearchResult> search({
    required String query,
    required int page,
    required int pageSize,
    EntryType? typeFilter,
    bool favoritesOnly = false,
    bool fullDictionary = false,
  }) async => const DictionarySearchResult(
    entries: [_entry],
    page: 0,
    pageSize: 40,
    totalCount: 1,
  );

  @override
  Future<void> toggleFavorite(String id) async {}
}

class _Decks implements DeckRepository {
  final Map<String, Set<String>> memberships = {};

  @override
  Future<void> addWord(String wordId, String deckId) async {
    memberships.putIfAbsent(wordId, () => {}).add(deckId);
  }

  @override
  Future<DeckEntity> createDeck(String title) async =>
      DeckEntity(id: 'custom', title: title, isSystem: false);

  @override
  Future<void> deleteDeck(String deckId) async {}

  @override
  Future<DeckEntity?> getDeck(String deckId) async {
    for (final deck in DeckEntity.systemDecks) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  @override
  Future<Set<String>> getDeckIdsForWord(String wordId) async => {
    ...?memberships[wordId],
  };

  @override
  Future<List<DeckEntity>> getDecks() async => DeckEntity.systemDecks;

  @override
  Future<List<String>> getWordIds(String deckId, {DateTime? now}) async => [
    for (final item in memberships.entries)
      if (item.value.contains(deckId)) item.key,
  ];

  @override
  Future<void> removeWord(String wordId, String deckId) async {
    memberships[wordId]?.remove(deckId);
  }
}

class _Progress implements ProgressRepository {
  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() async => const {};

  @override
  Future<List<WordProgressEntity>> getDueForReview({DateTime? now}) async =>
      const [];

  @override
  Future<List<String>> getFavorites() async => const [];

  @override
  Future<WordProgressEntity?> getProgress(String wordId) async => null;

  @override
  Future<void> saveProgress(WordProgressEntity progress) async {}

  @override
  Future<void> toggleFavorite(String wordId) async {}
}

void main() {
  testWidgets('dictionary entry can be added to and removed from cards', (
    tester,
  ) async {
    final decks = _Decks();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionarySearchRepoProvider.overrideWithValue(_DictionarySearch()),
          deckRepoProvider.overrideWithValue(decks),
          progressRepoProvider.overrideWithValue(_Progress()),
        ],
        child: const MaterialApp(home: DictionaryDetailScreen(id: 'word-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Маршалла'), findsOneWidget);
    await tester.tap(find.text('Добавить в карточки'));
    await tester.pumpAndSettle();

    final dictionaryDeck = find.text('Добавлено из словаря');
    expect(dictionaryDeck, findsOneWidget);

    await tester.tap(dictionaryDeck);
    await tester.pump();
    expect(decks.memberships[_entry.id], contains(SystemDeckIds.dictionary));

    await tester.tap(dictionaryDeck);
    await tester.pump();
    expect(
      decks.memberships[_entry.id],
      isNot(contains(SystemDeckIds.dictionary)),
    );
  });
}
