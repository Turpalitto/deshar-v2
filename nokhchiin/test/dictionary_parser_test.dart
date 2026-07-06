import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/data/datasources/asset_dictionary_parser.dart';

void main() {
  group('parseBundledDictionaryIsolate', () {
    test('parses curated entries correctly', () {
      final rawJson = {
        'curated': jsonEncode({
          'entries': [
            {
              'chechen': 'маршалла',
              'russian': 'Здравствуйте',
              'category': 'greetings',
              'emoji': '👋',
              'sources': ['curated'],
            },
            {
              'chechen': 'ткъа',
              'russian': 'Двадцать',
              'category': 'numbers',
            },
          ],
        }),
        'dictionary': jsonEncode({'entries': []}),
      };

      final words = parseBundledDictionaryIsolate(rawJson);

      expect(words.length, 2);
      expect(words[0].chechen, 'Маршалла'); // capitalized
      expect(words[0].russian, 'Здравствуйте');
      expect(words[0].partOfSpeech, PartOfSpeech.phrase); // greetings → phrase
      expect(words[0].emoji, '👋');
      expect(words[0].tags, ['verified']);

      expect(words[1].partOfSpeech, PartOfSpeech.number); // numbers → number
    });

    test('parses dictionary entries correctly', () {
      final rawJson = {
        'curated': jsonEncode({'entries': []}),
        'dictionary': jsonEncode({
          'entries': [
            {
              'chechen': 'бер',
              'russian': 'Ребёнок',
              'sources': ['maciev'],
              'category': null,
            },
          ],
        }),
      };

      final words = parseBundledDictionaryIsolate(rawJson);

      expect(words.length, 1);
      expect(words[0].chechen, 'бер');
      expect(words[0].russian, 'Ребёнок');
      expect(words[0].sources, ['maciev']);
    });

    test('curated entries take priority (deduplication)', () {
      final rawJson = {
        'curated': jsonEncode({
          'entries': [
            {
              'chechen': 'дог',
              'russian': 'Сердце',
              'category': 'body',
              'emoji': '❤️',
            },
          ],
        }),
        'dictionary': jsonEncode({
          'entries': [
            {
              'chechen': 'дог',
              'russian': 'Сердце',
              'sources': ['maciev'],
            },
          ],
        }),
      };

      final words = parseBundledDictionaryIsolate(rawJson);

      // Same chechen|russian → same UUID v5 → deduped
      expect(words.length, 1);
      expect(words[0].emoji, '❤️'); // curated version kept
      expect(words[0].tags, ['verified']);
    });

    test('generates stable UUIDs', () {
      final rawJson = {
        'curated': jsonEncode({
          'entries': [
            {
              'chechen': 'нана',
              'russian': 'Мать',
              'category': 'family',
            },
          ],
        }),
        'dictionary': jsonEncode({'entries': []}),
      };

      final words1 = parseBundledDictionaryIsolate(rawJson);
      final words2 = parseBundledDictionaryIsolate(rawJson);

      expect(words1[0].id, words2[0].id); // same input → same ID
      expect(words1[0].id, isNotEmpty);
    });

    test('guesses part of speech from category', () {
      final rawJson = {
        'curated': jsonEncode({
          'entries': [
            {'chechen': 'дика', 'russian': 'Хороший', 'category': 'adjectives'},
            {'chechen': 'деша', 'russian': 'Читать', 'category': 'verbs'},
            {'chechen': 'ткъа', 'russian': 'Двадцать', 'category': 'numbers'},
            {'chechen': 'дег1', 'russian': 'Сердце', 'category': 'body'},
          ],
        }),
        'dictionary': jsonEncode({'entries': []}),
      };

      final words = parseBundledDictionaryIsolate(rawJson);

      expect(words[0].partOfSpeech, PartOfSpeech.adjective);
      expect(words[1].partOfSpeech, PartOfSpeech.verb);
      expect(words[2].partOfSpeech, PartOfSpeech.number);
      expect(words[3].partOfSpeech, PartOfSpeech.noun); // default
    });

    test('handles noun class', () {
      final rawJson = {
        'curated': jsonEncode({
          'entries': [
            {
              'chechen': 'бер',
              'russian': 'Ребёнок',
              'category': 'family',
              'nounClass': 'd',
            },
          ],
        }),
        'dictionary': jsonEncode({'entries': []}),
      };

      final words = parseBundledDictionaryIsolate(rawJson);
      expect(words[0].nounClass, NounClass.d);
    });
  });
}
