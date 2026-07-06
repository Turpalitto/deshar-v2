import '../../domain/entities/learning_entities.dart';

/// Чистая логика ежедневной синхронизации профиля (стрик, weeklyXp, достижения).
class DailySyncCalculator {
  const DailySyncCalculator();

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  UserProfileEntity sync(UserProfileEntity profile, DateTime now) {
    final today = dateKey(now);
    if (profile.lastActiveDate == today) return profile;

    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    final twoDaysAgo = dateKey(now.subtract(const Duration(days: 2)));

    int streak;
    var freezeCount = profile.streakFreezeCount;
    if (profile.lastActiveDate == yesterday) {
      streak = profile.streakDays + 1;
    } else if (profile.lastActiveDate == twoDaysAgo && profile.streakFreezeCount > 0) {
      // Пропущен ровно один день, есть заморозка — тратим её, стрик не рвётся.
      streak = profile.streakDays + 1;
      freezeCount = profile.streakFreezeCount - 1;
    } else {
      streak = 1;
    }

    final weekly = List<int>.from(profile.weeklyXp);
    if (weekly.length != 7) {
      weekly
        ..clear()
        ..addAll(List.filled(7, 0));
    } else {
      // Сдвигаем окно на число пропущенных дней (заполняем нулями),
      // а не всегда на 1 — раньше пропуск >1 дня оставлял устаревшие
      // значения в weeklyXp (аудит daily_sync).
      final lastActive = profile.lastActiveDate != null
          ? DateTime.parse('${profile.lastActiveDate}T00:00:00')
          : now;
      var days = now.difference(lastActive).inDays;
      if (days < 1) days = 1;
      if (days > 7) days = 7;      for (var i = 0; i < days; i++) {
        weekly.removeAt(0);
        weekly.add(0);
      }
    }

    var achievements = List<String>.from(profile.achievements);
    if (streak >= 3 && !achievements.contains('streak_3')) achievements.add('streak_3');
    if (streak >= 7 && !achievements.contains('streak_7')) achievements.add('streak_7');

    return profile.copyWith(
      lastActiveDate: today,
      streakDays: streak,
      wordsLearnedToday: 0,
      todayMinutes: 0,
      dailyGiftClaimed: false,
      reviewsDoneToday: 0,
      weeklyXp: weekly,
      achievements: achievements,
      streakFreezeCount: freezeCount,
    );
  }
}
