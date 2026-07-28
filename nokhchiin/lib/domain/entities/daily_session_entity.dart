import 'package:equatable/equatable.dart';

class DailySessionEntity extends Equatable {
  const DailySessionEntity({
    required this.date,
    this.selectedWordIds = const [],
    this.completedTaskIds = const [],
    this.quizScore = 0,
    this.quizTotal = 0,
    this.reviewCount = 0,
    this.minutesSpent = 0,
    this.finishedAt,
  });

  final DateTime date;
  final List<String> selectedWordIds;
  final List<String> completedTaskIds;
  final int quizScore;
  final int quizTotal;
  final int reviewCount;
  final int minutesSpent;
  final DateTime? finishedAt;

  DailySessionEntity copyWith({
    List<String>? selectedWordIds,
    List<String>? completedTaskIds,
    int? quizScore,
    int? quizTotal,
    int? reviewCount,
    int? minutesSpent,
    DateTime? finishedAt,
  }) {
    return DailySessionEntity(
      date: date,
      selectedWordIds: selectedWordIds ?? this.selectedWordIds,
      completedTaskIds: completedTaskIds ?? this.completedTaskIds,
      quizScore: quizScore ?? this.quizScore,
      quizTotal: quizTotal ?? this.quizTotal,
      reviewCount: reviewCount ?? this.reviewCount,
      minutesSpent: minutesSpent ?? this.minutesSpent,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  List<Object?> get props => [
    date,
    selectedWordIds,
    completedTaskIds,
    quizScore,
    quizTotal,
    reviewCount,
    minutesSpent,
    finishedAt,
  ];
}
