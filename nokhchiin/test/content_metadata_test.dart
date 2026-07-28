import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/content_metadata.dart';

void main() {
  test('learning JSON has explicit conservative review metadata', () {
    final lessons =
        jsonDecode(File('assets/data/lessons.json').readAsStringSync()) as List;
    final curated =
        (jsonDecode(
                  File(
                    'assets/data/curated_vocabulary.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['entries']
            as List;
    final entries = [
      for (final lesson in lessons)
        ...((lesson as Map<String, dynamic>)['words'] as List),
      ...curated,
    ];

    for (final raw in entries) {
      final entry = raw as Map<String, dynamic>;
      expect(
        ReviewStatus.fromJson(entry['reviewStatus']),
        isNot(ReviewStatus.draft),
        reason: '${entry['chechen']} must have an explicit checked source',
      );
      expect(entry['chechen'] as String, isNot(contains('\u04CF')));
      expect(
        FrequencyTier.fromJson(entry['frequencyTier']),
        isNotNull,
        reason: '${entry['chechen']} must have frequencyTier',
      );
    }
  });
}
