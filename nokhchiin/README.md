# Нохчийн (Deshar v2)

Production-grade, **offline-first** Flutter-приложение для изучения чеченского языка.

## Содержание

- **Платформа:** Flutter (iOS, Android, Web)
- **Аудитория:** взрослый трек (SRS, инсайты, культура) + детский (игры)
- **Данные:** JSON в `assets/data/`, прогресс в Hive
- **Словарь:** ~134 000 пар из Hugging Face + приоритетный проверяемый curated-слой
- **Детский цикл:** три возрастные механики с SRS и сохранением результата
- **История:** фактически завершённые дневные задачи хранятся в Hive
- **Аудио:** UI и политика готовы, каталог записей носителей пока пуст

## Запуск

```bash
flutter pub get
flutter run -d chrome --web-port=7357    # web
flutter run -d <device>                   # iOS/Android
```

### Sentry (опционально)

DSN передаётся через `--dart-define`. Без него `AppLogger` fallback на `debugPrint`.

```bash
flutter run --dart-define=SENTRY_DSN=your_dsn_here
```

## Тесты и аудит

```bash
flutter test
flutter analyze
python ../tools/validate_content.py
python ../tools/audit_dictionary_package.py
```

CI дополнительно требует не менее 60% покрытия строк `domain/data`, собирает web
и Android debug APK. Покрыты SRS, словарь, детский цикл, дневные сессии,
разговорная практика, onboarding, billing/paywall и ключевые маршруты.

## Архитектура

Clean Architecture: `domain → data → core → features`.

```
lib/
  core/
    design/           # Material: AppScaffold, AppShell, тема, SVG
    design_system/    # Figma/iOS: iosTokens, NokhchiinButton, FlipCard
    router/           # GoRouter
    providers/        # Riverpod
    services/         # Audio, billing, analytics
    utils/            # chechen_text_utils, dictionary_labels
    config/           # feature_flags
  features/           # Экраны (home, games, dictionary, culture, …)
  domain/             # Entities, use cases, abstract repos
  data/               # Repository impl, parsers, Hive
```

Два слоя дизайна: `core/design/` (Material, kids/культура) и `core/design_system/` (iOS/Figma, adult-трек). Adult-трек = визуальный язык Deshar (зелёный primary `#1B6B4A`).

## Маршруты (GoRouter)

Таб-бар: `/` Home · `/collections` · `/dictionary` · `/profile`.
Также: `/splash`, `/onboarding`, `/path`, `/today/*`, `/review`, `/parent`,
games, stories, boss, `/paywall` и `/legal/{privacy,terms}`. Premium-флаг
выключен, но маршрут paywall и возврат на исходный экран уже проверяются.

## Данные

`assets/data/` — источник правды для приложения:
- `dictionary.json` — словарь
- `curated_vocabulary.json` — verified + lesson-слова
- `lessons.json` — уроки
- `learning_path.json` — юниты Path (с `enabled: false` для нереализованных)
- `worlds.json`, `collections.json`, `stories.json`, `bosses.json` — контент

Пайплайн словаря запускается из корня workspace:

```bash
python tools/build_dictionary.py --hf-dataset NM-development/nmd-ce-ru-171k-v0 --copy-assets
python tools/build_dictionary.py --curate-only --copy-assets
```

Приложение читает подготовленные assets локально и не зависит от сети во время обучения.
Профиль, SRS, колоды и `DailySessionEntity` сохраняются в отдельных Hive-box.

## Документация

- `AGENTS.md` (корень workspace) — точка входа для IDE/агентов
- `nokhchiin/.agents/AGENTS.md` — детальные правила Flutter
- `ARCHITECTURE.md` — актуальная архитектура и источники данных
- `PRODUCT_QUALITY.md` — продуктовые и редакторские критерии качества

## Лицензия

Приватный проект Deshar Premium.
