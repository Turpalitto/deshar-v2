import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/learning_usecases.dart';
import '../../domain/usecases/access_usecases.dart';
import '../../domain/usecases/placement_test_usecase.dart';
import 'repository_providers.dart';
import 'billing_providers.dart';


final reviewWordUseCaseProvider = Provider(
  (ref) => ReviewWordUseCase(ref.watch(progressRepoProvider)),
);

final getDueWordsUseCaseProvider = Provider(
  (ref) => GetDueWordsUseCase(
    ref.watch(progressRepoProvider),
    ref.watch(dictionaryRepoProvider),
  ),
);

final unitMasteryUseCaseProvider = Provider(
  (ref) => UnitMasteryPercentUseCase(
    ref.watch(progressRepoProvider),
    ref.watch(dictionaryRepoProvider),
  ),
);

final canAccessUnitUseCaseProvider = Provider(
  (ref) => CanAccessUnitUseCase(
    ref.watch(billingServiceProvider),
    ref.watch(userRepoProvider),
  ),
);

final canAccessFeatureUseCaseProvider = Provider(
  (ref) => CanAccessFeatureUseCase(
    ref.watch(billingServiceProvider),
    ref.watch(userRepoProvider),
  ),
);

final canStartReviewUseCaseProvider = Provider(
  (ref) => CanStartReviewUseCase(
    ref.watch(billingServiceProvider),
    ref.watch(userRepoProvider),
    ref.watch(progressRepoProvider),
  ),
);

final seedUnitMasteryUseCaseProvider = Provider(
  (ref) => SeedUnitMasteryFromPlacementUseCase(
    ref.watch(progressRepoProvider),
    ref.watch(dictionaryRepoProvider),
  ),
);
