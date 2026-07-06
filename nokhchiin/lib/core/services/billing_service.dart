import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/app_logger.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/repositories.dart';

/// Биллинг: in_app_purchase на iOS/Android.
///
/// На web/desktop IAP недоступен — методы покупки бросают
/// [BillingUnavailableException]. Локальный premium-флаг не выдаётся
/// без реальной покупки (регрессия _stubPurchase — аудит 2.1).
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
  bool _premiumConfirmedByStore = false;

  Future<void> _initIap() async {
    if (kIsWeb) return;
    try {
      _iapReady = await _iap.isAvailable();
      if (!_iapReady) return;
      _purchaseSub = _iap.purchaseStream.listen(_onPurchases);
      // Сверяем реальный статус подписки с локальным Hive-флагом при старте.
      // Если в Hive premium=true, а магазин не подтверждает — сбрасываем
      // (закрывает финансовую дыру: локальный флаг без валидации — аудит 2.2).
      unawaited(_syncPremiumWithStore());
    } catch (e, st) {
      AppLogger.warn('IAP init failed', error: e, stackTrace: st);
      _iapReady = false;
    }
  }

  /// Синхронизация локального premium-флага с реальным состоянием магазина.
  /// Восстанавливает покупки; если restore не подтвердил premium, а локальный
  /// флаг стоит — сбрасываем его (защита от подделки Hive-файла).
  ///
  /// Раньше это было только комментарием — restorePurchases() резолвится,
  /// когда запрос отправлен в магазин, а не когда purchaseStream доставил
  /// все PurchaseDetails, так что сброс нельзя делать сразу после await.
  /// При сетевой ошибке не сбрасываем — оффлайн не означает "покупки нет"
  /// (аудит §5).
  Future<void> _syncPremiumWithStore() async {
    final profile = await _userRepo.getProfile();
    if (!profile.isPremium) return;

    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      AppLogger.warn('restorePurchases on init failed', error: e, stackTrace: st);
      return;
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!_premiumConfirmedByStore) {
      await _onPremiumChanged(false);
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
        _premiumConfirmedByStore = true;
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
    // На web/desktop IAP недоступен — не выдаём premium бесплатно.
    if (!_iapReady) {
      throw const BillingUnavailableException(
        'Магазин недоступен. Повторите покупку позже.',
      );
    }
    final response = await _iap.queryProductDetails({SubscriptionLimits.premiumProductId});
    if (response.productDetails.isEmpty) {
      throw const BillingUnavailableException(
        'Товар не найден в магазине. Проверьте регион аккаунта.',
      );
    }
    final param = PurchaseParam(productDetails: response.productDetails.first);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      throw const BillingUnavailableException('Не удалось запустить покупку.');
    }
    // premium выдаётся только из _onPurchases() по реальному
    // PurchaseStatus.purchased — не здесь.
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
