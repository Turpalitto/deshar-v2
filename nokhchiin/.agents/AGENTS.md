# AGENTS.md — Nokhchiin Project Rules

> **Монорепозиторий (корень workspace):** [`../../AGENTS.md`](../../AGENTS.md)

Проект: **Nokhchiin** — Flutter-приложение для изучения чеченского языка.  
Путь: `C:\dev\deshar-v2\nokhchiin\`

---

## Архитектура

Clean Architecture: `domain → data → core → features`.

```
lib/
  core/
    config/         # FeatureFlags (premiumEnabled, etc.)
    providers/      # Riverpod провайдеры (barrel → отдельные файлы)
    services/       # BillingService, ProgressStatsService, AudioService
    design/         # Виджеты, токены (AppSpacing, AppColors)
    design_system/  # Компоненты дизайн-системы
  data/
    datasources/    # AssetDictionaryDataSource, LocalStorageDataSource
    repositories/   # Barrel + отдельные *_impl.dart файлы
  domain/
    constants/      # GameplayConstants, SubscriptionLimits
    entities/       # WordEntity, UserProfileEntity, LearningUnitEntity, etc.
    repositories/   # Абстрактные интерфейсы
    services/       # DailySyncCalculator, SpacedRepetitionEngine, PremiumStatusChecker
    usecases/       # learning_usecases.dart, access_usecases.dart
  features/         # Экраны (18 фич)
```

---

## Слой провайдеров (`lib/core/providers/`)

`providers.dart` — barrel, реэкспортирует все файлы ниже.  
**Никогда не добавляй логику напрямую в `providers.dart`.**

| Файл | Содержимое |
|------|-----------|
| `datasource_providers.dart` | `assetDictSourceProvider`, `progressLocalProvider`, `userLocalProvider` |
| `repository_providers.dart` | `dictionaryRepoProvider`, `progressRepoProvider`, `learningPathRepoProvider`, `userRepoProvider` |
| `usecase_providers.dart` | `reviewWordUseCaseProvider`, `getDueWordsUseCaseProvider`, `unitMasteryUseCaseProvider`, `canAccess*` |
| `user_profile_provider.dart` | `userProfileProvider` + `UserProfileNotifier` (AsyncNotifier) |
| `billing_providers.dart` | `billingServiceProvider`, `subscriptionProvider` |
| `content_providers.dart` | `dictionaryProvider`, `learningUnitsProvider`, `dueWordsProvider`, `progressStatsProvider`, `learnerInsightsProvider`, `continueUnitProvider`, `worldsProvider`, `collectionsProvider`, `storiesProvider` |

---

## Слой репозиториев (`lib/data/repositories/`)

`repository_impl.dart` — barrel, реэкспортирует все файлы.  
**Реализации хранятся в отдельных файлах:**

| Файл | Класс |
|------|-------|
| `dictionary_repository_impl.dart` | `DictionaryRepositoryImpl` — HashMap-кэш, O(1) lookup |
| `progress_repository_impl.dart` | `ProgressRepositoryImpl` |
| `learning_path_repository_impl.dart` | `LearningPathRepositoryImpl` |
| `user_repository_impl.dart` | `UserRepositoryImpl` |
| `stub_repositories.dart` | `AiTutorRepositoryStub`, `PdfImportRepositoryStub` |

---

## Ключевые правила

### Провайдеры

- **`UserProfileNotifier` — `AsyncNotifier<UserProfileEntity>`** (не `StateNotifier`).  
  Провайдер: `AsyncNotifierProvider<UserProfileNotifier, UserProfileEntity>`.
- Все методы notifier'а используют приватный `_update(updated)` → не пиши `state = AsyncData(x)` напрямую.
- Для получения текущего профиля внутри notifier'а: `_current` (геттер), не `state.value!`.
- `ref.read(userProfileProvider.notifier).someMethod()` — правильный паттерн в UI.

### Entities

- `UserProfileEntity.props` содержит **все 19 полей** — не добавляй поля без добавления в `props`.
- `WordEntity.copyWith` поддерживает **все поля** — проверяй при добавлении новых полей.
- `LearningUnitEntity.props` и `LessonEntity.props` содержат только `[id]` — это намеренно.

### Константы

- Игровые числа → только через `GameplayConstants` (`lib/domain/constants/gameplay_constants.dart`).  
  Никаких magic numbers: `xpPerLevel`, `wordLearnedXp`, `wordLearnedCoins`, `dailyGiftCoins`, `dailyGiftXp`, `chestCoins`, `chestXp`, `weeklyXpDays`.
- Лимиты подписки → только через `SubscriptionLimits` (`subscription_limits.dart`).

### Premium / Доступ

- `PremiumStatusChecker` — единственное место проверки статуса.  
  **Не копируй** проверку billing + profile вне этого класса.
- `FeatureFlags.premiumEnabled = false` (dev-режим) → весь контент открыт.  
  Тесты, проверяющие freemium-блокировку, должны делать early return при `!FeatureFlags.premiumEnabled`.

### SRS и тестируемость

- `SpacedRepetitionEngine` и `DailySyncCalculator` принимают `{DateTime? now}` — не используй `DateTime.now()` внутри логики движка.
- Всегда передавай фиксированное время в тестах.

### Импорты

- Никогда не импортируй `content_providers.dart` напрямую — он реэкспортируется через `providers.dart`.
- Используй `providers.dart` как единственную точку входа в слой провайдеров.

---

## Хранилище

**Hive** (`hive_flutter: ^1.1.0`) — текущее хранилище.  
Нет type adapters — данные сериализуются как `Map<String, dynamic>` вручную в `UserRepositoryImpl`.  
Миграция на Isar/Drift **не планируется** пока не появятся сложные запросы или offline-sync.

---

## Тесты (`test/`)

Запуск: `flutter test --no-pub`  
Ожидаемый результат: **46 тестов, 0 провалов.**

| Файл | Покрытие |
|------|---------|
| `access_usecases_test.dart` | Freemium-гейтинг (3 теста, учитывает `FeatureFlags`) |
| `analytics_event_test.dart` | Сериализация событий |
| `chechen_text_utils_test.dart` | Нормализация палочки |
| `daily_sync_test.dart` | Стрик, ротация weeklyXp |
| `dictionary_parser_test.dart` | Парсинг, дедупликация, UUID, POS, nounClass |
| `learning_usecases_test.dart` | UnitMastery (4), GetDueWords (3), ReviewWord (2) |
| `onboarding_screen_test.dart` | Виджет-тесты онбординга |
| `spaced_repetition_engine_test.dart` | SRS алгоритм |
| `user_profile_entity_test.dart` | Defaults, copyWith, dailyGoal, Equatable regression |

---

## Анализ

```bash
dart analyze lib/          # 0 ошибок (warnings/info допустимы — см. ниже)
flutter test --no-pub      # 46 tests passed
dart format --set-exit-if-changed .
```

### Известные info (не критично, не исправлять без задачи)

- `use_build_context_synchronously` — `lesson_flow_screen.dart`, `review_screen.dart`
- `deprecated_member_use` — `RadioGroup` в `profile_screen.dart` (Flutter 3.32+)
- `unnecessary_underscores` — в нескольких экранах
- `avoid_dynamic_calls` — `content_datasource.dart`

---

## CI (`/.github/workflows/flutter.yml`)

Шаги:
1. `flutter pub get`
2. `dart format --set-exit-if-changed .`
3. `flutter test`
4. `flutter build web`

---

## Что НЕ делать

- ❌ Не добавлять `StateNotifier` для нового state — только `AsyncNotifier` или `Notifier`.
- ❌ Не добавлять код в barrel-файлы (`providers.dart`, `repository_impl.dart`).
- ❌ Не хардкодить игровые числа — только `GameplayConstants`.
- ❌ Не дублировать premium-проверку — только `PremiumStatusChecker`.
- ❌ Не добавлять поля в entities без обновления `props` (Equatable regression).
- ❌ Не использовать `DateTime.now()` внутри domain-сервисов — только через параметр.

---

## Фазы рефакторинга

| Фаза | Статус | Содержание |
|------|--------|-----------|
| Фаза 1 | ✅ Завершена | Баги Equatable/copyWith, HashMap, GameplayConstants, PremiumStatusChecker, SRS тестируемость, 46 тестов, CI |
| Фаза 2 | ✅ Завершена | Разбивка providers.dart + repository_impl.dart, AsyncNotifier миграция, warning cleanup |
| Фаза 3 | 🔲 Планируется | Freezed codegen (при необходимости), BuildContext warnings, RadioGroup deprecation |
