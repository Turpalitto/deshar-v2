import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Прогресс по слову + данные интервального повторения (SRS).
class WordProgressEntity extends Equatable {
  const WordProgressEntity({
    required this.wordId,
    this.mastery = MasteryLevel.unseen,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.correctStreak = 0,
    this.wrongCount = 0,
    this.isFavorite = false,
  });

  final String wordId;
  final MasteryLevel mastery;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final int correctStreak;
  final int wrongCount;
  final bool isFavorite;

  bool get needsReview {
    if (nextReviewAt == null) return mastery != MasteryLevel.unseen;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  WordProgressEntity copyWith({
    MasteryLevel? mastery,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    int? correctStreak,
    int? wrongCount,
    bool? isFavorite,
  }) {
    return WordProgressEntity(
      wordId: wordId,
      mastery: mastery ?? this.mastery,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      correctStreak: correctStreak ?? this.correctStreak,
      wrongCount: wrongCount ?? this.wrongCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [wordId];
}
