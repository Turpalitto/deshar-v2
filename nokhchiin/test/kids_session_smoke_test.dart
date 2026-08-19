import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/core/services/analytics_service.dart';
import 'package:nokhchiin/core/services/chechen_audio_service.dart';
import 'package:nokhchiin/domain/entities/analytics_event.dart';
import 'package:nokhchiin/domain/entities/daily_content_entity.dart';
import 'package:nokhchiin/domain/entities/daily_session_entity.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/features/home/kids_session_screen.dart';

const _words = [
  WordEntity(id: '1', chechen: 'ce-1', russian: 'ru-1', emoji: '1'),
  WordEntity(id: '2', chechen: 'ce-2', russian: 'ru-2', emoji: '2'),
  WordEntity(id: '3', chechen: 'ce-3', russian: 'ru-3', emoji: '3'),
  WordEntity(id: '4', chechen: 'ce-4', russian: 'ru-4', emoji: '4'),
  WordEntity(id: '5', chechen: 'ce-5', russian: 'ru-5', emoji: '5'),
];

class _KidsProfileNotifier extends UserProfileNotifier {
  _KidsProfileNotifier(this.ageGroup);

  final KidsAgeGroup ageGroup;
  int recordedWords = 0;
  int recordedMinutes = 0;

  @override
  Future<UserProfileEntity> build() async =>
      UserProfileEntity(mode: AppMode.kids, ageGroup: ageGroup);

  @override
  Future<bool> recordKidsSession({
    required int wordsLearned,
    required int minutes,
    DateTime? date,
  }) async {
    recordedWords += wordsLearned;
    recordedMinutes += minutes;
    return true;
  }
}

class _ProgressRepo implements ProgressRepository {
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

class _DailySessionRepo implements DailySessionRepository {
  DailySessionEntity? session;

  @override
  Future<DailySessionEntity?> getForDate(DateTime date) async => session;

  @override
  Future<List<DailySessionEntity>> getRecent({int limit = 7}) async =>
      session == null ? [] : [session!];

  @override
  Future<void> save(DailySessionEntity session) async {
    this.session = session;
  }
}

class _NoAudioService extends ChechenAudioService {
  @override
  Future<bool> hasVerifiedClip(String? audioId) async => false;
}

class _AnalyticsService extends AnalyticsService {
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
  testWidgets('kids complete a short word, phrase and quiz session', (
    tester,
  ) async {
    final profileNotifier = _KidsProfileNotifier(KidsAgeGroup.age3to6);
    final progressRepo = _ProgressRepo();
    final dailySessionRepo = _DailySessionRepo();
    final analytics = _AnalyticsService();
    final content = DailyContentEntity(
      date: DateTime(2026, 7, 28),
      wordOfTheDay: _words.first,
      newWords: _words,
      phraseOfTheDay: const WordEntity(
        id: 'phrase',
        chechen: 'phrase ce',
        russian: 'phrase ru',
      ),
      rareWordOfTheDay: _words.last,
      quizWords: _words,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => profileNotifier),
          progressRepoProvider.overrideWithValue(progressRepo),
          dailySessionRepoProvider.overrideWithValue(dailySessionRepo),
          todayContentProvider.overrideWith((_) async => content),
          chechenAudioServiceProvider.overrideWithValue(_NoAudioService()),
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: const MaterialApp(home: KidsSessionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ce-1'), findsOneWidget);
    expect(find.text('Аудио пока недоступно'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
    }
    expect(find.text('phrase ce'), findsOneWidget);

    await tester.tap(find.text('К заданию'));
    await tester.pumpAndSettle();
    expect(find.text('Найди картинку для слова'), findsOneWidget);
    expect(find.text('Послушай и найди картинку'), findsNothing);
    for (var index = 0; index < 3; index++) {
      expect(find.text('ce-${index + 1}'), findsOneWidget);
      await tester.tap(find.text('ru-${index + 1}'));
      await tester.pumpAndSettle();
      expect(find.text('Верно!'), findsOneWidget);

      final action = index == 2 ? 'Завершить' : 'Дальше';
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
    }
    expect(find.text('Занятие завершено'), findsOneWidget);
    expect(profileNotifier.recordedWords, 3);
    expect(profileNotifier.recordedMinutes, 1);
    expect(progressRepo.data['1']?.repetitions, 1);
    expect(progressRepo.data['2']?.repetitions, 1);
    expect(progressRepo.data['3']?.repetitions, 1);
    expect(progressRepo.data['phrase']?.mastery, MasteryLevel.seen);
    expect(
      analytics.events.where(
        (event) => event == AnalyticsEventName.answerSubmitted,
      ),
      hasLength(3),
    );
    expect(analytics.events, contains(AnalyticsEventName.sessionCompleted));
    expect(dailySessionRepo.session?.completedTaskIds, ['kids_session']);
    expect(dailySessionRepo.session?.quizScore, 3);
  });

  testWidgets('ages 6-9 get a recognition task for every introduced word', (
    tester,
  ) async {
    final content = DailyContentEntity(
      date: DateTime(2026, 7, 28),
      wordOfTheDay: _words.first,
      newWords: _words,
      phraseOfTheDay: null,
      rareWordOfTheDay: _words.last,
      quizWords: _words,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            () => _KidsProfileNotifier(KidsAgeGroup.age6to9),
          ),
          progressRepoProvider.overrideWithValue(_ProgressRepo()),
          dailySessionRepoProvider.overrideWithValue(_DailySessionRepo()),
          todayContentProvider.overrideWith((_) async => content),
          chechenAudioServiceProvider.overrideWithValue(_NoAudioService()),
          analyticsServiceProvider.overrideWithValue(_AnalyticsService()),
        ],
        child: const MaterialApp(home: KidsSessionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Что означает это слово?'), findsOneWidget);
    expect(find.text('ce-1'), findsOneWidget);
  });

  testWidgets('ages 9-12 must actively recall and type Chechen', (
    tester,
  ) async {
    final content = DailyContentEntity(
      date: DateTime(2026, 7, 28),
      wordOfTheDay: _words.first,
      newWords: _words,
      phraseOfTheDay: null,
      rareWordOfTheDay: _words.last,
      quizWords: _words,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            () => _KidsProfileNotifier(KidsAgeGroup.age9to12),
          ),
          progressRepoProvider.overrideWithValue(_ProgressRepo()),
          dailySessionRepoProvider.overrideWithValue(_DailySessionRepo()),
          todayContentProvider.overrideWith((_) async => content),
          chechenAudioServiceProvider.overrideWithValue(_NoAudioService()),
          analyticsServiceProvider.overrideWithValue(_AnalyticsService()),
        ],
        child: const MaterialApp(home: KidsSessionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 5; index++) {
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Напиши по-чеченски'), findsOneWidget);
    expect(find.text('ru-1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ce-1');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();
    expect(find.text('Верно!'), findsOneWidget);
  });
}
