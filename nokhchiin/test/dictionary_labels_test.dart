import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/utils/dictionary_labels.dart';

void main() {
  test('dictionary sources are presented with user-facing labels', () {
    expect(
      DictionaryLabels.sourcesLabel(const ['lessons', 'curated']),
      'Учебная программа · Учебная подборка',
    );
    expect(DictionaryLabels.sourcesLabel(const ['unknown']), 'Словарная база');
  });
}
