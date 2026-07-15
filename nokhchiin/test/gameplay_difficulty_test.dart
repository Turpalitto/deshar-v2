import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/utils/gameplay_difficulty.dart';
import 'package:nokhchiin/domain/entities/enums.dart';

void main() {
  group('GameplayDifficulty', () {
    test('youngest kids get simplest exercises', () {
      expect(
        GameplayDifficulty.quizOptionCount(
          mode: AppMode.kids,
          age: KidsAgeGroup.age3to6,
        ),
        2,
      );
      expect(
        GameplayDifficulty.flashcardCount(
          mode: AppMode.kids,
          age: KidsAgeGroup.age3to6,
        ),
        4,
      );
      expect(
        GameplayDifficulty.showTyping(
          mode: AppMode.kids,
          age: KidsAgeGroup.age3to6,
        ),
        isFalse,
      );
    });

    test('adults get full difficulty', () {
      expect(
        GameplayDifficulty.quizOptionCount(
          mode: AppMode.adult,
          age: KidsAgeGroup.age9to12,
        ),
        4,
      );
      expect(
        GameplayDifficulty.showTyping(
          mode: AppMode.adult,
          age: KidsAgeGroup.age3to6,
        ),
        isTrue,
      );
    });

    test('placement scope by mode', () {
      expect(GameplayDifficulty.placementUnitLimit(mode: AppMode.kids), 3);
      expect(GameplayDifficulty.placementUnitLimit(mode: AppMode.adult), 2);
      expect(
        GameplayDifficulty.placementQuestionsPerUnit(mode: AppMode.kids),
        1,
      );
      expect(
        GameplayDifficulty.placementQuestionsPerUnit(mode: AppMode.adult),
        2,
      );
    });

    test('typing word count scales by age', () {
      expect(
        GameplayDifficulty.typingWordCount(
          mode: AppMode.kids,
          age: KidsAgeGroup.age3to6,
        ),
        3,
      );
      expect(
        GameplayDifficulty.typingWordCount(
          mode: AppMode.adult,
          age: KidsAgeGroup.age9to12,
        ),
        6,
      );
    });
  });
}
