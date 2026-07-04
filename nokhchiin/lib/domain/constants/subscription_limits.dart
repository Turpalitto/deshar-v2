/// Лимиты freemium-модели.
///
/// POLICY: до публикации — все лимиты сняты (9999 = без ограничений).
/// Платные уровни, premium и paywall включаются перед релизом.
/// См. AGENTS.md → «Политика монетизации».
abstract final class SubscriptionLimits {
  /// Бесплатно: первые N юнитов пути обучения.
  static const int freeUnitMaxOrder = 9999;

  /// Лимит слов SRS-повторения в день (free).
  static const int freeDailyReviewLimit = 9999;

  /// Бесплатный просмотр словаря без поиска.
  static const int freeDictionaryBrowseLimit = 9999;

  /// Бесплатный поиск в словаре.
  static const int freeDictionarySearchLimit = 9999;

  /// Сундук каждые N завершённых уроков.
  static const int lessonsPerChest = 3;

  static const String premiumProductId = 'nokhchiin_premium_monthly';
  static const int trialDays = 7;
}
