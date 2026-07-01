import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/repositories.dart';

/// Биллинг: in_app_purchase на iOS/Android, локальная заглушка на web/desktop.
class BillingService implements BillingRepository {
  BillingService({
    required UserRepository userRepo,
    required Future<void> Function(bool) onPremiumChanged,
  })  : _userRepo = userRepo,
        _onPremiumChanged = onPremiumChanged {
    _initIap();
  }

  final UserRepository _userRepo;
  final Future<void> Function(bool) _onPremiumChanged;
  final _controller = StreamController<SubscriptionEntity>.broadcast();
  final InAppPurchase _iap = InAppPurchase.instance;
  SubscriptionEntity _current = const SubscriptionEntity();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _iapReady = false;

  Future<void> _initIap() async {
    if (kIsWeb) return;
    try {
      _iapReady = await _iap.isAvailable();
      if (!_iapReady) return;
      _purchaseSub = _iap.purchaseStream.listen(_onPurchases);
    } catch (_) {
      _iapReady = false;
    }
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _controller.close();
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.productID == SubscriptionLimits.premiumProductId &&
          (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)) {
        _emitPremium();
        if (p.pendingCompletePurchase) {
          _iap.completePurchase(p);
        }
      }
    }
  }

  @override
  Future<SubscriptionEntity> getSubscription() async {
    final profile = await _userRepo.getProfile();
    if (profile.isPremium) {
      return const SubscriptionEntity(tier: SubscriptionTier.premium);
    }
    return _current;
  }

  @override
  Stream<SubscriptionEntity> watchSubscription() => _controller.stream;

  void _emit(SubscriptionEntity sub) {
    _current = sub;
    _controller.add(sub);
  }

  Future<void> _emitPremium() async {
    final sub = SubscriptionEntity(
      tier: SubscriptionTier.premium,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      productId: SubscriptionLimits.premiumProductId,
    );
    _emit(sub);
    await _onPremiumChanged(true);
  }

  @override
  Future<SubscriptionEntity> startTrial() async {
    final ends = DateTime.now().add(
      const Duration(days: SubscriptionLimits.trialDays),
    );
    final sub = SubscriptionEntity(
      tier: SubscriptionTier.trial,
      trialEndsAt: ends,
      productId: SubscriptionLimits.premiumProductId,
    );
    _emit(sub);
    await _onPremiumChanged(true);
    return sub;
  }

  @override
  Future<SubscriptionEntity> purchasePremium() async {
    if (_iapReady) {
      final response = await _iap.queryProductDetails({SubscriptionLimits.premiumProductId});
      if (response.productDetails.isNotEmpty) {
        final param = PurchaseParam(productDetails: response.productDetails.first);
        await _iap.buyNonConsumable(purchaseParam: param);
        return getSubscription();
      }
    }
    return _stubPurchase();
  }

  Future<SubscriptionEntity> _stubPurchase() async {
    await _emitPremium();
    return getSubscription();
  }

  @override
  Future<SubscriptionEntity> restorePurchases() async {
    if (_iapReady) {
      await _iap.restorePurchases();
      return getSubscription();
    }
    final profile = await _userRepo.getProfile();
    if (profile.isPremium) {
      const sub = SubscriptionEntity(tier: SubscriptionTier.premium);
      _emit(sub);
      return sub;
    }
    return _current;
  }
}
