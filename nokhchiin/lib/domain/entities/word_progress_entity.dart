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
    this.lastSuccessfulReviewAt,
    this.successfulReviewDays = 0,
    this.correctStreak = 0,
    this.wrongCount = 0,
    this.isFavorite = false,
    this.seededFromPlacement = false,
    this.deckIds = const {},
  });

  final String wordId;
  final MasteryLevel mastery;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final DateTime? lastSuccessfulReviewAt;
  final int successfulReviewDays;
  final int correctStreak;
  final int wrongCount;
  final bool isFavorite;

  /// true — слово засчитано освоенным через placement-тест при онбординге
  /// (см. `SeedUnitMasteryFromPlacementUseCase`), а не через реальную
  /// практику в приложении. Используется, чтобы статистика прогресса не
  /// путала «уже знал» с «выучил здесь» — но НЕ влияет на mastery-проценты
  /// юнитов/разблокировку, где placement-слова обязаны учитываться как
  /// освоенные.
  final bool seededFromPlacement;
  final Set<String> deckIds;

  bool needsReviewAt(DateTime now) {
    final dueAt = nextReviewAt;
    if (dueAt == null) return false;
    return !dueAt.isAfter(now);
  }

  bool get needsReview => needsReviewAt(DateTime.now());

  WordProgressEntity copyWith({
    MasteryLevel? mastery,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    DateTime? lastSuccessfulReviewAt,
    int? successfulReviewDays,
    int? correctStreak,
    int? wrongCount,
    bool? isFavorite,
    bool? seededFromPlacement,
    Set<String>? deckIds,
  }) {
    return WordProgressEntity(
      wordId: wordId,
      mastery: mastery ?? this.mastery,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      lastSuccessfulReviewAt:
          lastSuccessfulReviewAt ?? this.lastSuccessfulReviewAt,
      successfulReviewDays: successfulReviewDays ?? this.successfulReviewDays,
      correctStreak: correctStreak ?? this.correctStreak,
      wrongCount: wrongCount ?? this.wrongCount,
      isFavorite: isFavorite ?? this.isFavorite,
      seededFromPlacement: seededFromPlacement ?? this.seededFromPlacement,
      deckIds: deckIds ?? this.deckIds,
    );
  }

  @override
  List<Object?> get props => [
    wordId,
    mastery,
    easeFactor,
    intervalDays,
    repetitions,
    nextReviewAt,
    lastReviewedAt,
    lastSuccessfulReviewAt,
    successfulReviewDays,
    correctStreak,
    wrongCount,
    isFavorite,
    seededFromPlacement,
    deckIds,
  ];
}
