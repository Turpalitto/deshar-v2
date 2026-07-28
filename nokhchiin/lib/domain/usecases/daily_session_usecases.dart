import '../entities/daily_session_entity.dart';
import '../constants/gameplay_constants.dart';
import '../repositories/repositories.dart';

class RecordDailyTaskUseCase {
  RecordDailyTaskUseCase(this._repository);

  final DailySessionRepository _repository;

  Future<DailySessionEntity> call({
    required DateTime date,
    required String taskId,
    required List<String> selectedWordIds,
    int quizScore = 0,
    int quizTotal = 0,
    int reviewCount = 0,
    int minutesSpent = 0,
    required DateTime finishedAt,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing =
        await _repository.getForDate(normalizedDate) ??
        DailySessionEntity(date: normalizedDate);
    final isFirstCompletion = !existing.completedTaskIds.contains(taskId);
    final updated = existing.copyWith(
      selectedWordIds: {
        ...existing.selectedWordIds,
        ...selectedWordIds,
      }.toList(),
      completedTaskIds: {...existing.completedTaskIds, taskId}.toList(),
      quizScore: quizScore > existing.quizScore
          ? quizScore
          : existing.quizScore,
      quizTotal: quizTotal > existing.quizTotal
          ? quizTotal
          : existing.quizTotal,
      reviewCount: existing.reviewCount + (isFirstCompletion ? reviewCount : 0),
      minutesSpent:
          existing.minutesSpent +
          (isFirstCompletion
              ? minutesSpent.clamp(
                  0,
                  GameplayConstants.maximumRecordedSessionMinutes,
                )
              : 0),
      finishedAt: finishedAt,
    );
    await _repository.save(updated);
    return updated;
  }
}
