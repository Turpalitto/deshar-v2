import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nokhchiin/app.dart';
import 'package:nokhchiin/core/router/app_router.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUi(WidgetTester tester, [int milliseconds = 900]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: milliseconds));
    await tester.pump(Duration(milliseconds: milliseconds));
  }

  setUpAll(() async {
    await Hive.initFlutter();
    await LocalProgressDataSource().init();
    await LocalUserDataSource().init();
    await Hive.box<Map>(LocalProgressDataSource.boxName).clear();
    await Hive.box<Map>(LocalUserDataSource.boxName).clear();
    await Hive.box<Map>(LocalUserDataSource.boxName).put('profile', {
      'mode': 1,
      'ageGroup': 1,
      'hasCompletedOnboarding': true,
      'seenCultureCapsules': <String>[],
      'weeklyXp': <int>[0, 0, 0, 0, 0, 0, 0],
    });
    OnboardingGuard.completed = true;
  });

  testWidgets('critical Android journey and main routes', (tester) async {
    final greetings = await _loadLessonPairs('greetings');
    appRouter.go('/splash');
    await tester.pumpWidget(const ProviderScope(child: NokhchiinApp()));
    await tester.pump(const Duration(seconds: 2));
    await pumpUi(tester, 1500);
    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text('План на сегодня'), findsOneWidget);

    appRouter.go('/lesson/greetings');
    await pumpUi(tester, 1200);
    if (find.text('✕ Закрыть').evaluate().isNotEmpty) {
      await tester.tap(find.text('✕ Закрыть'));
      await pumpUi(tester);
    }

    for (var i = 0; i < 8; i++) {
      expect(find.text('Повторить'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    }
    await pumpUi(tester, 1200);
    expect(find.textContaining('Собери пары'), findsWidgets);

    var matched = 0;
    for (final pair in greetings.entries) {
      final ce = find.text(pair.key);
      final ru = find.text(pair.value);
      if (ce.evaluate().isEmpty || ru.evaluate().isEmpty) continue;
      await tester.tap(ce.first);
      await tester.pump();
      await tester.tap(ru.first);
      await pumpUi(tester, 500);
      matched++;
    }
    expect(matched, 5);
    await pumpUi(tester, 1200);
    expect(find.textContaining('Вопрос 1 /'), findsOneWidget);

    for (var question = 0; question < 5; question++) {
      MapEntry<String, String>? visible;
      for (final pair in greetings.entries) {
        if (find.text(pair.key).evaluate().isNotEmpty) {
          visible = pair;
          break;
        }
      }
      expect(visible, isNotNull);
      final answer = find.textContaining(visible!.value);
      expect(answer, findsWidgets);
      await tester.ensureVisible(answer.last);
      await tester.pumpAndSettle();
      await tester.tap(answer.last);
      await tester.pump(const Duration(milliseconds: 900));
    }

    expect(find.text('Забрать награду'), findsOneWidget);
    await tester.tap(find.text('Забрать награду'));
    await pumpUi(tester, 1200);
    expect(find.text('Урок завершён!'), findsOneWidget);
    final next = find.textContaining('Дальше:');
    expect(next, findsOneWidget);
    await tester.tap(next);
    await pumpUi(tester, 1200);
    expect(find.textContaining('Урок'), findsWidgets);

    appRouter.go('/review');
    await pumpUi(tester);
    expect(find.text('Повторение'), findsWidgets);

    appRouter.go('/dictionary');
    await pumpUi(tester, 5000);
    expect(find.text('Словарь'), findsWidgets);

    appRouter.go('/profile');
    await pumpUi(tester);
    expect(find.text('Взрослый трек'), findsOneWidget);

    appRouter.go('/parent');
    await pumpUi(tester);
    expect(find.text('Кабинет родителя'), findsOneWidget);

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    appRouter.go('/');
    await pumpUi(tester);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
  });
}

Future<Map<String, String>> _loadLessonPairs(String lessonId) async {
  final raw = await rootBundle.loadString('assets/data/lessons.json');
  final lessons = jsonDecode(raw) as List<dynamic>;
  final lesson = lessons.whereType<Map<String, dynamic>>().firstWhere(
    (item) => item['id'] == lessonId,
  );
  final words = (lesson['words'] as List<dynamic>)
      .whereType<Map<String, dynamic>>();
  return {
    for (final word in words)
      word['chechen'] as String: word['russian'] as String,
  };
}
