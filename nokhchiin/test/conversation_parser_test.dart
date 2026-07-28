import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/data/datasources/content_parser.dart';
import 'package:nokhchiin/domain/entities/conversation_entities.dart';

void main() {
  test('conversation infrastructure exposes all requested categories', () {
    final categories = parseConversationCategories(
      File('assets/data/conversation_categories.json').readAsStringSync(),
    );

    expect(categories, hasLength(13));
    expect(categories.map((item) => item.id), contains('introductions'));
    expect(categories.map((item) => item.id), contains('with_child'));
    expect(categories.map((item) => item.id), contains('elders'));
    expect(
      categories
          .where((item) => item.enabled)
          .every((item) => item.entries.isNotEmpty),
      isTrue,
    );
    expect(VocabularyQuizType.values, hasLength(9));
    expect(
      categories.first.entries.first.quizTypes,
      contains(VocabularyQuizType.chooseReply),
    );
  });
}
