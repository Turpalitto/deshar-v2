import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/data/datasources/content_parse_exception.dart';
import 'package:nokhchiin/data/datasources/content_parser.dart';

void main() {
  group('parseWorld', () {
    test('happy path', () {
      final world = parseWorld({
        'id': 'meadow',
        'titleRu': 'Животные',
        'titleCe': 'Дийнаташ',
        'emoji': '🐻',
        'gradient': ['#A8E6CF', '#DCEDC1'],
        'unlockStars': 0,
        'units': ['animals'],
      });

      expect(world.id, 'meadow');
      expect(world.units, ['animals']);
      expect(world.gradient.length, 2);
    });

    test('missing id throws ContentParseException', () {
      expect(
        () => parseWorld({'titleRu': 'x', 'titleCe': 'y', 'gradient': [], 'units': []}),
        throwsA(isA<ContentParseException>()),
      );
    });
  });

  group('parseCollection', () {
    test('happy path', () {
      final col = parseCollection({
        'id': 'album_animals',
        'titleRu': 'Альбом',
        'titleCe': 'Дийнаташ',
        'category': 'animals',
        'totalCards': 14,
        'rarity': 'common',
      });

      expect(col.totalCards, 14);
      expect(col.rarity, 'common');
    });

    test('missing totalCards throws', () {
      expect(
        () => parseCollection({
          'id': 'a',
          'titleRu': 'b',
          'titleCe': 'c',
          'category': 'animals',
          'rarity': 'common',
        }),
        throwsA(isA<ContentParseException>()),
      );
    });
  });

  group('parseStory', () {
    test('happy path with panels and quiz', () {
      final story = parseStory({
        'id': 'fox',
        'titleRu': 'Лиса',
        'titleCe': 'Цхьогал',
        'unitId': 'greetings',
        'requiredMastery': 60,
        'panels': [
          {
            'imageKey': 'meadow',
            'narrationRu': 'Утро',
            'dialogue': [
              {'speaker': 'Цхьогал', 'chechen': 'Маршалла', 'russian': 'Привет'},
            ],
          },
        ],
        'quiz': [
          {
            'question': 'Привет?',
            'answer': 'Маршалла',
            'options': ['Маршалла', 'Баркалла'],
          },
        ],
      });

      expect(story.panels.length, 1);
      expect(story.quiz.length, 1);
      expect(story.panels.first.dialogue.first.chechen, 'Маршалла');
    });

    test('missing unitId throws', () {
      expect(
        () => parseStory({'id': 'x', 'titleRu': 'a', 'titleCe': 'b'}),
        throwsA(isA<ContentParseException>()),
      );
    });
  });

  group('parseBoss', () {
    test('happy path', () {
      final boss = parseBoss({
        'id': 'boss_animals',
        'unitId': 'animals',
        'titleRu': 'Хранитель',
        'titleCe': 'Хьунан',
        'questionsCount': 10,
        'timeLimitSec': 120,
        'passScore': 8,
        'rewardStars': 25,
        'rewardXp': 100,
      });

      expect(boss.passScore, 8);
      expect(boss.rewardXp, 100);
    });

    test('missing passScore throws', () {
      expect(
        () => parseBoss({
          'id': 'b',
          'unitId': 'animals',
          'titleRu': 't',
          'titleCe': 't',
          'questionsCount': 1,
          'timeLimitSec': 1,
          'rewardStars': 1,
          'rewardXp': 1,
        }),
        throwsA(isA<ContentParseException>()),
      );
    });
  });

  group('parseWorlds list', () {
    test('invalid root key returns parse exception', () {
      expect(
        () => parseWorlds('{"not_worlds": []}'),
        throwsA(isA<ContentParseException>()),
      );
    });
  });
}
