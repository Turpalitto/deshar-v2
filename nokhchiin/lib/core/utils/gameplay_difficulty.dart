import '../../domain/entities/enums.dart';

/// Параметры упражнений по режиму и возрасту — дети 3–6 проще, 9–12 ближе к взрослым.
abstract final class GameplayDifficulty {
  static int flashcardCount({
    required AppMode mode,
    required KidsAgeGroup age,
  }) {
    if (mode == AppMode.adult) return 8;
    return switch (age) {
      KidsAgeGroup.age3to6 => 4,
      KidsAgeGroup.age6to9 => 6,
      KidsAgeGroup.age9to12 => 8,
    };
  }

  static int matchPairCount({
    required AppMode mode,
    required KidsAgeGroup age,
  }) {
    if (mode == AppMode.adult) return 5;
    return switch (age) {
      KidsAgeGroup.age3to6 => 3,
      KidsAgeGroup.age6to9 => 4,
      KidsAgeGroup.age9to12 => 5,
    };
  }

  /// Сколько вариантов ответа в квизе (включая правильный).
  static int quizOptionCount({
    required AppMode mode,
    required KidsAgeGroup age,
  }) {
    if (mode == AppMode.adult) return 4;
    return switch (age) {
      KidsAgeGroup.age3to6 => 2,
      KidsAgeGroup.age6to9 => 3,
      KidsAgeGroup.age9to12 => 4,
    };
  }

  static int lessonQuizQuestions({
    required AppMode mode,
    required KidsAgeGroup age,
  }) {
    if (mode == AppMode.adult) return 5;
    return switch (age) {
      KidsAgeGroup.age3to6 => 3,
      KidsAgeGroup.age6to9 => 4,
      KidsAgeGroup.age9to12 => 5,
    };
  }

  static bool showTyping({required AppMode mode, required KidsAgeGroup age}) {
    if (mode == AppMode.adult) return true;
    return age == KidsAgeGroup.age9to12;
  }

  /// Сколько юнитов включать в placement (по order).
  static int placementUnitLimit({required AppMode mode}) =>
      mode == AppMode.kids ? 3 : 2;

  static int placementQuestionsPerUnit({required AppMode mode}) =>
      mode == AppMode.kids ? 1 : 2;

  static int typingWordCount({
    required AppMode mode,
    required KidsAgeGroup age,
  }) {
    if (mode == AppMode.adult) return 6;
    return switch (age) {
      KidsAgeGroup.age3to6 => 3,
      KidsAgeGroup.age6to9 => 4,
      KidsAgeGroup.age9to12 => 6,
    };
  }
}
