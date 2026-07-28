import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/services/spaced_repetition_engine.dart';

void main() {
  const engine = SpacedRepetitionEngine();

  group('SpacedRepetitionEngine', () {
    test('markSeen promotes unseen word to seen', () {
      const progress = WordProgressEntity(wordId: 'marshalla');
      final now = DateTime(2026, 7, 28, 9);
      final updated = engine.markSeen(progress, now: now);

      expect(updated.mastery, MasteryLevel.seen);
      expect(updated.nextReviewAt, now.add(const Duration(hours: 4)));
    });

    test('markSeen is idempotent for already seen words', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.recognizing,
      );
      final updated = engine.markSeen(progress, now: DateTime(2026, 7, 28, 9));

      expect(updated.mastery, MasteryLevel.recognizing);
    });

    test('successful review increases repetitions and mastery', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.seen,
      );
      final now = DateTime(2026, 7, 28, 9);
      final updated = engine.review(progress, 4, now: now);

      expect(updated.repetitions, 1);
      expect(updated.intervalDays, 1);
      expect(updated.correctStreak, 1);
      expect(updated.successfulReviewDays, 1);
      expect(updated.mastery, MasteryLevel.recognizing);
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
      final now = DateTime(2026, 7, 28, 9);
      final updated = engine.review(progress, 1, now: now);

      expect(updated.repetitions, 0);
      expect(updated.intervalDays, 0);
      expect(updated.correctStreak, 0);
      expect(updated.wrongCount, 1);
      expect(updated.easeFactor, closeTo(2.3, 0.001));
      expect(
        updated.nextReviewAt,
        now.add(SpacedRepetitionEngine.failedReviewDelay),
      );
    });

    test('failed review clamps ease factor at minimum 1.3', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        easeFactor: 1.35,
      );
      final updated = engine.review(progress, 0, now: DateTime(2026, 7, 28, 9));

      expect(updated.easeFactor, 1.3);
    });

    test('perfect first review does not reach mastered', () {
      const progress = WordProgressEntity(wordId: 'marshalla');
      final updated = engine.review(progress, 5, now: DateTime(2026, 7, 28, 9));

      expect(updated.mastery, isNot(MasteryLevel.mastered));
      expect(updated.mastery, MasteryLevel.remembering);
      expect(updated.successfulReviewDays, 1);
    });

    // Аудит §low: раньше не проверялись ни рост интервала при
    // repetitions>=3, ни граница quality=2/3 — важнейшая граница алгоритма.
    test(
      'interval grows via ease-factor multiplication once repetitions >= 3',
      () {
        const progress = WordProgressEntity(
          wordId: 'marshalla',
          mastery: MasteryLevel.recognizing,
          repetitions: 2,
          intervalDays: 3,
          easeFactor: 2.5,
        );
        final updated = engine.review(
          progress,
          4,
          now: DateTime(2026, 7, 28, 9),
        );

        expect(updated.repetitions, 3);
        expect(updated.intervalDays, (3 * 2.5).round());
      },
    );

    test('quality=2 is a fail — resets repetitions and demotes mastery', () {
      const progress = WordProgressEntity(
        wordId: 'marshalla',
        mastery: MasteryLevel.remembering,
        repetitions: 4,
        intervalDays: 10,
        correctStreak: 3,
      );
      final updated = engine.review(progress, 2, now: DateTime(2026, 7, 28, 9));

      expect(updated.repetitions, 0);
      expect(updated.intervalDays, 0);
      expect(updated.correctStreak, 0);
      expect(updated.wrongCount, 1);
      expect(updated.mastery, MasteryLevel.recognizing);
    });

    test(
      'quality=3 is a pass — increments repetitions and promotes mastery',
      () {
        const progress = WordProgressEntity(
          wordId: 'marshalla',
          mastery: MasteryLevel.seen,
        );
        final updated = engine.review(
          progress,
          3,
          now: DateTime(2026, 7, 28, 9),
        );

        expect(updated.repetitions, 1);
        expect(updated.intervalDays, 1);
        expect(updated.correctStreak, 1);
        expect(updated.wrongCount, 0);
        expect(updated.mastery, MasteryLevel.recognizing);
      },
    );

    test('repeated failure remains scheduled for a short retry', () {
      final first = engine.review(
        const WordProgressEntity(wordId: 'marshalla'),
        1,
        now: DateTime(2026, 7, 28, 9),
      );
      final secondNow = DateTime(2026, 7, 28, 9, 10);
      final second = engine.review(first, 1, now: secondNow);

      expect(second.repetitions, 0);
      expect(second.wrongCount, 2);
      expect(
        second.nextReviewAt,
        secondNow.add(SpacedRepetitionEngine.failedReviewDelay),
      );
    });

    test('mastered requires successful reviews on different days', () {
      var progress = const WordProgressEntity(wordId: 'marshalla');

      progress = engine.review(progress, 5, now: DateTime(2026, 7, 28, 9));
      progress = engine.review(progress, 5, now: DateTime(2026, 7, 28, 18));
      expect(progress.successfulReviewDays, 1);
      expect(progress.mastery, isNot(MasteryLevel.mastered));

      progress = engine.review(progress, 5, now: DateTime(2026, 7, 29, 9));
      expect(progress.successfulReviewDays, 2);
      expect(progress.mastery, MasteryLevel.using);

      progress = engine.review(progress, 5, now: DateTime(2026, 7, 30, 9));
      expect(progress.successfulReviewDays, 3);
      expect(progress.mastery, MasteryLevel.mastered);
    });
  });
}
