import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nokhchiin/app.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/core/router/app_router.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/domain/constants/gameplay_constants.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    await LocalProgressDataSource().init();
    await LocalDeckDataSource().init();
    await LocalUserDataSource().init();
    await LocalDailySessionDataSource().init();
  });

  setUp(() async {
    await Hive.box<Map>(LocalProgressDataSource.boxName).clear();
    await Hive.box<Map>(LocalDeckDataSource.boxName).clear();
    await Hive.box<Map>(LocalUserDataSource.boxName).clear();
    await Hive.box<Map>(LocalDailySessionDataSource.boxName).clear();
    OnboardingGuard.completed = false;
  });

  for (final scenario in <(KidsAgeGroup, String, int)>[
    (
      KidsAgeGroup.age3to6,
      '3–6 лет',
      GameplayConstants.kidsAge3to6SessionWordCount,
    ),
    (
      KidsAgeGroup.age6to9,
      '6–9 лет',
      GameplayConstants.kidsAge6to9SessionWordCount,
    ),
    (
      KidsAgeGroup.age9to12,
      '9–12 лет',
      GameplayConstants.kidsAge9to12SessionWordCount,
    ),
  ]) {
    testWidgets(
      '${scenario.$2}: progress survives an app restart',
      (tester) => _runKidsJourney(
        tester,
        ageGroup: scenario.$1,
        ageLabel: scenario.$2,
        wordCount: scenario.$3,
      ),
    );
  }
}

Future<void> _runKidsJourney(
  WidgetTester tester, {
  required KidsAgeGroup ageGroup,
  required String ageLabel,
  required int wordCount,
}) async {
  final container = ProviderContainer();
  appRouter.go('/onboarding');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const NokhchiinApp(),
    ),
  );
  await _pumpUi(tester, 1200);

  await tester.tap(find.text('Детский режим'));
  await _pumpUi(tester);
  await tester.tap(find.text(ageLabel));
  await _pumpUi(tester, 1200);
  await tester.ensureVisible(find.text('Пропустить'));
  await tester.tap(find.text('Пропустить'));
  await _pumpUi(tester, 1500);

  final content = await container.read(todayContentProvider.future);
  expect(content, isNotNull);
  final words = content!.newWords.take(wordCount).toList();
  expect(words, hasLength(wordCount));

  await tester.ensureVisible(find.byKey(const Key('kids_continue')));
  await tester.tap(find.byKey(const Key('kids_continue')));
  await _pumpUi(tester, 1200);

  for (var index = 0; index < wordCount; index++) {
    await tester.ensureVisible(find.text('Дальше'));
    await tester.tap(find.text('Дальше'));
    await _pumpUi(tester);
  }
  if (content.phraseOfTheDay != null) {
    await tester.ensureVisible(find.text('К заданию'));
    await tester.tap(find.text('К заданию'));
    await _pumpUi(tester);
  }

  for (var index = 0; index < words.length; index++) {
    final target = words[index];
    final answer = index == 0 ? words[1] : target;
    await _submitAnswer(tester, ageGroup, target: target, answer: answer);

    if (index == 0) {
      expect(find.textContaining('Правильный ответ'), findsOneWidget);
    } else {
      expect(find.text('Верно!'), findsOneWidget);
    }

    final action = index == words.length - 1 ? 'Завершить' : 'Дальше';
    await tester.ensureVisible(find.text(action));
    await tester.tap(find.text(action));
    await _pumpUi(tester);
  }

  expect(find.text('Занятие завершено'), findsOneWidget);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  container.dispose();

  final restarted = ProviderContainer();
  addTearDown(restarted.dispose);
  final profile = await restarted.read(userProfileProvider.future);
  final progress = await restarted.read(progressRepoProvider).getAllProgress();
  final history = await restarted.read(dailySessionRepoProvider).getRecent();

  expect(profile.ageGroup, ageGroup);
  expect(profile.wordsLearnedToday, wordCount);
  expect(profile.todayMinutes, greaterThanOrEqualTo(1));
  expect(profile.xp, wordCount * GameplayConstants.wordLearnedXp);
  expect(history, hasLength(1));
  expect(history.single.quizScore, wordCount - 1);
  expect(history.single.quizTotal, wordCount);
  expect(history.single.completedTaskIds, contains('kids_session'));
  expect(progress[words.first.id]?.wrongCount, 1);
  for (final word in words.skip(1)) {
    expect(progress[word.id]?.repetitions, 1);
  }
}

Future<void> _submitAnswer(
  WidgetTester tester,
  KidsAgeGroup ageGroup, {
  required WordEntity target,
  required WordEntity answer,
}) async {
  switch (ageGroup) {
    case KidsAgeGroup.age3to6:
    case KidsAgeGroup.age6to9:
      await tester.ensureVisible(find.text(answer.russian));
      await tester.tap(find.text(answer.russian));
      break;
    case KidsAgeGroup.age9to12:
      await tester.enterText(find.byType(TextField), answer.chechen);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.onSubmitted, isNotNull);
      field.onSubmitted!(answer.chechen);
      break;
  }
  await _pumpUi(tester);
}

Future<void> _pumpUi(WidgetTester tester, [int milliseconds = 700]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: milliseconds));
  await tester.pump(Duration(milliseconds: milliseconds));
}
