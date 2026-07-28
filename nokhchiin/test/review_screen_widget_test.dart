import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/entities/subscription_entity.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/billing_repository.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/domain/usecases/access_usecases.dart';
import 'package:nokhchiin/features/review/review_screen.dart';

class _ProfileNotifier extends UserProfileNotifier {
  _ProfileNotifier(this.mode);

  final AppMode mode;

  @override
  Future<UserProfileEntity> build() async => UserProfileEntity(mode: mode);
}

class _Progress implements ProgressRepository {
  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() async => const {};

  @override
  Future<List<WordProgressEntity>> getDueForReview({DateTime? now}) async =>
      const [];

  @override
  Future<List<String>> getFavorites() async => const [];

  @override
  Future<WordProgressEntity?> getProgress(String wordId) async => null;

  @override
  Future<void> saveProgress(WordProgressEntity progress) async {}

  @override
  Future<void> toggleFavorite(String wordId) async {}
}

class _UserRepository implements UserRepository {
  @override
  Future<UserProfileEntity> getProfile() async => const UserProfileEntity();

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {}
}

class _Billing implements BillingRepository {
  @override
  Future<SubscriptionEntity> getSubscription() async =>
      const SubscriptionEntity();

  @override
  Future<SubscriptionEntity> purchasePremium() => getSubscription();

  @override
  Future<SubscriptionEntity> restorePurchases() => getSubscription();

  @override
  Future<SubscriptionEntity> startTrial() => getSubscription();

  @override
  Stream<SubscriptionEntity> watchSubscription() => const Stream.empty();
}

const _word = WordEntity(
  id: 'word-1',
  chechen: 'Маршалла',
  russian: 'Здравствуйте',
);

void main() {
  Future<void> openRatings(WidgetTester tester, AppMode mode) async {
    final progress = _Progress();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => _ProfileNotifier(mode)),
          dueWordsProvider.overrideWith((ref) async => const [_word]),
          progressRepoProvider.overrideWithValue(progress),
          canStartReviewUseCaseProvider.overrideWithValue(
            CanStartReviewUseCase(_Billing(), _UserRepository(), progress),
          ),
        ],
        child: const MaterialApp(home: ReviewScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Показать'));
    await tester.pumpAndSettle();
  }

  testWidgets('adult review shows four SRS ratings', (tester) async {
    await openRatings(tester, AppMode.adult);

    expect(find.text('Снова'), findsOneWidget);
    expect(find.text('Трудно'), findsOneWidget);
    expect(find.text('Хорошо'), findsOneWidget);
    expect(find.text('Легко'), findsOneWidget);
  });

  testWidgets('kids review keeps two simple ratings', (tester) async {
    await openRatings(tester, AppMode.kids);

    expect(find.text('Не помню'), findsOneWidget);
    expect(find.text('Помню'), findsOneWidget);
    expect(find.text('Трудно'), findsNothing);
    expect(find.text('Легко'), findsNothing);
  });
}
