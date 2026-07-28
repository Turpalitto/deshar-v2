/// Константы игрового процесса — награды, прогрессия, лимиты.
///
/// Все «магические числа» из providers и use cases собраны здесь,
/// чтобы легко балансировать без поиска по коду.
abstract final class GameplayConstants {
  // --- Прогрессия ---

  /// XP, необходимый для следующего уровня.
  static const int xpPerLevel = 100;

  // --- Награды за урок ---

  /// XP за каждое выученное слово.
  static const int wordLearnedXp = 8;

  /// Монеты за каждое выученное слово.
  static const int wordLearnedCoins = 2;

  // --- Ежедневный подарок ---

  /// Монеты за daily gift.
  static const int dailyGiftCoins = 15;

  /// XP за daily gift.
  static const int dailyGiftXp = 20;

  // --- Сундук ---

  /// Монеты за открытие сундука.
  static const int chestCoins = 25;

  /// XP за открытие сундука.
  static const int chestXp = 30;

  // --- Weekly XP ---

  /// Количество дней в weekly XP массиве.
  static const int weeklyXpDays = 7;

  // --- Учебные сессии ---

  static const int minimumRecordedSessionMinutes = 1;
  static const int maximumRecordedSessionMinutes = 60;
  static const int kidsAge3to6SessionWordCount = 3;
  static const int kidsAge6to9SessionWordCount = 4;
  static const int kidsAge9to12SessionWordCount = 5;

  // --- Заморозка стрика ---

  /// Стоимость одной заморозки стрика (монеты).
  static const int streakFreezeCoinCost = 150;

  /// Максимум одновременно хранимых заморозок.
  static const int maxStreakFreezes = 2;
}
