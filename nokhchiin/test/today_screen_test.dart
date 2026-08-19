import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/domain/entities/daily_content_entity.dart';
import 'package:nokhchiin/domain/entities/deck_entity.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/features/today/today_screen.dart';

const _words = [
  WordEntity(id: 'w1', chechen: 'ce-1', russian: 'ru-1'),
  WordEntity(id: 'w2', chechen: 'ce-2', russian: 'ru-2'),
  WordEntity(id: 'w3', chechen: 'ce-3', russian: 'ru-3'),
  WordEntity(id: 'w4', chechen: 'ce-4', russian: 'ru-4'),
  WordEntity(id: 'w5', chechen: 'ce-5', russian: 'ru-5'),
];

const _phrase = WordEntity(
  id: 'phrase',
  chechen: 'phrase ce',
  russian: 'phrase ru',
);
const _rare = WordEntity(id: 'rare', chechen: 'rare-ce', russian: 'rare-ru');

class _Decks implements DeckRepository {
  final Map<String, Set<String>> memberships = {};

  @override
  Future<void> addWord(String wordId, String deckId) async {
    memberships.putIfAbsent(wordId, () => {}).add(deckId);
  }

  @override
  Future<DeckEntity> createDeck(String title) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDeck(String deckId) async {}

  @override
  Future<DeckEntity?> getDeck(String deckId) async => null;

  @override
  Future<Set<String>> getDeckIdsForWord(String wordId) async => {
    ...?memberships[wordId],
  };

  @override
  Future<List<DeckEntity>> getDecks() async => DeckEntity.systemDecks;

  @override
  Future<List<String>> getWordIds(String deckId, {DateTime? now}) async =>
      const [];

  @override
  Future<void> removeWord(String wordId, String deckId) async {
    memberships[wordId]?.remove(deckId);
  }
}

void main() {
  testWidgets('today shows the complete adult daily cycle', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final decks = _Decks();
    final today = DateTime(2026, 7, 28);
    final content = DailyContentEntity(
      date: today,
      wordOfTheDay: _words.first,
      newWords: _words,
      phraseOfTheDay: _phrase,
      rareWordOfTheDay: _rare,
      quizWords: _words,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayContentProvider.overrideWith((ref) async => content),
          dailyHistoryProvider.overrideWith((ref) async => const []),
          dueWordsProvider.overrideWith((ref) async => const []),
          allProgressProvider.overrideWith((ref) async => const {}),
          deckRepoProvider.overrideWithValue(decks),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Просроченные повторения'), findsOneWidget);
    expect(find.text('Пять новых слов'), findsOneWidget);
    expect(find.text('Слово дня'), findsOneWidget);
    expect(find.text('Фраза дня'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Добавить в карточки').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Добавить в карточки').first);
    await tester.pumpAndSettle();
    expect(
      decks.memberships[_words.first.id],
      contains(SystemDeckIds.dictionary),
    );

    await tester.scrollUntilVisible(
      find.text('Редкое слово дня'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Редкое слово дня'), findsOneWidget);
    expect(find.textContaining('Викторина'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('История'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('История'), findsOneWidget);
  });
}
