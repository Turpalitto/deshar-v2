import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:nokhchiin/core/providers/billing_providers.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/core/widgets/legal_links_row.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/entities/subscription_entity.dart';
import 'package:nokhchiin/domain/repositories/billing_repository.dart';
import 'package:nokhchiin/features/paywall/paywall_screen.dart';
import 'package:nokhchiin/l10n/app_localizations.dart';


class _FakeBilling implements BillingRepository {
  _FakeBilling({this.throwOnPurchase = false, this.throwOnTrial = false});

  final bool throwOnPurchase;
  final bool throwOnTrial;
  SubscriptionTier lastTier = SubscriptionTier.free;

  @override
  Future<SubscriptionEntity> getSubscription() async =>
      SubscriptionEntity(tier: lastTier);

  @override
  Future<SubscriptionEntity> purchasePremium() async {
    if (throwOnPurchase) {
      throw const BillingUnavailableException('Магазин недоступен');
    }
    lastTier = SubscriptionTier.premium;
    return const SubscriptionEntity(tier: SubscriptionTier.premium);
  }

  @override
  Future<SubscriptionEntity> restorePurchases() async => getSubscription();

  @override
  Future<SubscriptionEntity> startTrial() async {
    if (throwOnTrial) {
      throw const BillingUnavailableException('Trial недоступен');
    }
    lastTier = SubscriptionTier.trial;
    return const SubscriptionEntity(tier: SubscriptionTier.trial);
  }

  @override
  Stream<SubscriptionEntity> watchSubscription() => const Stream.empty();
}

void main() {
  final hiveDir = Directory('test/.hive');

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
    hiveDir.createSync(recursive: true);
    Hive.init(hiveDir.path);
    await LocalProgressDataSource().init();
    await LocalUserDataSource().init();
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
  });

  group('BillingUnavailableException', () {
    test('stores message and toString', () {
      const e = BillingUnavailableException('Магазин недоступен');
      expect(e.message, 'Магазин недоступен');
      expect(e.toString(), contains('Магазин недоступен'));
    });

    test('is an Exception', () {
      const e = BillingUnavailableException('test');
      expect(e, isA<Exception>());
    });
  });

  group('FakeBilling purchasePremium', () {
    test('throws BillingUnavailableException when store unavailable', () async {
      final billing = _FakeBilling(throwOnPurchase: true);
      expect(
        () => billing.purchasePremium(),
        throwsA(isA<BillingUnavailableException>()),
      );
    });

    test('sets premium tier on success', () async {
      final billing = _FakeBilling();
      final sub = await billing.purchasePremium();
      expect(sub.tier, SubscriptionTier.premium);
      expect(billing.lastTier, SubscriptionTier.premium);
    });
  });

  group('FakeBilling startTrial', () {
    test('throws BillingUnavailableException when unavailable', () async {
      final billing = _FakeBilling(throwOnTrial: true);
      expect(
        () => billing.startTrial(),
        throwsA(isA<BillingUnavailableException>()),
      );
    });

    test('sets trial tier on success', () async {
      final billing = _FakeBilling();
      final sub = await billing.startTrial();
      expect(sub.tier, SubscriptionTier.trial);
    });
  });

  group('PaywallScreen widget', () {
    testWidgets('shows LegalLinksRow', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const PaywallScreen()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billingServiceProvider.overrideWith((ref) => _FakeBilling()),
            userProfileProvider.overrideWith(() => _FakeNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ru'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LegalLinksRow), findsOneWidget);
    });

    testWidgets('renders trial and buy buttons', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const PaywallScreen()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billingServiceProvider.overrideWith((ref) => _FakeBilling()),
            userProfileProvider.overrideWith(() => _FakeNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ru'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Premium'), findsWidgets);
      expect(find.byType(LegalLinksRow), findsOneWidget);
    });
  });
}

class _FakeNotifier extends UserProfileNotifier {
  @override
  Future<UserProfileEntity> build() async => UserProfileEntity();
}
