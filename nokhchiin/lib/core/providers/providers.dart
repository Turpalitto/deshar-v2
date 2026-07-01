import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/asset_dictionary_datasource.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/learning_usecases.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/entities/enums.dart';

// --- Data sources ---
final assetDictSourceProvider = Provider((_) => AssetDictionaryDataSource());
final progressLocalProvider = Provider((_) => LocalProgressDataSource());
final userLocalProvider = Provider((_) => LocalUserDataSource());

// --- Repositories ---
final dictionaryRepoProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepositoryImpl(ref.watch(assetDictSourceProvider)),
);

final progressRepoProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(ref.watch(progressLocalProvider)),
);

final learningPathRepoProvider = Provider<LearningPathRepository>(
  (ref) => LearningPathRepositoryImpl(
    ref.watch(assetDictSourceProvider),
    ref.watch(dictionaryRepoProvider),
  ),
);

final userRepoProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(userLocalProvider)),
);

// --- Use cases ---
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

// --- App state ---
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfileEntity>>(
  (ref) => UserProfileNotifier(ref.watch(userRepoProvider)),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfileEntity>> {
  UserProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final UserRepository _repo;

  Future<void> _load() async {
    state = AsyncValue.data(await _repo.getProfile());
  }

  Future<void> setMode(AppMode mode) async {
    final current = state.value ?? const UserProfileEntity();
    final updated = current.copyWith(mode: mode);
    await _repo.saveProfile(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> setAgeGroup(KidsAgeGroup age) async {
    final current = state.value ?? const UserProfileEntity();
    final updated = current.copyWith(ageGroup: age);
    await _repo.saveProfile(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addXp(int xp, int stars) async {
    final current = state.value ?? const UserProfileEntity();
    final newXp = current.xp + xp;
    final updated = current.copyWith(
      xp: newXp,
      level: (newXp / 100).floor() + 1,
      stars: current.stars + stars,
    );
    await _repo.saveProfile(updated);
    state = AsyncValue.data(updated);
  }
}

final dictionaryProvider = FutureProvider<List<WordEntity>>((ref) async {
  return ref.watch(dictionaryRepoProvider).getAllWords();
});

final learningUnitsProvider =
    FutureProvider<List<LearningUnitEntity>>((ref) async {
  final units = await ref.watch(learningPathRepoProvider).getUnits();
  final mastery = ref.watch(unitMasteryUseCaseProvider);

  final result = <LearningUnitEntity>[];
  LearningUnitEntity? prev;
  for (final u in units) {
    final pct = await mastery(u.id);
    var unlocked = u.order == 1;
    if (!unlocked && prev != null) {
      final prevPct = await mastery(prev.id);
      unlocked = prevPct >= u.requiredMastery;
    }
    result.add(LearningUnitEntity(
      id: u.id,
      order: u.order,
      titleRu: u.titleRu,
      titleCe: u.titleCe,
      icon: u.icon,
      requiredMastery: u.requiredMastery,
      wordIds: u.wordIds,
      isUnlocked: unlocked,
      masteryPercent: pct,
    ));
    prev = u;
  }
  return result;
});

final dueWordsProvider = FutureProvider<List<WordEntity>>((ref) async {
  return ref.watch(getDueWordsUseCaseProvider)();
});
