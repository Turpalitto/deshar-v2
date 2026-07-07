# AGENTS.md — Нохчийн (workspace root)

**Корень workspace:** `C:\dev\deshar-v2\`  
**GitHub:** [Turpalitto/deshar-v2](https://github.com/Turpalitto/deshar-v2) — **последняя версия** (канонический репозиторий)  
Старый [deshar](https://github.com/Turpalitto/deshar) — архив, не использовать для новой работы.

Этот файл — **главная точка входа** для любой IDE, открытой на `C:\dev\deshar-v2\`.  
Дополнительно: `nokhchiin/.agents/AGENTS.md` — углублённые правила Flutter (провайдеры, entities, CI).

---

## Суть проекта

**Нохчийн** — production-grade, **offline-first** приложение для изучения чеченского языка.

| Аспект | Описание |
|--------|----------|
| Платформа | Flutter (iOS, Android, Web) в `nokhchiin/` |
| Аудитория | Взрослый трек (SRS, инсайты, культура) + детский (игры) |
| Данные | JSON в `nokhchiin/assets/`, прогресс в Hive |
| Визуал | Порт из Figma Make; бизнес-логика — Dart |
| Словарь | ~134 000 записей из Hugging Face датасета (Bible исключён) |
| Preview | `figma-preview/` — React/Vite, только UI |

**Главное правило:** при работе с UI переносить **только визуал**. **Не переписывать** без явной просьбы: Riverpod providers, use cases, SRS, billing, unlock, GoRouter, Hive.

---

## Структура монорепозитория

```
C:\dev\deshar-v2\                         ← workspace root (открывать IDE здесь)
├── AGENTS.md                     ← этот файл
├── nokhchiin/                    ← Flutter-приложение (production)
│   ├── lib/                      ← весь код приложения
│   ├── assets/data/              ← словарь, уроки, миры (источник правды для app)
│   ├── test/
│   └── .agents/AGENTS.md         ← детальные правила Flutter-архитектуры
├── figma-preview/                ← Vite + React: визуальный прототип экранов
├── tools/                        ← Python: сборка и очистка словаря
├── legacy/                       ← устаревший HTML-прототип (не трогать)
├── vocabulary_corrections.json   ← ручные overrides учебной лексики
├── dictionary.json               ← сгенерирован build_dictionary.py (HF датасет)
└── curated_vocabulary.json       ← проверенные слова для уроков и игр
```

| Путь | Что это | Можно менять логику? |
|------|---------|----------------------|
| `nokhchiin/` | Единственное production-приложение | Да (осторожно с SRS/billing) |
| `figma-preview/` | UI-preview для Figma | Только визуал + loadDictionary |
| `tools/` | Пайплайн данных | Да |
| `legacy/` | Архив | Нет |

---

## Команды

```bash
# Flutter — из nokhchiin/
cd nokhchiin
flutter pub get
flutter run -d chrome --web-port=7357
flutter test
dart analyze lib/

# Figma preview — из figma-preview/
cd figma-preview
npm install
npm run dev          # http://localhost:5173
npm run build

# Словарь — из корня (pip install datasets pandas pyarrow)
python tools/build_dictionary.py --hf-dataset NM-development/nmd-ce-ru-171k-v0 --copy-assets
python tools/build_dictionary.py --curate-only --copy-assets
```

---

## Figma Make — визуальный эталон

- **URL:** https://www.figma.com/make/v2oX5GKxzHgJFcI6l10D7l/Create-app
- **fileKey:** `v2oX5GKxzHgJFcI6l10D7l`

### figma-preview/

| Файл | Роль |
|------|------|
| `figma-preview/src/App.tsx` | 15+ экранов, phone frame, словарь с виртуальным скроллом |
| `figma-preview/src/loadDictionary.ts` | Загрузка из `nokhchiin/assets/data/` |
| `figma-preview/vite.config.ts` | `server.fs.allow` на родительскую папку для JSON |

Словарь в preview: `dictionary.json` + `curated_vocabulary.json`, переключатель «Весь словарь» / «Проверено», категории без сырого `default`, транскрипция скрывается при дубле.

**Не путать с `legacy/`** — старый HTML-прототип.

---

## Словарь и данные

### Источник правды для приложения

`nokhchiin/assets/data/`:

| Файл | Содержимое |
|------|------------|
| `dictionary.json` | Полный словарь (~134 000 записей из HF датасета, компактный формат) |
| `curated_vocabulary.json` | Verified + lesson-слова (~200+) |
| `lessons.json` | Уроки (greetings, animals, body, …) |
| `learning_path.json` | Юниты learning path |
| `worlds.json`, `collections.json`, `stories.json`, `bosses.json` | Контент |
| `audio_manifest.json`, `illustrations_manifest.json` | Медиа |

Корневые `dictionary.json` / `curated_vocabulary.json` — **копии** после `build_dictionary.py --copy-assets`. Менять данные в `nokhchiin/assets/data/`, затем при необходимости копировать в корень.

### Пайплайн (`tools/`)

1. **`build_dictionary.py`** — импорт из HF датасета + curated из `vocabulary_corrections.json` + майнинг по категориям
2. **`audit_emoji_vocabulary.py`** — валидация curated после сборки
3. **`vocabulary_corrections.json`** — ручные overrides (Лерг→Ухо, Хьаша→Гость, …)

```bash
python tools/build_dictionary.py --curate-only --copy-assets
```

### Flutter: загрузка словаря

| Файл | Роль |
|------|------|
| `nokhchiin/lib/data/datasources/asset_dictionary_parser.dart` | `compute()` парсинг |
| `nokhchiin/lib/data/datasources/asset_dictionary_datasource.dart` | `rootBundle` |
| `nokhchiin/lib/core/utils/dictionary_labels.dart` | Категории, транскрипция |
| `nokhchiin/lib/core/utils/chechen_text_utils.dart` | Поиск с палочкой |
| `nokhchiin/lib/features/dictionary/dictionary_screen.dart` | UI, free/premium лимиты |

Merge: **curated первым**, затем dictionary (дедуп по `chechen|russian`).

---

## Flutter-приложение (`nokhchiin/`)

### Стек

Flutter 3.12+, Dart 3.12+, `flutter_riverpod`, `go_router`, `hive_flutter`, `google_fonts`, `flutter_animate`, `flutter_svg`, `uuid`.

### Архитектура

Clean Architecture: `domain → data → core → features`.

```
nokhchiin/lib/
  core/
    design/           # Material: AppScaffold, AppShell, тема, SVG
    design_system/    # Figma: iosTokens, NokhchiinButton, FlipCard, …
    router/           # GoRouter
    providers/        # Riverpod (barrel → отдельные файлы)
    services/         # Audio, billing, analytics
    utils/            # chechen_text_utils, dictionary_labels
    config/           # feature_flags
  features/           # Экраны (home, games, dictionary, culture, …)
  domain/             # Entities, use cases, abstract repos
  data/               # Repository impl, parsers, Hive
```

Точка входа: `main.dart` → `app.dart` → `DesignSystemIntegration.enhanceWithContext`.

### Два слоя дизайна

| Модуль | Назначение |
|--------|------------|
| `core/design/` | Material shell, `NokhchiinTheme`, spacing |
| `core/design_system/` | Figma-компоненты, `context.iosTokens` |

Токены (`design_tokens.dart`): background `#F7F4EF`, terracotta `#C4724E`, meadow `#3D7A5C`, gold `#D4A84B`, culture `#1E1510`.

### Маршруты (GoRouter)

Таб-бар: `/` Home · `/worlds` · `/review` · `/profile`

Также: `/splash`, `/onboarding`, `/dictionary`, `/path`, `/insights`, `/paywall`, `/parent`, games, stories, boss.

Первый урок после onboarding: `kFirstLessonUnitId = 'animals'` (`lib/core/router/app_router.dart`).

### Ключевые providers

`dictionaryProvider`, `dueWordsProvider`, `userProfileProvider`, `learningUnitsProvider`, `subscriptionProvider`, `canAccessUnitUseCaseProvider`, `learnerInsightsProvider` — см. `lib/core/providers/providers.dart`.

**Не ломать:** SRS (`domain/usecases/`), free limits (`subscription_limits.dart`), `FeatureFlags`, parental gate.

### Правила кода (кратко)

Подробности → `nokhchiin/.agents/AGENTS.md`.

- Barrel-файлы (`providers.dart`, `repository_impl.dart`) — только реэкспорт, без логики
- `UserProfileNotifier` — `AsyncNotifier`, не `StateNotifier`
- Игровые числа → `GameplayConstants`, лимиты → `SubscriptionLimits`
- Premium → только `PremiumStatusChecker`
- SRS/DailySync → `{DateTime? now}`, не `DateTime.now()` внутри domain
- Новые поля entities → обновить `props` (Equatable)

---

## Git

- Ветка: `master`
- **Не коммитить и не пушить** без явной просьбы пользователя
- **Не коммитить:** `.env`, ключи, credentials
- Коммиты (если просят):  
  `git -c user.name="Turpalitto" -c user.email="Turpalitto@users.noreply.github.com" commit …`

---

## Тесты

```bash
cd nokhchiin && flutter test
```

Ключевые файлы: `onboarding_screen_test.dart`, `chechen_text_utils_test.dart`, `daily_sync_test.dart`, `access_usecases_test.dart`, `dictionary_parser_test.dart`, `learning_usecases_test.dart`, `spaced_repetition_engine_test.dart`.

---

## Политика монетизации

**До публикации — все ограничения сняты.** Никаких замков, paywall, лимитов.

| Компонент | Статус | Где |
|-----------|--------|-----|
| `FeatureFlags.premiumEnabled` | `false` | `lib/core/config/feature_flags.dart` |
| `SubscriptionLimits.freeUnitMaxOrder` | `9999` | `lib/domain/constants/subscription_limits.dart` |
| `SubscriptionLimits.freeDailyReviewLimit` | `9999` | — |
| `SubscriptionLimits.freeDictionaryBrowseLimit` | `9999` | — |
| `SubscriptionLimits.freeDictionarySearchLimit` | `9999` | — |
| `CanAccessUnitUseCase` | `return true` | `lib/domain/usecases/access_usecases.dart` |
| `CanAccessFeatureUseCase` | `return true` | — |
| `CanStartReviewUseCase` | `return true` | — |
| `isWorldUnlocked()` | `return true` | `lib/core/utils/world_progress_util.dart` |
| Paywall UI | скрыт (`premiumEnabled=false`) | `lib/features/paywall/`, `dictionary_screen`, `profile_screen` |

**Когда будете готовы к публикации:**
1. `FeatureFlags.premiumEnabled = true`
2. Вернуть реальные лимиты в `SubscriptionLimits` (3 юнита, 20 SRS/день, 50 словарь, 20 поиск)
3. Вернуть реальные проверки в `access_usecases.dart` (см. git history до `49fa448`)
4. Вернуть `isWorldUnlocked()` с реальной логикой
5. Проверить paywall + billing flow на реальном устройстве

---

## Частые ошибки (для агентов)

| Проблема | Решение |
|----------|---------|
| IDE не видит preview/tools | Открыть workspace на `C:\dev\deshar-v2\`, не только `nokhchiin/` |
| Белый экран на web | Onboarding через `builder`, не opacity 0 на initial route |
| Словарь не обновлён | `python tools/build_dictionary.py --curate-only --copy-assets` |
| Preview не скроллит словарь | `flex:1; minHeight:0` + `position:absolute; inset:0` на scroll |
| Preview не читает JSON | `vite.config.ts` → `fs.allow: [..]` |
| Дубли `[ХӀоа]` в UI | `DictionaryLabels` / `loadDictionary.ts` |
| `context.iosTokens` не найден | Импорт `design_system.dart` |
| Править JSON словаря вручную | Нет — только через `tools/` |

---

## Чеклист перед сдачей

- [ ] `cd nokhchiin && flutter test`
- [ ] Визуал не трогает providers / SRS / billing
- [ ] Данные словаря — через `build_dictionary.py`
- [ ] Preview и Flutter читают `nokhchiin/assets/data/`
- [ ] Коммит — только по просьбе пользователя

---

## Источник словаря

- [Hugging Face: NM-development/nmd-ce-ru-171k-v0](https://huggingface.co/datasets/NM-development/nmd-ce-ru-171k-v0)
- Учебная лексика: `vocabulary_corrections.json`
