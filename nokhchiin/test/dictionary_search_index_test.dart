import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/data/datasources/dictionary_parser.dart';
import 'package:nokhchiin/data/datasources/dictionary_search_index.dart';

void main() {
  test('indexed search accepts every palochka keyboard variant', () {
    final entry = const DictionaryParser().parse({
      'chechen': 'Ӏаьржа',
      'russian': 'Чёрный',
    });
    final index = DictionarySearchIndex([entry]);

    for (final query in ['Ӏаьржа', 'ӏаьржа', 'Iаьржа', '1аьржа']) {
      expect(index.search(query).map((item) => item.id), contains(entry.id));
    }
  });
}
