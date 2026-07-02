import '../../core/config/feature_flags.dart';
import '../repositories/billing_repository.dart';
import '../repositories/repositories.dart';

/// Единый источник правды для проверки premium-статуса.
///
/// Когда [FeatureFlags.premiumEnabled] == false, всегда возвращает `true`
/// (весь контент доступен бесплатно).
class PremiumStatusChecker {
  const PremiumStatusChecker(this._billing, this._userRepo);

  final BillingRepository _billing;
  final UserRepository _userRepo;

  /// Возвращает `true`, если пользователь имеет premium
  /// (через подписку ИЛИ через флаг профиля),
  /// либо если premium-система отключена.
  Future<bool> isPremium() async {
    if (!FeatureFlags.premiumEnabled) return true;
    final sub = await _billing.getSubscription();
    if (sub.isPremium) return true;
    final profile = await _userRepo.getProfile();
    return profile.isPremium;
  }
}
