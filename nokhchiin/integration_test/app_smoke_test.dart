import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nokhchiin/app.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';

/// E2E: onboarding → placement → home → worlds → dictionary → review tab.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    await Hive.initFlutter();
    await LocalProgressDataSource().init();
    await LocalUserDataSource().init();
    await tester.pumpWidget(const ProviderScope(child: NokhchiinApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> completeAdultOnboarding(WidgetTester tester) async {
    final adultMode = find.text('Взрослый режим');
    if (adultMode.evaluate().isEmpty) return;
    await tester.tap(adultMode);
    await tester.pumpAndSettle();
    final skip = find.text('Пропустить');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('adult: onboarding → home → worlds → dictionary', (tester) async {
    await pumpApp(tester);
    await completeAdultOnboarding(tester);

    expect(find.textContaining('Уровень'), findsWidgets);

    await tester.tap(find.text('Миры').last);
    await tester.pumpAndSettle();
    expect(find.text('Миры'), findsWidgets);

    await tester.tap(find.text('Главная').last);
    await tester.pumpAndSettle();

    final dictionaryTile = find.text('Словарь');
    if (dictionaryTile.evaluate().isNotEmpty) {
      await tester.tap(dictionaryTile.first);
      await tester.pumpAndSettle();
      expect(find.text('Словарь'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('kids: age → placement skip → home → ai tutor route', (tester) async {
    await pumpApp(tester);

    final kidsMode = find.text('Детский режим');
    if (kidsMode.evaluate().isEmpty) return;

    await tester.tap(kidsMode);
    await tester.pumpAndSettle();

    final ageRow = find.text('6–9 лет');
    expect(ageRow, findsOneWidget);
    await tester.tap(ageRow);
    await tester.pumpAndSettle();

    final skip = find.text('Пропустить');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Уровень'), findsWidgets);

    final foxLink = find.text('Цхьогал');
    if (foxLink.evaluate().isNotEmpty) {
      await tester.tap(foxLink.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Цхьогал'), findsWidgets);
    }
  });

  testWidgets('review tab loads without crash', (tester) async {
    await pumpApp(tester);
    await completeAdultOnboarding(tester);

    await tester.tap(find.text('Повтор').last);
    await tester.pumpAndSettle();
    expect(find.text('Повтор'), findsWidgets);
  });
}