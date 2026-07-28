import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/core/widgets/word_illustration.dart';
import 'package:nokhchiin/data/datasources/content_datasource.dart';
import 'package:nokhchiin/domain/entities/content_entities.dart';
import 'package:nokhchiin/features/stories/story_reader_screen.dart';

const _story = StoryEntity(
  id: 'family_dinner',
  titleRu: 'Семейный ужин',
  titleCe: 'Доьзалан кха',
  unitId: 'family',
  requiredMastery: 0,
  emoji: '🍲',
  panels: [
    StoryPanelEntity(
      imageKey: 'family_table',
      narrationRu: 'Семья собирается за столом.',
    ),
    StoryPanelEntity(
      imageKey: 'family_thanks',
      narrationRu: 'Дети благодарят маму.',
    ),
  ],
);

class _ContentSource extends ContentDataSource {
  @override
  Future<StoryEntity?> loadStory(String id) async =>
      id == _story.id ? _story : null;
}

void main() {
  testWidgets('story illustration follows each panel image key', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentSourceProvider.overrideWithValue(_ContentSource())],
        child: const MaterialApp(
          home: StoryReaderScreen(storyId: 'family_dinner'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var illustration = tester.widget<WordIllustration>(
      find.byType(WordIllustration),
    );
    expect(illustration.category, 'food');
    expect(illustration.emoji, '🍲');

    await tester.tap(find.text('Далее'));
    await tester.pump();

    illustration = tester.widget<WordIllustration>(
      find.byType(WordIllustration),
    );
    expect(illustration.category, 'family');
    expect(illustration.emoji, '🙏');
  });
}
