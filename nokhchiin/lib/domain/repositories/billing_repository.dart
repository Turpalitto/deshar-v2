import '../entities/subscription_entity.dart';

/// Биллинг недоступен — магазин не инициализирован, товар не найден
/// или покупка не стартовала. UI должен показать понятную ошибку, а не
/// выдавать premium бесплатно (регрессия _stubPurchase — см. аудит 2.1).
class BillingUnavailableException implements Exception {
  const BillingUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'BillingUnavailableException: $message';
}

abstract class BillingRepository {
  Future<SubscriptionEntity> getSubscription();
  Future<SubscriptionEntity> startTrial();
  Future<SubscriptionEntity> purchasePremium();
  Future<SubscriptionEntity> restorePurchases();
  Stream<SubscriptionEntity> watchSubscription();
}
