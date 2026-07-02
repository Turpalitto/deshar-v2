import '../entities/word_progress_entity.dart';
import '../entities/enums.dart';

/// SM-2 интервальное повторение (упрощённая production-версия).
class SpacedRepetitionEngine {
  const SpacedRepetitionEngine();

  /// quality: 0–5 (0 = полный провал, 5 = идеально)
  /// [now] — текущее время; передаётся извне для тестируемости.
  WordProgressEntity review(WordProgressEntity current, int quality, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    var ease = current.easeFactor;
    var interval = current.intervalDays;
    var reps = current.repetitions;
    var mastery = current.mastery;

    if (quality < 3) {
      reps = 0;
      interval = 1;
      ease = (ease - 0.2).clamp(1.3, 2.5);
      mastery = mastery.demote();
      if (mastery == MasteryLevel.unseen) mastery = MasteryLevel.seen;
    } else {
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
      mastery = _masteryFromQuality(quality, mastery);
    }

    return current.copyWith(
      easeFactor: ease,
      intervalDays: interval,
      repetitions: reps,
      nextReviewAt: timestamp.add(Duration(days: interval)),
      lastReviewedAt: timestamp,
      correctStreak: quality >= 3 ? current.correctStreak + 1 : 0,
      wrongCount: quality < 3 ? current.wrongCount + 1 : current.wrongCount,
      mastery: mastery,
    );
  }

  MasteryLevel _masteryFromQuality(int quality, MasteryLevel current) {
    if (quality >= 5) return MasteryLevel.mastered;
    if (quality >= 4) return current.value < MasteryLevel.using.value
        ? MasteryLevel.using
        : current;
    if (quality >= 3) {
      if (current == MasteryLevel.unseen) return MasteryLevel.seen;
      if (current == MasteryLevel.seen) return MasteryLevel.recognizing;
      if (current == MasteryLevel.recognizing) return MasteryLevel.remembering;
      return current;
    }
    return current;
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

