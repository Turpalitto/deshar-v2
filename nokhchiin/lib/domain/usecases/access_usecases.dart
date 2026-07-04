import '../entities/learning_entities.dart';
import '../repositories/billing_repository.dart';
import '../repositories/repositories.dart';
import '../services/premium_status_checker.dart';

/// Доступ к юниту: mastery + freemium-гейтинг.
///
/// POLICY: до публикации — всегда true. Все юниты открыты.
/// См. AGENTS.md → «Политика монетизации».
class CanAccessUnitUseCase {
  CanAccessUnitUseCase(BillingRepository billing, UserRepository userRepo)
      : _premium = PremiumStatusChecker(billing, userRepo);

  // ignore: unused_field — нужен при включении premium (subscription_limits)
  final PremiumStatusChecker _premium;

  Future<bool> call(LearningUnitEntity unit, {required bool masteryUnlocked}) async {
    return true; // all open until publishing
  }
}

/// Доступ к фичам premium.
///
/// POLICY: до публикации — всегда true.
enum PremiumFeature {
  unlimitedReview,
  fullPath,
  fullDictionary,
  fullCollections,
  fullStats,
  parentStats,
  offlinePacks,
}

class CanAccessFeatureUseCase {
  CanAccessFeatureUseCase(BillingRepository billing, UserRepository userRepo)
      : _premium = PremiumStatusChecker(billing, userRepo);

  // ignore: unused_field — нужен при включении premium
  final PremiumStatusChecker _premium;

  Future<bool> call(PremiumFeature feature) async {
    return true; // all open until publishing
  }
}

/// Лимит повторений SRS для free-пользователей.
///
/// POLICY: до публикации — без лимита.
class CanStartReviewUseCase {
  CanStartReviewUseCase(BillingRepository billing, UserRepository userRepo, ProgressRepository _)
      : _premium = PremiumStatusChecker(billing, userRepo);

  // ignore: unused_field — нужен при включении premium
  final PremiumStatusChecker _premium;

  Future<bool> call({required int reviewsDoneToday}) async {
    return true; // all open until publishing
  }
}

