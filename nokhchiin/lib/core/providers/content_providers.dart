import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/word_entity.dart';
import '../../core/services/progress_stats_service.dart';
import '../../core/services/learner_insights_service.dart';
import 'repository_providers.dart';
import 'usecase_providers.dart';
import 'user_profile_provider.dart';
import '../../data/datasources/content_datasource.dart';

// --- Worlds / Collections / Stories ---
final contentSourceProvider = Provider((_) => ContentDataSource());
final worldsProvider =
    FutureProvider((ref) => ref.read(contentSourceProvider).loadWorlds());
final collectionsProvider =
    FutureProvider((ref) => ref.read(contentSourceProvider).loadCollections());
final storiesProvider =
    FutureProvider((ref) => ref.read(contentSourceProvider).loadStories());

// --- Dictionary & Learning units ---
final dictionaryProvider = FutureProvider<List<WordEntity>>((ref) async {
  return ref.watch(dictionaryRepoProvider).getAllWords();
});

final dueWordsProvider = FutureProvider<List<WordEntity>>((ref) async {
  return ref.watch(getDueWordsUseCaseProvider)();
});

final learningUnitsProvider =
    FutureProvider<List<LearningUnitEntity>>((ref) async {
  final units = await ref.watch(learningPathRepoProvider).getUnits();
  final mastery = ref.watch(unitMasteryUseCaseProvider);
  final canAccess = ref.watch(canAccessUnitUseCaseProvider);

  final result = <LearningUnitEntity>[];
  LearningUnitEntity? prev;
  for (final u in units) {
    final pct = await mastery(u.id);
    var masteryUnlocked = u.order == 1;
    if (!masteryUnlocked && prev != null) {
      final prevPct = await mastery(prev.id);
      masteryUnlocked = prevPct >= u.requiredMastery;
    }
    final unlocked = await canAccess(u, masteryUnlocked: masteryUnlocked);
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

// --- Stats ---
final progressStatsProvider = Provider(
  (ref) => ProgressStatsService(
    ref.watch(progressRepoProvider),
    ref.watch(dictionaryRepoProvider),
  ),
);

final languageMasteryProvider = FutureProvider<int>((ref) async {
  return ref.watch(progressStatsProvider).languageMasteryPercent();
});

final learnerInsightsProvider = FutureProvider<LearnerInsights>((ref) async {
  final units = await ref.watch(learningUnitsProvider.future);
  final language = await ref.watch(languageMasteryProvider.future);
  final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();

  return LearnerInsightsService.build(
    units: units,
    languageMasteryPercent: language,
    streakDays: profile.streakDays,
    level: profile.level,
    xp: profile.xp,
    lessonsCompleted: profile.lessonsCompletedTotal,
  );
});

final continueUnitProvider = FutureProvider<LearningUnitEntity?>((ref) async {
  final units = await ref.watch(learningUnitsProvider.future);
  return ref.watch(progressStatsProvider).findContinueUnit(units);
});
