import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/data/datasources/dictionary_parser.dart';
import 'package:nokhchiin/data/datasources/dictionary_search_index.dart';

void main() {
  const parser = DictionaryParser();

  DictionarySearchIndex buildIndex() {
    final entries = [
      parser.parse({'chechen': 'Ӏаьржа', 'russian': 'чёрный'}),
      parser.parse({'chechen': 'нана', 'russian': 'мать'}),
    ];
    return DictionarySearchIndex(entries);
  }

  group('DictionarySearchIndex palochka normalization', () {
    test('finds a palochka word via the "1" ASCII substitute', () {
      final results = buildIndex().search('1аьржа');
      expect(results.map((e) => e.chechen), contains('Ӏаьржа'));
    });

    test('finds a palochka word via the Latin "I" substitute', () {
      final results = buildIndex().search('Iаьржа');
      expect(results.map((e) => e.chechen), contains('Ӏаьржа'));
    });

    test('finds a palochka word via the Latin "l" substitute', () {
      final results = buildIndex().search('lаьржа');
      expect(results.map((e) => e.chechen), contains('Ӏаьржа'));
    });

    test('still finds words via a plain Russian query', () {
      final results = buildIndex().search('мать');
      expect(results.map((e) => e.russian), contains('мать'));
    });

    test('returns no results for an unrelated query', () {
      expect(buildIndex().search('zzz'), isEmpty);
    });
  });
}
