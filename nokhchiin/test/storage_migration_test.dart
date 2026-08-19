import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/data/repositories/daily_session_repository_impl.dart';
import 'package:nokhchiin/data/repositories/user_repository_impl.dart';
import 'package:nokhchiin/domain/entities/enums.dart';

void main() {
  late Directory hiveDirectory;
  late LocalUserDataSource userSource;
  late LocalDailySessionDataSource sessionSource;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'nokhchiin_migration_test_',
    );
    Hive.init(hiveDirectory.path);
    userSource = LocalUserDataSource();
    sessionSource = LocalDailySessionDataSource();
    await userSource.init();
    await sessionSource.init();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('legacy profile keeps progress and receives safe defaults', () async {
    await Hive.box<Map>(LocalUserDataSource.boxName).put('profile', {
      'mode': AppMode.kids.index,
      'ageGroup': KidsAgeGroup.age9to12.index,
      'xp': 480,
      'level': 5,
      'streakDays': 12,
      'stars': 40,
      'wordsLearnedToday': 7,
      'lastActiveDate': '2026-07-27',
      'weeklyXp': <int>[10, 20, 30, 40, 50, 60, 70],
      'unlockedWorlds': <String>['meadow', 'city'],
    });

    final profile = await UserRepositoryImpl(userSource).getProfile();

    expect(profile.xp, 480);
    expect(profile.level, 5);
    expect(profile.streakDays, 12);
    expect(profile.ageGroup, KidsAgeGroup.age9to12);
    expect(profile.unlockedWorlds, ['meadow', 'city']);
    expect(profile.coins, 40);
    expect(profile.lastKidsSessionRewardDate, isNull);
    expect(profile.notificationsEnabled, isFalse);
    expect(profile.chechenUiEnabled, isFalse);
    expect(profile.seenCultureCapsules, isEmpty);
  });

  test(
    'missing daily-session box starts empty without synthetic history',
    () async {
      final repository = DailySessionRepositoryImpl(sessionSource);

      expect(await repository.getRecent(), isEmpty);
      expect(await repository.getForDate(DateTime(2026, 7, 28)), isNull);
    },
  );

  test('older daily-session maps receive new score defaults', () async {
    await Hive.box<Map>(LocalDailySessionDataSource.boxName).put('2026-07-27', {
      'date': '2026-07-27T00:00:00.000',
      'selectedWordIds': <String>['w1', 'w2'],
      'completedTaskIds': <String>['new_words'],
      'minutesSpent': 3,
    });

    final session = await DailySessionRepositoryImpl(
      sessionSource,
    ).getForDate(DateTime(2026, 7, 27));

    expect(session, isNotNull);
    expect(session!.selectedWordIds, ['w1', 'w2']);
    expect(session.quizScore, 0);
    expect(session.quizTotal, 0);
    expect(session.reviewCount, 0);
    expect(session.finishedAt, isNull);
  });
}
