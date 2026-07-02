import '../constants/subscription_limits.dart';
import '../entities/learning_entities.dart';
import '../repositories/billing_repository.dart';
import '../repositories/repositories.dart';
import '../services/premium_status_checker.dart';

/// Доступ к юниту: mastery + freemium-гейтинг.
class CanAccessUnitUseCase {
  CanAccessUnitUseCase(BillingRepository billing, UserRepository userRepo)
      : _premium = PremiumStatusChecker(billing, userRepo);

  final PremiumStatusChecker _premium;

  Future<bool> call(LearningUnitEntity unit, {required bool masteryUnlocked}) async {
    if (!masteryUnlocked) return false;
    if (await _premium.isPremium()) return true;
    return unit.order <= SubscriptionLimits.freeUnitMaxOrder;
  }
}

/// Доступ к фичам premium.
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

  final PremiumStatusChecker _premium;

  Future<bool> call(PremiumFeature feature) async {
    if (await _premium.isPremium()) return true;

    return switch (feature) {
      PremiumFeature.unlimitedReview => false,
      PremiumFeature.fullPath => false,
      PremiumFeature.fullDictionary => false,
      PremiumFeature.fullCollections => false,
      PremiumFeature.fullStats => false,
      PremiumFeature.parentStats => false,
      PremiumFeature.offlinePacks => false,
    };
  }
}

/// Лимит повторений SRS для free-пользователей.
class CanStartReviewUseCase {
  CanStartReviewUseCase(BillingRepository billing, UserRepository userRepo, ProgressRepository _)
      : _premium = PremiumStatusChecker(billing, userRepo);

  final PremiumStatusChecker _premium;

  Future<bool> call({required int reviewsDoneToday}) async {
    if (await _premium.isPremium()) return true;
    return reviewsDoneToday < SubscriptionLimits.freeDailyReviewLimit;
  }
}

