import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/core/services/chechen_audio_service.dart';
import 'package:nokhchiin/domain/entities/daily_content_entity.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/features/home/kids_session_screen.dart';

const _words = [
  WordEntity(id: '1', chechen: 'ce-1', russian: 'ru-1', emoji: '1'),
  WordEntity(id: '2', chechen: 'ce-2', russian: 'ru-2', emoji: '2'),
  WordEntity(id: '3', chechen: 'ce-3', russian: 'ru-3', emoji: '3'),
  WordEntity(id: '4', chechen: 'ce-4', russian: 'ru-4', emoji: '4'),
  WordEntity(id: '5', chechen: 'ce-5', russian: 'ru-5', emoji: '5'),
];

class _KidsProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfileEntity> build() async => const UserProfileEntity(
    mode: AppMode.kids,
    ageGroup: KidsAgeGroup.age3to6,
  );
}

class _NoAudioService extends ChechenAudioService {
  @override
  Future<bool> hasVerifiedClip(String? audioId) async => false;
}

void main() {
  testWidgets('kids complete a short word, phrase and quiz session', (
    tester,
  ) async {
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
          userProfileProvider.overrideWith(_KidsProfileNotifier.new),
          todayContentProvider.overrideWith((_) async => content),
          chechenAudioServiceProvider.overrideWithValue(_NoAudioService()),
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

    await tester.tap(find.text('К викторине'));
    await tester.pumpAndSettle();
    expect(find.text('ce-1'), findsOneWidget);

    await tester.tap(find.text('ru-1'));
    await tester.pumpAndSettle();
    expect(find.text('Верно!'), findsOneWidget);

    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();
    expect(find.text('Занятие завершено'), findsOneWidget);
  });
}
