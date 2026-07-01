import 'package:equatable/equatable.dart';
import 'enums.dart';

class LearningUnitEntity extends Equatable {
  const LearningUnitEntity({
    required this.id,
    required this.order,
    required this.titleRu,
    required this.titleCe,
    required this.icon,
    required this.requiredMastery,
    this.wordIds = const [],
    this.isUnlocked = false,
    this.masteryPercent = 0,
  });

  final String id;
  final int order;
  final String titleRu;
  final String titleCe;
  final String icon;
  final int requiredMastery;
  final List<String> wordIds;
  final bool isUnlocked;
  final int masteryPercent;

  @override
  List<Object?> get props => [id];
}

class LessonEntity extends Equatable {
  const LessonEntity({
    required this.id,
    required this.title,
    required this.chechenTitle,
    required this.wordIds,
    this.icon = '📖',
    this.colorHex = '#1A73E8',
  });

  final String id;
  final String title;
  final String chechenTitle;
  final List<String> wordIds;
  final String icon;
  final String colorHex;

  @override
  List<Object?> get props => [id];
}

class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    this.mode = AppMode.kids,
    this.ageGroup = KidsAgeGroup.age6to9,
    this.xp = 0,
    this.level = 1,
    this.streakDays = 0,
    this.stars = 0,
    this.coins = 0,
    this.dailyGoalMinutes = 10,
    this.dailyGoalWords = 5,
    this.todayMinutes = 0,
    this.wordsLearnedToday = 0,
    this.avatarId = 'fox_default',
    this.currentWorldId = 'meadow',
    this.unlockedWorlds = const ['meadow'],
    this.achievements = const [],
    this.lastActiveDate,
    this.dailyGiftClaimed = false,
    this.weeklyXp = const [0, 0, 0, 0, 0, 0, 0],
    this.isPremium = false,
    this.lessonsCompletedTotal = 0,
    this.reviewsDoneToday = 0,
    this.seenCultureCapsules = const [],
  });

  final AppMode mode;
  final KidsAgeGroup ageGroup;
  final int xp;
  final int level;
  final int streakDays;
  final int stars;
  final int coins;
  final int dailyGoalMinutes;
  final int dailyGoalWords;
  final int todayMinutes;
  final int wordsLearnedToday;
  final String avatarId;
  final String currentWorldId;
  final List<String> unlockedWorlds;
  final List<String> achievements;
  final String? lastActiveDate;
  final bool dailyGiftClaimed;
  final List<int> weeklyXp;
  final bool isPremium;
  final int lessonsCompletedTotal;
  final int reviewsDoneToday;
  final List<String> seenCultureCapsules;

  int get dailyGoalProgress =>
      dailyGoalWords > 0 ? (wordsLearnedToday / dailyGoalWords * 100).round().clamp(0, 100) : 0;

  UserProfileEntity copyWith({
    AppMode? mode,
    KidsAgeGroup? ageGroup,
    int? xp,
    int? level,
    int? streakDays,
    int? stars,
    int? coins,
    int? dailyGoalMinutes,
    int? dailyGoalWords,
    int? todayMinutes,
    int? wordsLearnedToday,
    String? avatarId,
    String? currentWorldId,
    List<String>? unlockedWorlds,
    List<String>? achievements,
    String? lastActiveDate,
    bool? dailyGiftClaimed,
    List<int>? weeklyXp,
    bool? isPremium,
    int? lessonsCompletedTotal,
    int? reviewsDoneToday,
    List<String>? seenCultureCapsules,
  }) {
    return UserProfileEntity(
      mode: mode ?? this.mode,
      ageGroup: ageGroup ?? this.ageGroup,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      stars: stars ?? this.stars,
      coins: coins ?? this.coins,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      dailyGoalWords: dailyGoalWords ?? this.dailyGoalWords,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      wordsLearnedToday: wordsLearnedToday ?? this.wordsLearnedToday,
      avatarId: avatarId ?? this.avatarId,
      currentWorldId: currentWorldId ?? this.currentWorldId,
      unlockedWorlds: unlockedWorlds ?? this.unlockedWorlds,
      achievements: achievements ?? this.achievements,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyGiftClaimed: dailyGiftClaimed ?? this.dailyGiftClaimed,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      isPremium: isPremium ?? this.isPremium,
      lessonsCompletedTotal: lessonsCompletedTotal ?? this.lessonsCompletedTotal,
      reviewsDoneToday: reviewsDoneToday ?? this.reviewsDoneToday,
      seenCultureCapsules: seenCultureCapsules ?? this.seenCultureCapsules,
    );
  }

  @override
  List<Object?> get props => [mode, xp, level, streakDays];
}
