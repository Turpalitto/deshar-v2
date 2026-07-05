import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/constants/gameplay_constants.dart';
import '../../domain/services/daily_sync_calculator.dart';
import 'repository_providers.dart';

/// Провайдер профиля пользователя.
/// Фаза 2: мигрирован `StateNotifier<AsyncValue<T>>` → `AsyncNotifier<T>`.
/// Все вызовы ref.read(userProfileProvider.notifier).someMethod() работают без изменений.

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileEntity>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfileEntity> {
  static const _dailySync = DailySyncCalculator();

  @override
  Future<UserProfileEntity> build() async {
    final repo = ref.watch(userRepoProvider);
    var profile = await repo.getProfile();
    profile = _dailySync.sync(profile, DateTime.now());
    await repo.saveProfile(profile);
    return profile;
  }

  // --- Вспомогательные геттеры ---

  UserRepository get _repo => ref.read(userRepoProvider);

  String _todayKey() => DailySyncCalculator.dateKey(DateTime.now());

  UserProfileEntity get _current => state.value ?? const UserProfileEntity();

  Future<void> _update(UserProfileEntity updated) async {
    await _repo.saveProfile(updated);
    state = AsyncData(updated);
  }

  // --- Публичные методы (совместимы с предыдущим API) ---

  Future<void> setMode(AppMode mode) =>
      _update(_current.copyWith(mode: mode));

  Future<void> setAgeGroup(KidsAgeGroup age) =>
      _update(_current.copyWith(ageGroup: age));

  Future<void> addXp(int xp, int stars) async {
    final current = _current;
    final newXp = current.xp + xp;
    final weekly = List<int>.from(current.weeklyXp);
    if (weekly.length == GameplayConstants.weeklyXpDays) weekly[6] += xp;
    await _update(current.copyWith(
      xp: newXp,
      level: (newXp / GameplayConstants.xpPerLevel).floor() + 1,
      stars: current.stars + stars,
      coins: current.coins + stars,
      weeklyXp: weekly,
    ));
  }

  Future<void> recordWordLearned({
    int xp = GameplayConstants.wordLearnedXp,
    int coins = GameplayConstants.wordLearnedCoins,
  }) async {
    final current = _current;
    final newXp = current.xp + xp;
    final weekly = List<int>.from(current.weeklyXp);
    if (weekly.length == GameplayConstants.weeklyXpDays) weekly[6] += xp;
    await _update(current.copyWith(
      xp: newXp,
      level: (newXp / GameplayConstants.xpPerLevel).floor() + 1,
      coins: current.coins + coins,
      stars: current.stars + coins,
      wordsLearnedToday: current.wordsLearnedToday + 1,
      weeklyXp: weekly,
      lastActiveDate: _todayKey(),
    ));
  }

  Future<void> claimDailyGift() async {
    if (_current.dailyGiftClaimed) return;
    await _update(_current.copyWith(
      dailyGiftClaimed: true,
      coins: _current.coins + GameplayConstants.dailyGiftCoins,
      xp: _current.xp + GameplayConstants.dailyGiftXp,
    ));
  }

  Future<void> setCurrentWorld(String worldId) =>
      _update(_current.copyWith(currentWorldId: worldId));

  Future<void> completeLesson() => completeLessonWithReward();

  Future<void> unlockAchievement(String id) async {
    if (_current.achievements.contains(id)) return;
    await _update(
        _current.copyWith(achievements: [..._current.achievements, id]));
  }

  Future<void> unlockWorld(String worldId) async {
    if (_current.unlockedWorlds.contains(worldId)) {
      await setCurrentWorld(worldId);
      return;
    }
    await _update(_current.copyWith(
      unlockedWorlds: [..._current.unlockedWorlds, worldId],
      currentWorldId: worldId,
    ));
  }

  Future<void> recordReview() => _update(
      _current.copyWith(reviewsDoneToday: _current.reviewsDoneToday + 1));

  Future<int> completeLessonWithReward() async {
    final total = _current.lessonsCompletedTotal + 1;
    await _update(_current.copyWith(lessonsCompletedTotal: total));
    return total;
  }

  Future<void> openLessonChest() => _update(_current.copyWith(
        coins: _current.coins + GameplayConstants.chestCoins,
        xp: _current.xp + GameplayConstants.chestXp,
      ));

  Future<void> setPremium(bool value) =>
      _update(_current.copyWith(isPremium: value));

  Future<void> completeOnboarding() =>
      _update(_current.copyWith(hasCompletedOnboarding: true));

  Future<void> markCultureCapsuleSeen(String capsuleId) async {
    if (_current.seenCultureCapsules.contains(capsuleId)) return;
    await _update(_current.copyWith(
        seenCultureCapsules: [..._current.seenCultureCapsules, capsuleId]));
  }

  /// Покупает заморозку стрика за монеты. Возвращает false без побочных
  /// эффектов, если не хватает монет или уже достигнут максимум.
  Future<bool> buyStreakFreeze() async {
    final current = _current;
    if (current.streakFreezeCount >= GameplayConstants.maxStreakFreezes) return false;
    if (current.coins < GameplayConstants.streakFreezeCoinCost) return false;
    await _update(current.copyWith(
      coins: current.coins - GameplayConstants.streakFreezeCoinCost,
      streakFreezeCount: current.streakFreezeCount + 1,
    ));
    return true;
  }
}
