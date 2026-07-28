import 'dart:convert';
import 'dart:io';

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
        () => parseWorld({
          'titleRu': 'x',
          'titleCe': 'y',
          'gradient': [],
          'units': [],
        }),
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
              {
                'speaker': 'Цхьогал',
                'chechen': 'Маршалла',
                'russian': 'Привет',
              },
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

  group('parseCultureCapsule', () {
    test('happy path keeps the unit link and optional illustration', () {
      final capsule = parseCultureCapsule({
        'id': 'home_hospitality',
        'relatedUnitId': 'home',
        'eyebrow': 'Дом · гостеприимство',
        'tags': ['Дом', 'Гость', 'Уважение'],
        'title': 'Дом и гостеприимство',
        'body': 'Первый абзац.\n\nВторой абзац.',
        'imagePath': 'assets/images/culture/home_welcome.png',
        'featuredWord': {
          'chechen': 'ЦӀий',
          'russian': 'Дом',
          'pronunciation': 'ЦӀий',
        },
      });

      expect(capsule.relatedUnitId, 'home');
      expect(capsule.paragraphs, hasLength(2));
      expect(capsule.imagePath, 'assets/images/culture/home_welcome.png');
      expect(capsule.eyebrow, 'Дом · гостеприимство');
      expect(capsule.tags, ['Дом', 'Гость', 'Уважение']);
      expect(capsule.featuredWord?.chechen, 'ЦӀий');
    });

    test('missing body throws', () {
      expect(
        () => parseCultureCapsule({
          'id': 'x',
          'relatedUnitId': 'home',
          'title': 'x',
        }),
        throwsA(isA<ContentParseException>()),
      );
    });

    test('bundled capsules cover every learning unit exactly once', () {
      final raw = File('assets/data/culture_capsules.json').readAsStringSync();
      final capsules = parseCultureCapsules(raw);
      final unitIds = capsules.map((capsule) => capsule.relatedUnitId).toSet();

      expect(capsules, hasLength(15));
      expect(unitIds, hasLength(15));
      expect(
        unitIds,
        containsAll(['greetings', 'animals', 'school', 'stories']),
      );
    });

    test('bundled capsule words belong to their linked lessons', () {
      final capsuleRaw = File(
        'assets/data/culture_capsules.json',
      ).readAsStringSync();
      final capsules = parseCultureCapsules(capsuleRaw);
      final lessonRaw =
          jsonDecode(File('assets/data/lessons.json').readAsStringSync())
              as List<dynamic>;
      final lessonWords = <String, Set<String>>{};
      for (final item in lessonRaw.cast<Map<String, dynamic>>()) {
        final words = (item['words'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        lessonWords[item['id'] as String] = {
          for (final word in words)
            '${word['chechen']}|${word['russian']}|${word['pronunciation']}',
        };
      }

      for (final capsule in capsules) {
        expect(capsule.eyebrow, isNotEmpty, reason: capsule.id);
        expect(capsule.tags, hasLength(3), reason: capsule.id);
        final featured = capsule.featuredWord;
        if (featured == null) continue;
        expect(
          lessonWords[capsule.relatedUnitId],
          contains(
            '${featured.chechen}|${featured.russian}|'
            '${featured.pronunciation}',
          ),
          reason: '${capsule.id} points to a word outside its lesson',
        );
      }
    });

    test('bundled capsules have local illustrations', () {
      final raw = File('assets/data/culture_capsules.json').readAsStringSync();
      final capsules = parseCultureCapsules(raw);

      for (final capsule in capsules) {
        expect(capsule.imagePath, isNotNull, reason: capsule.id);
        expect(
          File(capsule.imagePath!).existsSync(),
          isTrue,
          reason: '${capsule.id} references a missing illustration',
        );
      }
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

  test('bundled story panels have stable illustration keys', () {
    final raw = File('assets/data/stories.json').readAsStringSync();
    final stories = parseStories(raw);

    for (final story in stories) {
      for (final panel in story.panels) {
        expect(panel.imageKey.trim(), isNotEmpty, reason: story.id);
      }
    }
  });
}
