import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nokhchiin/app.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';

/// Дымовой E2E-тест на реальном устройстве/эмуляторе.
///
/// Проверяет самый важный флоу приложения целиком, а не изолированные виджеты:
/// запуск → онбординг (выбор трека → placement-тест) → главный экран →
/// переход на «Миры». Если тут что-то падает, значит сломан путь, которым
/// проходит каждый новый пользователь — widget-тесты такое не ловят, потому
/// что не поднимают реальный Hive и реальную навигацию go_router целиком.
///
/// Использует plain `integration_test`, а не `patrolTest` — Patrol в этом
/// тесте не нужен (нет native permission-диалогов), а его CLI-бандлер ломается
/// на дефисе в имени папки репозитория ("deshar-v2"). Пакет `patrol` остаётся
/// установлен для будущих тестов, которым реально нужна native-автоматизация.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding → placement test → home → world navigation works end-to-end', (tester) async {
    await Hive.initFlutter();
    await LocalProgressDataSource().init();
    await LocalUserDataSource().init();

    await tester.pumpWidget(const ProviderScope(child: NokhchiinApp()));
    // Splash ждёт max(загрузка профиля, 1200мс) через Future.delayed без
    // непрерывной анимации — pumpAndSettle() может решить, что всё "settled"
    // ещё до того, как этот таймер сработает и произойдёт redirect с
    // /splash. Явно прокачиваем реальное время, затем settle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Первый запуск показывает онбординг (выбор Дети/Взрослые, l10n:
    // adultModeTitle = "Взрослый режим") — если профиль уже сохранён с
    // прошлого прогона, сразу увидим Главную.
    List<String> visibleTexts() => find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .toList();

    final adultMode = find.text('Взрослый режим');
    if (adultMode.evaluate().isNotEmpty) {
      await tester.tap(adultMode);
      await tester.pumpAndSettle();

      // После выбора трека — короткий placement-тест. Пропускаем его через
      // кнопку в AppBar, не отвечая на вопросы: цель теста — проверить, что
      // навигация целиком не падает, а не логику placement-теста.
      final skip = find.text('Пропустить');
      expect(skip, findsOneWidget);
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }

    // Главный экран должен показать уровень пользователя.
    if (find.textContaining('Уровень').evaluate().isEmpty) {
      // ignore: avoid_print
      print('DEBUG: no "Уровень" found, visible texts: ${visibleTexts()}');
    }
    expect(find.textContaining('Уровень'), findsWidgets);

    // Переход на «Миры» через таб-бар не должен падать.
    await tester.tap(find.text('Миры').last);
    await tester.pumpAndSettle();
    expect(find.text('Миры'), findsWidgets);
  });
}
