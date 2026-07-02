import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/constants/gameplay_constants.dart';

void main() {
  group('UserProfileEntity', () {
    test('default values are correct', () {
      const profile = UserProfileEntity();

      expect(profile.mode, AppMode.kids);
      expect(profile.ageGroup, KidsAgeGroup.age6to9);
      expect(profile.xp, 0);
      expect(profile.level, 1);
      expect(profile.streakDays, 0);
      expect(profile.stars, 0);
      expect(profile.coins, 0);
      expect(profile.isPremium, false);
      expect(profile.wordsLearnedToday, 0);
      expect(profile.weeklyXp.length, 7);
      expect(profile.achievements, isEmpty);
      expect(profile.unlockedWorlds, ['meadow']);
    });

    test('copyWith preserves unchanged fields', () {
      const profile = UserProfileEntity(
        xp: 100,
        level: 2,
        coins: 50,
        stars: 10,
        isPremium: true,
      );

      final updated = profile.copyWith(coins: 75);

      expect(updated.xp, 100);
      expect(updated.level, 2);
      expect(updated.coins, 75);
      expect(updated.stars, 10);
      expect(updated.isPremium, true);
    });

    test('dailyGoalProgress calculates correctly', () {
      const profile = UserProfileEntity(
        dailyGoalWords: 10,
        wordsLearnedToday: 5,
      );

      expect(profile.dailyGoalProgress, 50);
    });

    test('dailyGoalProgress clamps at 100', () {
      const profile = UserProfileEntity(
        dailyGoalWords: 5,
        wordsLearnedToday: 10,
      );

      expect(profile.dailyGoalProgress, 100);
    });

    test('dailyGoalProgress returns 0 when goal is 0', () {
      const profile = UserProfileEntity(
        dailyGoalWords: 0,
        wordsLearnedToday: 5,
      );

      expect(profile.dailyGoalProgress, 0);
    });

    test('Equatable compares ALL fields (regression test for props)', () {
      const a = UserProfileEntity(coins: 10);
      const b = UserProfileEntity(coins: 20);
      const c = UserProfileEntity(coins: 10);

      expect(a, isNot(equals(b)));
      expect(a, equals(c));
    });

    test('Equatable detects changes in every field', () {
      const base = UserProfileEntity();

      // Each field change should produce a non-equal entity
      expect(base, isNot(equals(base.copyWith(mode: AppMode.adult))));
      expect(base, isNot(equals(base.copyWith(ageGroup: KidsAgeGroup.age3to6))));
      expect(base, isNot(equals(base.copyWith(xp: 1))));
      expect(base, isNot(equals(base.copyWith(level: 2))));
      expect(base, isNot(equals(base.copyWith(streakDays: 1))));
      expect(base, isNot(equals(base.copyWith(stars: 1))));
      expect(base, isNot(equals(base.copyWith(coins: 1))));
      expect(base, isNot(equals(base.copyWith(dailyGoalMinutes: 99))));
      expect(base, isNot(equals(base.copyWith(dailyGoalWords: 99))));
      expect(base, isNot(equals(base.copyWith(todayMinutes: 1))));
      expect(base, isNot(equals(base.copyWith(wordsLearnedToday: 1))));
      expect(base, isNot(equals(base.copyWith(avatarId: 'other'))));
      expect(base, isNot(equals(base.copyWith(currentWorldId: 'forest'))));
      expect(base, isNot(equals(base.copyWith(isPremium: true))));
      expect(base, isNot(equals(base.copyWith(lessonsCompletedTotal: 1))));
      expect(base, isNot(equals(base.copyWith(reviewsDoneToday: 1))));
      expect(base, isNot(equals(base.copyWith(dailyGiftClaimed: true))));
    });
  });

  group('GameplayConstants', () {
    test('XP per level is positive', () {
      expect(GameplayConstants.xpPerLevel, greaterThan(0));
    });

    test('weekly XP days is 7', () {
      expect(GameplayConstants.weeklyXpDays, 7);
    });

    test('reward values are positive', () {
      expect(GameplayConstants.wordLearnedXp, greaterThan(0));
      expect(GameplayConstants.wordLearnedCoins, greaterThan(0));
      expect(GameplayConstants.dailyGiftCoins, greaterThan(0));
      expect(GameplayConstants.dailyGiftXp, greaterThan(0));
      expect(GameplayConstants.chestCoins, greaterThan(0));
      expect(GameplayConstants.chestXp, greaterThan(0));
    });
  });
}
