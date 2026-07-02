import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/billing_service.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/entities/subscription_entity.dart';
import 'repository_providers.dart';
import 'user_profile_provider.dart';

final billingServiceProvider = Provider<BillingRepository>((ref) {
  return BillingService(
    userRepo: ref.watch(userRepoProvider),
    onPremiumChanged: (v) => ref.read(userProfileProvider.notifier).setPremium(v),
  );
});

final subscriptionProvider = FutureProvider<SubscriptionEntity>((ref) async {
  return ref.watch(billingServiceProvider).getSubscription();
});
