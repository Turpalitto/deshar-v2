import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/core/services/analytics_service.dart';
import 'package:nokhchiin/domain/entities/analytics_event.dart';
import 'package:nokhchiin/domain/entities/conversation_entities.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/features/conversations/conversation_screen.dart';

class _ProgressRepository implements ProgressRepository {
  final data = <String, WordProgressEntity>{};

  @override
  Future<WordProgressEntity?> getProgress(String wordId) async => data[wordId];

  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() async => data;

  @override
  Future<void> saveProgress(WordProgressEntity progress) async {
    data[progress.wordId] = progress;
  }

  @override
  Future<List<WordProgressEntity>> getDueForReview({DateTime? now}) async => [];

  @override
  Future<List<String>> getFavorites() async => [];

  @override
  Future<void> toggleFavorite(String wordId) async {}
}

class _Analytics extends AnalyticsService {
  final events = <AnalyticsEventName>[];

  @override
  Future<void> track(
    AnalyticsEventName name, {
    Map<String, String> properties = const {},
  }) async {
    events.add(name);
  }
}

void main() {
  testWidgets('source-checked conversations use a neutral content label', (
    tester,
  ) async {
    const category = ConversationCategoryEntity(
      id: 'greetings',
      title: 'Знакомство',
      icon: 'chat',
      enabled: true,
      entries: [
        WordEntity(id: 'hello', chechen: 'Маршалла', russian: 'Здравствуйте'),
        WordEntity(id: 'thanks', chechen: 'Баркалла', russian: 'Спасибо'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationCategoriesProvider.overrideWith((_) async => [category]),
        ],
        child: const MaterialApp(home: ConversationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 фраз из учебной подборки'), findsOneWidget);
    expect(find.textContaining('проверенн'), findsNothing);
  });

  testWidgets('conversation answers update SRS and learning analytics', (
    tester,
  ) async {
    final progress = _ProgressRepository();
    final analytics = _Analytics();
    const words = [
      WordEntity(id: 'hello', chechen: 'Маршалла', russian: 'Здравствуйте'),
      WordEntity(id: 'thanks', chechen: 'Баркалла', russian: 'Спасибо'),
    ];
    const category = ConversationCategoryEntity(
      id: 'greetings',
      title: 'Знакомство',
      icon: 'chat',
      enabled: true,
      entries: words,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationCategoriesProvider.overrideWith((_) async => [category]),
          progressRepoProvider.overrideWithValue(progress),
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: const MaterialApp(
          home: ConversationQuizScreen(categoryId: 'greetings'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Маршалла'));
    await tester.pumpAndSettle();

    expect(find.text('Верно'), findsOneWidget);
    expect(progress.data['hello']?.repetitions, 1);
    expect(analytics.events, contains(AnalyticsEventName.answerSubmitted));
  });
}
