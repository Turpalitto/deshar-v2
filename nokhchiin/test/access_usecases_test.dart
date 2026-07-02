import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/config/feature_flags.dart';
import 'package:nokhchiin/domain/constants/subscription_limits.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/entities/subscription_entity.dart';
import 'package:nokhchiin/domain/repositories/billing_repository.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/domain/usecases/access_usecases.dart';


class _FakeBilling implements BillingRepository {
  _FakeBilling(this.tier);
  SubscriptionTier tier;

  @override
  Future<SubscriptionEntity> getSubscription() async =>
      SubscriptionEntity(tier: tier);

  @override
  Future<SubscriptionEntity> purchasePremium() async => getSubscription();

  @override
  Future<SubscriptionEntity> restorePurchases() async => getSubscription();

  @override
  Future<SubscriptionEntity> startTrial() async => getSubscription();

  @override
  Stream<SubscriptionEntity> watchSubscription() => const Stream.empty();
}

class _FakeUserRepo implements UserRepository {
  _FakeUserRepo(this.profile);
  UserProfileEntity profile;

  @override
  Future<UserProfileEntity> getProfile() async => profile;

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {}
}

void main() {
  const unitFree = LearningUnitEntity(
    id: 'animals',
    order: 2,
    titleRu: 'Животные',
    titleCe: 'Дийнаташ',
    icon: 'paw',
    requiredMastery: 0,
  );
  const unitPaid = LearningUnitEntity(
    id: 'school',
    order: 5,
    titleRu: 'Школа',
    titleCe: 'Дешар',
    icon: 'book',
    requiredMastery: 70,
  );

  test('free user can access unit within free limit', () async {
    final useCase = CanAccessUnitUseCase(
      _FakeBilling(SubscriptionTier.free),
      _FakeUserRepo(const UserProfileEntity()),
    );
    expect(await useCase(unitFree, masteryUnlocked: true), isTrue);
  });

  test('free user blocked from unit beyond free limit', () async {
    // Тест актуален только когда premiumEnabled = true.
    // При premiumEnabled = false весь контент открыт (dev-режим).
    if (!FeatureFlags.premiumEnabled) return;
    final useCase = CanAccessUnitUseCase(
      _FakeBilling(SubscriptionTier.free),
      _FakeUserRepo(const UserProfileEntity()),
    );
    expect(await useCase(unitPaid, masteryUnlocked: true), isFalse);
    expect(unitPaid.order, greaterThan(SubscriptionLimits.freeUnitMaxOrder));
  });


  test('premium user can access any mastery-unlocked unit', () async {
    final useCase = CanAccessUnitUseCase(
      _FakeBilling(SubscriptionTier.premium),
      _FakeUserRepo(const UserProfileEntity(isPremium: true)),
    );
    expect(await useCase(unitPaid, masteryUnlocked: true), isTrue);
  });
}
