import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/billing_service.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/entities/subscription_entity.dart';
import 'repository_providers.dart';
import 'user_profile_provider.dart';

final billingServiceProvider = Provider<BillingRepository>((ref) {
  final service = BillingService(
    userRepo: ref.watch(userRepoProvider),
    onPremiumChanged: (v) => ref.read(userProfileProvider.notifier).setPremium(v),
  );
  // Раньше dispose() был объявлен, но никогда не вызывался — подписка на
  // поток покупок теоретически текла (аудит §2).
  ref.onDispose(service.dispose);
  return service;
});

final subscriptionProvider =
    FutureProvider.autoDispose<SubscriptionEntity>((ref) async {
  return ref.watch(billingServiceProvider).getSubscription();
});
