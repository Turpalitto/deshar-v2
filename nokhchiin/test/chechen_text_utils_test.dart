import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/utils/chechen_text_utils.dart';

void main() {
  group('ChechenTextUtils', () {
    test('normalizes palochka aliases to CYRILLIC PALOCHKA', () {
      expect(ChechenTextUtils.normalizeForSearch('1аьржа'), ChechenTextUtils.normalizeForSearch('Ӏаьржа'));
      expect(ChechenTextUtils.normalizeForSearch('Iаьржа'), ChechenTextUtils.normalizeForSearch('Ӏаьржа'));
      expect(ChechenTextUtils.normalizeForSearch('lаьржа'), ChechenTextUtils.normalizeForSearch('Ӏаьржа'));
    });

    test('matchesWordQuery finds words with mixed palochka input', () {
      expect(
        ChechenTextUtils.matchesWordQuery(
          query: '1аьржа',
          chechen: 'Ӏаьржа',
          russian: 'весна',
        ),
        isTrue,
      );
      expect(
        ChechenTextUtils.matchesWordQuery(
          query: 'весна',
          chechen: 'Ӏаьржа',
          russian: 'весна',
        ),
        isTrue,
      );
    });
  });
}
