import '../entities/word_progress_entity.dart';
import '../entities/enums.dart';

/// SM-2 интервальное повторение (упрощённая production-версия).
class SpacedRepetitionEngine {
  const SpacedRepetitionEngine();

  static const failedReviewDelay = Duration(minutes: 10);

  /// quality: 0–5 (0 = полный провал, 5 = идеально)
  /// [now] — текущее время; передаётся извне для тестируемости.
  WordProgressEntity review(
    WordProgressEntity current,
    int quality, {
    DateTime? now,
  }) {
    if (quality < 0 || quality > 5) {
      throw RangeError.range(quality, 0, 5, 'quality');
    }
    final timestamp = now ?? DateTime.now();
    var ease = current.easeFactor;
    var interval = current.intervalDays;
    var reps = current.repetitions;
    var mastery = current.mastery;
    var successfulDays = current.successfulReviewDays;
    var lastSuccessfulReviewAt = current.lastSuccessfulReviewAt;
    late final DateTime nextReviewAt;

    if (quality < 3) {
      reps = 0;
      interval = 0;
      ease = (ease - 0.2).clamp(1.3, 2.5);
      mastery = mastery.demote();
      if (mastery == MasteryLevel.unseen) mastery = MasteryLevel.seen;
      nextReviewAt = timestamp.add(failedReviewDelay);
    } else {
      if (lastSuccessfulReviewAt == null ||
          !_isSameCalendarDay(lastSuccessfulReviewAt, timestamp)) {
        successfulDays += 1;
      }
      lastSuccessfulReviewAt = timestamp;
      reps += 1;
      if (reps == 1) {
        interval = 1;
      } else if (reps == 2) {
        interval = 3;
      } else {
        interval = (interval * ease).round().clamp(1, 365);
      }
      ease = (ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
          .clamp(1.3, 2.5);
      mastery = _masteryFromQuality(quality, mastery, successfulDays);
      nextReviewAt = timestamp.add(Duration(days: interval));
    }

    return current.copyWith(
      easeFactor: ease,
      intervalDays: interval,
      repetitions: reps,
      nextReviewAt: nextReviewAt,
      lastReviewedAt: timestamp,
      lastSuccessfulReviewAt: lastSuccessfulReviewAt,
      successfulReviewDays: successfulDays,
      correctStreak: quality >= 3 ? current.correctStreak + 1 : 0,
      wrongCount: quality < 3 ? current.wrongCount + 1 : current.wrongCount,
      mastery: mastery,
    );
  }

  MasteryLevel _masteryFromQuality(
    int quality,
    MasteryLevel current,
    int successfulDays,
  ) {
    final ratingBoost = quality - 3;
    final dayTarget = successfulDays + ratingBoost;
    final nextLevel = current.value + 1;
    final targetValue = (dayTarget > nextLevel ? dayTarget : nextLevel).clamp(
      MasteryLevel.seen.value,
      MasteryLevel.mastered.value,
    );
    final target = MasteryLevel.fromValue(targetValue);

    if (target == MasteryLevel.mastered && successfulDays < 3) {
      return current.value > MasteryLevel.using.value
          ? current
          : MasteryLevel.using;
    }
    return current.value > target.value ? current : target;
  }

  bool _isSameCalendarDay(DateTime left, DateTime right) {
    final a = left.toLocal();
    final b = right.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Первое знакомство со словом.
  /// [now] — текущее время; передаётся извне для тестируемости.
  WordProgressEntity markSeen(WordProgressEntity current, {DateTime? now}) {
    if (current.mastery != MasteryLevel.unseen) return current;
    final timestamp = now ?? DateTime.now();
    return current.copyWith(
      mastery: MasteryLevel.seen,
      lastReviewedAt: timestamp,
      nextReviewAt: timestamp.add(const Duration(hours: 4)),
    );
  }
}
