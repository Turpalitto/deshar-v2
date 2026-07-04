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

final dueWordsProvider =
    FutureProvider.autoDispose<List<WordEntity>>((ref) async {
  // autoDispose: только Review-экран. Аудит §3.2 — screen-scope, не копить
  // состояние между навигацией.
  return ref.watch(getDueWordsUseCaseProvider)();
});

final learningUnitsProvider =
    FutureProvider<List<LearningUnitEntity>>((ref) async {
  final all = await ref.watch(learningPathRepoProvider).getUnits();
  // Скрываем юниты без контента (enabled: false в learning_path.json).
  // Аудит logic §3: school/adjectives/phrases/dialogues/stories не имеют
  // ни категории в dictionary.json, ни уроков в lessons.json — показ
  // случайных слов под правильным заголовком = баг.
  final units = all.where((u) => u.enabled).toList();
  final mastery = ref.watch(unitMasteryUseCaseProvider);
  final canAccess = ref.watch(canAccessUnitUseCaseProvider);

  final result = <LearningUnitEntity>[];
  LearningUnitEntity? prev;
  for (final u in units) {
    final pct = await mastery(u.id);
    // Открыт по умолчанию если requiredMastery == 0 (стартовые юниты).
    // Раньше order == 1 — ломалось при нескольких стартовых.
    var masteryUnlocked = u.requiredMastery == 0;
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
      enabled: u.enabled,
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

final languageMasteryProvider =
    FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(progressStatsProvider).languageMasteryPercent();
});

final learnerInsightsProvider =
    FutureProvider.autoDispose<LearnerInsights>((ref) async {
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

final continueUnitProvider =
    FutureProvider.autoDispose<LearningUnitEntity?>((ref) async {
  final units = await ref.watch(learningUnitsProvider.future);
  return ref.watch(progressStatsProvider).findContinueUnit(units);
});
