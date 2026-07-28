import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/design/widgets/app_shell.dart';
import 'package:nokhchiin/core/design_system/widgets/nokhchiin_tab_bar.dart';
import 'package:nokhchiin/domain/entities/enums.dart';

void main() {
  test('adult navigation uses daily vocabulary workflow', () {
    final config = AppNavigationConfig.forMode(AppMode.adult);
    expect(config.labels, ['Сегодня', 'Карточки', 'Словарь', 'Профиль']);
    expect(config.routes, ['/', '/collections', '/dictionary', '/profile']);
  });

  test('kids navigation uses games and contextual phrases', () {
    final config = AppNavigationConfig.forMode(AppMode.kids);
    expect(config.labels, ['Главная', 'Игры', 'Фразы', 'Профиль']);
    expect(config.routes, ['/', '/games', '/phrases', '/profile']);
  });

  testWidgets('tab bar renders the selected mode labels', (tester) async {
    final config = AppNavigationConfig.forMode(AppMode.kids);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NokhchiinTabBar(
            currentIndex: 0,
            onTap: (_) {},
            labels: config.labels,
            iconAssets: config.iconAssets,
          ),
        ),
      ),
    );

    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Игры'), findsOneWidget);
    expect(find.text('Фразы'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('Миры'), findsNothing);
  });
}
