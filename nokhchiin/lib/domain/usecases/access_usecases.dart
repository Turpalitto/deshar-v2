import '../constants/subscription_limits.dart';
import '../entities/learning_entities.dart';
import '../entities/subscription_entity.dart';
import '../repositories/billing_repository.dart';
import '../repositories/repositories.dart';

/// Доступ к юниту: mastery + freemium-гейтинг.
class CanAccessUnitUseCase {
  CanAccessUnitUseCase(this._billing, this._userRepo);

  final BillingRepository _billing;
  final UserRepository _userRepo;

  Future<bool> call(LearningUnitEntity unit, {required bool masteryUnlocked}) async {
    if (!masteryUnlocked) return false;

    final sub = await _billing.getSubscription();
    if (sub.isPremium) return true;

    final profile = await _userRepo.getProfile();
    if (profile.isPremium) return true;

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
  CanAccessFeatureUseCase(this._billing, this._userRepo);

  final BillingRepository _billing;
  final UserRepository _userRepo;

  Future<bool> call(PremiumFeature feature) async {
    final sub = await _billing.getSubscription();
    if (sub.isPremium) return true;
    final profile = await _userRepo.getProfile();
    if (profile.isPremium) return true;

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
  CanStartReviewUseCase(this._billing, this._userRepo, this._progressRepo);

  final BillingRepository _billing;
  final UserRepository _userRepo;
  final ProgressRepository _progressRepo;

  Future<bool> call({required int reviewsDoneToday}) async {
    final sub = await _billing.getSubscription();
    if (sub.isPremium) return true;
    final profile = await _userRepo.getProfile();
    if (profile.isPremium) return true;
    return reviewsDoneToday < SubscriptionLimits.freeDailyReviewLimit;
  }
}
