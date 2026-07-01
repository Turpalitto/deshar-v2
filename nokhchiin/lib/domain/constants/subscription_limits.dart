/// Лимиты freemium-модели.
abstract final class SubscriptionLimits {
  /// Бесплатно: первые N юнитов пути обучения.
  static const int freeUnitMaxOrder = 3;

  /// Лимит слов SRS-повторения в день (free).
  static const int freeDailyReviewLimit = 20;

  /// Бесплатный просмотр словаря без поиска.
  static const int freeDictionaryBrowseLimit = 50;

  /// Бесплатный поиск в словаре.
  static const int freeDictionarySearchLimit = 20;

  /// Сундук каждые N завершённых уроков.
  static const int lessonsPerChest = 3;

  static const String premiumProductId = 'nokhchiin_premium_monthly';
  static const int trialDays = 7;
}
