import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/daily_session_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/domain/usecases/daily_session_usecases.dart';

class _Repository implements DailySessionRepository {
  DailySessionEntity? value;

  @override
  Future<DailySessionEntity?> getForDate(DateTime date) async => value;

  @override
  Future<List<DailySessionEntity>> getRecent({int limit = 7}) async =>
      value == null ? [] : [value!];

  @override
  Future<void> save(DailySessionEntity session) async {
    value = session;
  }
}

void main() {
  test('merges completed daily tasks into a real session history', () async {
    final repository = _Repository();
    final useCase = RecordDailyTaskUseCase(repository);
    final date = DateTime(2026, 7, 28, 9);

    await useCase(
      date: date,
      taskId: 'new_words',
      selectedWordIds: const ['w1', 'w2'],
      minutesSpent: 3,
      finishedAt: DateTime(2026, 7, 28, 9, 3),
    );
    final result = await useCase(
      date: date,
      taskId: 'quiz',
      selectedWordIds: const ['w2', 'w3'],
      quizScore: 4,
      quizTotal: 5,
      minutesSpent: 2,
      finishedAt: DateTime(2026, 7, 28, 9, 5),
    );

    expect(result.date, DateTime(2026, 7, 28));
    expect(result.selectedWordIds, ['w1', 'w2', 'w3']);
    expect(result.completedTaskIds, ['new_words', 'quiz']);
    expect(result.quizScore, 4);
    expect(result.quizTotal, 5);
    expect(result.minutesSpent, 5);
  });

  test('retrying the same task does not double-count time', () async {
    final repository = _Repository();
    final useCase = RecordDailyTaskUseCase(repository);
    final date = DateTime(2026, 7, 28);

    await useCase(
      date: date,
      taskId: 'quiz',
      selectedWordIds: const ['w1'],
      quizScore: 2,
      quizTotal: 5,
      minutesSpent: 4,
      finishedAt: DateTime(2026, 7, 28, 10),
    );
    final result = await useCase(
      date: date,
      taskId: 'quiz',
      selectedWordIds: const ['w1'],
      quizScore: 5,
      quizTotal: 5,
      minutesSpent: 4,
      finishedAt: DateTime(2026, 7, 28, 10, 4),
    );

    expect(result.completedTaskIds, ['quiz']);
    expect(result.minutesSpent, 4);
    expect(result.quizScore, 5);
  });
}
