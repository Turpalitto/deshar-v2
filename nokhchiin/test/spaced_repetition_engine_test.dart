import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/services/spaced_repetition_engine.dart';

void main() {
  const engine = SpacedRepetitionEngine();

  group('SpacedRepetitionEngine', () {
    test('markSeen promotes unseen word to seen', () {
      const progress = WordProgressEntity(wordId: 'marshalla');
      final updated = engine.markSeen(progress);

      expect(updated.mastery, MasteryLevel.seen);
      expect(updated.nextReviewAt, isNotNull);
    });

    test('markSeen is idempotent for already seen words', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.recognizing,
      );
      final updated = engine.markSeen(progress);

      expect(updated.mastery, MasteryLevel.recognizing);
    });

    test('successful review increases repetitions and mastery', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.seen,
      );
      final updated = engine.review(progress, 4);

      expect(updated.repetitions, 1);
      expect(updated.intervalDays, 1);
      expect(updated.correctStreak, 1);
      expect(updated.mastery.value, greaterThanOrEqualTo(MasteryLevel.seen.value));
    });

    test('failed review resets interval and increments wrong count', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.remembering,
        repetitions: 3,
        intervalDays: 7,
        correctStreak: 2,
        easeFactor: 2.5,
      );
      final updated = engine.review(progress, 1);

      expect(updated.repetitions, 0);
      expect(updated.intervalDays, 1);
      expect(updated.correctStreak, 0);
      expect(updated.wrongCount, 1);
      expect(updated.easeFactor, closeTo(2.3, 0.001));
    });

    test('failed review clamps ease factor at minimum 1.3', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        easeFactor: 1.35,
      );
      final updated = engine.review(progress, 0);

      expect(updated.easeFactor, 1.3);
    });

    test('perfect review can reach mastered', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.using,
      );
      final updated = engine.review(progress, 5);

      expect(updated.mastery, MasteryLevel.mastered);
    });
  });
}
