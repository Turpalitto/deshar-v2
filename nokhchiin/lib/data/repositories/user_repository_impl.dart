import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_storage_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._local);

  final LocalUserDataSource _local;

  @override
  Future<UserProfileEntity> getProfile() async {
    final data = await _local.get();
    if (data == null) return const UserProfileEntity();
    return UserProfileEntity(
      mode: AppMode.values[data['mode'] as int? ?? 0],
      ageGroup: KidsAgeGroup.values[data['ageGroup'] as int? ?? 1],
      xp: data['xp'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      streakDays: data['streakDays'] as int? ?? 0,
      stars: data['stars'] as int? ?? 0,
      coins: data['coins'] as int? ?? data['stars'] as int? ?? 0,
      dailyGoalMinutes: data['dailyGoalMinutes'] as int? ?? 10,
      dailyGoalWords: data['dailyGoalWords'] as int? ?? 5,
      todayMinutes: data['todayMinutes'] as int? ?? 0,
      wordsLearnedToday: data['wordsLearnedToday'] as int? ?? 0,
      avatarId: data['avatarId'] as String? ?? 'fox_default',
      currentWorldId: data['currentWorldId'] as String? ?? 'meadow',
      unlockedWorlds:
          (data['unlockedWorlds'] as List?)?.cast<String>() ?? const ['meadow'],
      achievements:
          (data['achievements'] as List?)?.cast<String>() ?? const [],
      lastActiveDate: data['lastActiveDate'] as String?,
      dailyGiftClaimed: data['dailyGiftClaimed'] as bool? ?? false,
      weeklyXp: (data['weeklyXp'] as List?)?.cast<int>() ??
          const [0, 0, 0, 0, 0, 0, 0],
      isPremium: data['isPremium'] as bool? ?? false,
      lessonsCompletedTotal: data['lessonsCompletedTotal'] as int? ?? 0,
      reviewsDoneToday: data['reviewsDoneToday'] as int? ?? 0,
      seenCultureCapsules:
          (data['seenCultureCapsules'] as List?)?.cast<String>() ?? const [],
      hasCompletedOnboarding: data['hasCompletedOnboarding'] as bool? ?? false,
      streakFreezeCount: data['streakFreezeCount'] as int? ?? 0,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? false,
    );
  }

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    await _local.save({
      'mode': profile.mode.index,
      'ageGroup': profile.ageGroup.index,
      'xp': profile.xp,
      'level': profile.level,
      'streakDays': profile.streakDays,
      'stars': profile.stars,
      'coins': profile.coins,
      'dailyGoalMinutes': profile.dailyGoalMinutes,
      'dailyGoalWords': profile.dailyGoalWords,
      'todayMinutes': profile.todayMinutes,
      'wordsLearnedToday': profile.wordsLearnedToday,
      'avatarId': profile.avatarId,
      'currentWorldId': profile.currentWorldId,
      'unlockedWorlds': profile.unlockedWorlds,
      'achievements': profile.achievements,
      'lastActiveDate': profile.lastActiveDate,
      'dailyGiftClaimed': profile.dailyGiftClaimed,
      'weeklyXp': profile.weeklyXp,
      'isPremium': profile.isPremium,
      'lessonsCompletedTotal': profile.lessonsCompletedTotal,
      'reviewsDoneToday': profile.reviewsDoneToday,
      'seenCultureCapsules': profile.seenCultureCapsules,
      'hasCompletedOnboarding': profile.hasCompletedOnboarding,
      'streakFreezeCount': profile.streakFreezeCount,
      'notificationsEnabled': profile.notificationsEnabled,
    });
  }
}
