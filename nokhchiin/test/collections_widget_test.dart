import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/domain/entities/deck_entity.dart';
import 'package:nokhchiin/domain/entities/dictionary_entry.dart';
import 'package:nokhchiin/domain/entities/entry_type.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/dictionary_search_repository.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/features/collections/collections_screen.dart';
import 'package:nokhchiin/features/collections/deck_detail_screen.dart';
import 'package:nokhchiin/features/dictionary/dictionary_detail_screen.dart';

const _word = WordEntity(
  id: 'word-1',
  chechen: 'Маршалла',
  russian: 'Здравствуйте',
  sources: ['curated'],
);

class _Decks implements DeckRepository {
  final Map<String, Set<String>> memberships = {};
  final List<DeckEntity> decks = [...DeckEntity.systemDecks];

  @override
  Future<void> addWord(String wordId, String deckId) async {
    memberships.putIfAbsent(wordId, () => {}).add(deckId);
  }

  @override
  Future<DeckEntity> createDeck(String title) async {
    final deck = DeckEntity(
      id: 'custom-${decks.length}',
      title: title,
      isSystem: false,
    );
    decks.add(deck);
    return deck;
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    decks.removeWhere((deck) => deck.id == deckId);
  }

  @override
  Future<DeckEntity?> getDeck(String deckId) async {
    for (final deck in decks) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  @override
  Future<Set<String>> getDeckIdsForWord(String wordId) async => {
    ...?memberships[wordId],
  };

  @override
  Future<List<DeckEntity>> getDecks() async => decks;

  @override
  Future<List<String>> getWordIds(String deckId, {DateTime? now}) async {
    if (deckId == SystemDeckIds.core) return [_word.id];
    return [
      for (final entry in memberships.entries)
        if (entry.value.contains(deckId)) entry.key,
    ];
  }

  @override
  Future<void> removeWord(String wordId, String deckId) async {
    memberships[wordId]?.remove(deckId);
  }
}

class _Dictionary implements DictionaryRepository {
  @override
  Future<List<WordEntity>> getAllWords() async => const [_word];

  @override
  Future<List<WordEntity>> getCuratedWords() async => const [_word];

  @override
  Future<List<WordEntity>> getLessonWords() async => const [_word];

  @override
  Future<WordEntity?> getWordById(String id) async =>
      id == _word.id ? _word : null;

  @override
  Future<List<WordEntity>> getWordsByCategory(String category) async => const [
    _word,
  ];

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async =>
      ids.contains(_word.id) ? const [_word] : const [];

  @override
  Future<List<WordEntity>> search(
    String query, {
    String? category,
    PartOfSpeech? pos,
  }) async => const [_word];
}

class _Progress implements ProgressRepository {
  final Map<String, WordProgressEntity> values = {};

  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() async => values;

  @override
  Future<List<WordProgressEntity>> getDueForReview({DateTime? now}) async =>
      const [];

  @override
  Future<List<String>> getFavorites() async => const [];

  @override
  Future<WordProgressEntity?> getProgress(String wordId) async =>
      values[wordId];

  @override
  Future<void> saveProgress(WordProgressEntity progress) async {
    values[progress.wordId] = progress;
  }

  @override
  Future<void> toggleFavorite(String wordId) async {}
}

class _Search implements DictionarySearchRepository {
  @override
  int get totalCount => 1;

  @override
  Future<DictionaryEntry?> getById(String id) async => DictionaryEntry(
    id: _word.id,
    type: EntryType.word,
    chechen: _word.chechen,
    russian: _word.russian,
    preview: _word.russian,
    searchTokens: const {'маршалла'},
  );

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
    entries: [],
    page: 0,
    pageSize: 40,
    totalCount: 0,
  );

  @override
  Future<void> toggleFavorite(String id) async {}
}

void main() {
  testWidgets('tapping a system deck opens its detail route', (tester) async {
    final decks = _Decks();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CollectionsScreen()),
        GoRoute(
          path: '/deck/:id',
          builder: (_, state) =>
              Scaffold(body: Text('deck:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckRepoProvider.overrideWithValue(decks),
          dictionaryRepoProvider.overrideWithValue(_Dictionary()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Основные слова'));
    await tester.pumpAndSettle();

    expect(find.text('deck:${SystemDeckIds.core}'), findsOneWidget);
  });

  testWidgets('dictionary entry can be added to cards', (tester) async {
    final decks = _Decks();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckRepoProvider.overrideWithValue(decks),
          dictionaryRepoProvider.overrideWithValue(_Dictionary()),
          progressRepoProvider.overrideWithValue(_Progress()),
          dictionarySearchRepoProvider.overrideWithValue(_Search()),
        ],
        child: const MaterialApp(home: DictionaryDetailScreen(id: 'word-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить в карточки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавлено из словаря'));
    await tester.pumpAndSettle();

    expect(decks.memberships['word-1'], contains(SystemDeckIds.dictionary));
  });

  testWidgets('deck actions open existing exercises', (tester) async {
    final decks = _Decks();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const DeckDetailScreen(deckId: SystemDeckIds.core),
        ),
        GoRoute(
          path: '/deck/:id/quiz',
          builder: (_, state) =>
              Scaffold(body: Text('quiz:${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckRepoProvider.overrideWithValue(decks),
          dictionaryRepoProvider.overrideWithValue(_Dictionary()),
          progressRepoProvider.overrideWithValue(_Progress()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Учить новые'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Викторина'), findsOneWidget);
    expect(find.text('Пары'), findsOneWidget);
    expect(find.text('Перемешать'), findsOneWidget);

    await tester.tap(find.text('Викторина'));
    await tester.pumpAndSettle();
    expect(find.text('quiz:${SystemDeckIds.core}'), findsOneWidget);
  });

  testWidgets('empty favorites explains how to add words', (tester) async {
    final decks = _Decks();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const DeckDetailScreen(deckId: SystemDeckIds.favorites),
        ),
        GoRoute(
          path: '/dictionary',
          builder: (_, _) => const Scaffold(body: Text('dictionary')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckRepoProvider.overrideWithValue(decks),
          dictionaryRepoProvider.overrideWithValue(_Dictionary()),
          progressRepoProvider.overrideWithValue(_Progress()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пока ничего не отмечено'), findsOneWidget);
    expect(find.text('Открыть словарь'), findsOneWidget);

    await tester.tap(find.text('Открыть словарь'));
    await tester.pumpAndSettle();
    expect(find.text('dictionary'), findsOneWidget);
  });
}
