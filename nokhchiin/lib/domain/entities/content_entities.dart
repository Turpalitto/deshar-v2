import 'package:equatable/equatable.dart';

class WorldEntity extends Equatable {
  const WorldEntity({
    required this.id,
    required this.titleRu,
    required this.titleCe,
    required this.gradient,
    required this.unlockStars,
    required this.units,
    this.emoji,
    this.subtitleRu,
  });

  final String id;
  final String titleRu;
  final String titleCe;
  final String? emoji;
  final List<String> gradient;
  final int unlockStars;
  final List<String> units;
  final String? subtitleRu;

  @override
  List<Object?> get props => [id];
}

class CollectionEntity extends Equatable {
  const CollectionEntity({
    required this.id,
    required this.titleRu,
    required this.titleCe,
    required this.category,
    required this.totalCards,
    required this.rarity,
    this.icon,
  });

  final String id;
  final String titleRu;
  final String titleCe;
  final String? icon;
  final String category;
  final int totalCards;
  final String rarity;

  @override
  List<Object?> get props => [id];
}

class ChestEntity extends Equatable {
  const ChestEntity({
    required this.id,
    required this.titleRu,
    required this.starsRequired,
    required this.cooldownHours,
  });

  final String id;
  final String titleRu;
  final int starsRequired;
  final int cooldownHours;

  @override
  List<Object?> get props => [id];
}

class StoryDialogueLine extends Equatable {
  const StoryDialogueLine({
    required this.speaker,
    required this.chechen,
    required this.russian,
  });

  final String speaker;
  final String chechen;
  final String russian;

  @override
  List<Object?> get props => [speaker, chechen, russian];
}

class StoryPanelEntity extends Equatable {
  const StoryPanelEntity({
    required this.imageKey,
    required this.narrationRu,
    this.dialogue = const [],
  });

  final String imageKey;
  final String narrationRu;
  final List<StoryDialogueLine> dialogue;

  @override
  List<Object?> get props => [imageKey];
}

class StoryQuizEntity extends Equatable {
  const StoryQuizEntity({
    required this.question,
    required this.answer,
    required this.options,
  });

  final String question;
  final String answer;
  final List<String> options;

  @override
  List<Object?> get props => [question];
}

class StoryEntity extends Equatable {
  const StoryEntity({
    required this.id,
    required this.titleRu,
    required this.titleCe,
    required this.unitId,
    required this.requiredMastery,
    this.emoji,
    this.panels = const [],
    this.quiz = const [],
  });

  final String id;
  final String titleRu;
  final String titleCe;
  final String unitId;
  final int requiredMastery;
  final String? emoji;
  final List<StoryPanelEntity> panels;
  final List<StoryQuizEntity> quiz;

  @override
  List<Object?> get props => [id];
}

class BossEntity extends Equatable {
  const BossEntity({
    required this.id,
    required this.unitId,
    required this.titleRu,
    required this.titleCe,
    required this.questionsCount,
    required this.timeLimitSec,
    required this.passScore,
    required this.rewardStars,
    required this.rewardXp,
    this.emoji,
  });

  final String id;
  final String unitId;
  final String titleRu;
  final String titleCe;
  final String? emoji;
  final int questionsCount;
  final int timeLimitSec;
  final int passScore;
  final int rewardStars;
  final int rewardXp;

  @override
  List<Object?> get props => [id];
}
