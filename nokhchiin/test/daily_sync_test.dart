import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/services/daily_sync_calculator.dart';

void main() {
  const calculator = DailySyncCalculator();

  UserProfileEntity profile({
    String? lastActiveDate,
    int streakDays = 0,
    List<int> weeklyXp = const [10, 20, 30, 40, 50, 60, 70],
    List<String> achievements = const [],
  }) {
    return UserProfileEntity(
      lastActiveDate: lastActiveDate,
      streakDays: streakDays,
      weeklyXp: weeklyXp,
      achievements: achievements,
    );
  }

  group('DailySyncCalculator', () {
    test('same day — profile unchanged', () {
      final now = DateTime(2026, 7, 2, 12);
      final p = profile(lastActiveDate: '2026-07-02', streakDays: 5);

      final result = calculator.sync(p, now);

      expect(identical(result, p), isTrue);
    });

    test('yesterday active — streak increments', () {
      final now = DateTime(2026, 7, 2, 9);
      final p = profile(lastActiveDate: '2026-07-01', streakDays: 4);

      final result = calculator.sync(p, now);

      expect(result.streakDays, 5);
      expect(result.lastActiveDate, '2026-07-02');
      expect(result.wordsLearnedToday, 0);
      expect(result.dailyGiftClaimed, isFalse);
    });

    test('skipped day — streak resets to 1', () {
      final now = DateTime(2026, 7, 2, 9);
      final p = profile(lastActiveDate: '2026-06-30', streakDays: 12);

      final result = calculator.sync(p, now);

      expect(result.streakDays, 1);
      expect(result.lastActiveDate, '2026-07-02');
    });

    test('new day — weeklyXp rotates (shift + trailing zero)', () {
      final now = DateTime(2026, 7, 2, 9);
      final p = profile(
        lastActiveDate: '2026-07-01',
        weeklyXp: const [1, 2, 3, 4, 5, 6, 7],
      );

      final result = calculator.sync(p, now);

      expect(result.weeklyXp, [2, 3, 4, 5, 6, 7, 0]);
    });

    test('weeklyXp padded when length is not 7', () {
      final now = DateTime(2026, 7, 2, 9);
      final p = profile(lastActiveDate: '2026-07-01', weeklyXp: const [5, 10]);

      final result = calculator.sync(p, now);

      expect(result.weeklyXp, List.filled(7, 0));
    });

    test('streak achievements added once', () {
      final now = DateTime(2026, 7, 8, 9);
      var p = profile(lastActiveDate: '2026-07-07', streakDays: 2);

      p = calculator.sync(p, now);
      expect(p.streakDays, 3);
      expect(p.achievements, contains('streak_3'));

      final again = calculator.sync(p, DateTime(2026, 7, 9));
      expect(again.achievements.where((a) => a == 'streak_3').length, 1);
    });

    test('streak_7 achievement when streak reaches 7', () {
      final now = DateTime(2026, 7, 8, 9);
      final p = profile(lastActiveDate: '2026-07-07', streakDays: 6);

      final result = calculator.sync(p, now);

      expect(result.streakDays, 7);
      expect(result.achievements, containsAll(['streak_3', 'streak_7']));
    });
  });
}
