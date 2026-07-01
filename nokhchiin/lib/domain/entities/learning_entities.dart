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
    this.dailyGoalMinutes = 10,
    this.todayMinutes = 0,
    this.avatarId = 'fox_default',
    this.unlockedWorlds = const ['meadow'],
    this.achievements = const [],
  });

  final AppMode mode;
  final KidsAgeGroup ageGroup;
  final int xp;
  final int level;
  final int streakDays;
  final int stars;
  final int dailyGoalMinutes;
  final int todayMinutes;
  final String avatarId;
  final List<String> unlockedWorlds;
  final List<String> achievements;

  UserProfileEntity copyWith({
    AppMode? mode,
    KidsAgeGroup? ageGroup,
    int? xp,
    int? level,
    int? streakDays,
    int? stars,
    int? dailyGoalMinutes,
    int? todayMinutes,
    String? avatarId,
  }) {
    return UserProfileEntity(
      mode: mode ?? this.mode,
      ageGroup: ageGroup ?? this.ageGroup,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      stars: stars ?? this.stars,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      avatarId: avatarId ?? this.avatarId,
      unlockedWorlds: unlockedWorlds,
      achievements: achievements,
    );
  }

  @override
  List<Object?> get props => [mode, xp, level];
}
