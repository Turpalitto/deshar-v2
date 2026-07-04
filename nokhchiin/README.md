# Нохчийн (Deshar v2)

Production-grade, **offline-first** Flutter-приложение для изучения чеченского языка.

## Содержание

- **Платформа:** Flutter (iOS, Android, Web)
- **Аудитория:** взрослый трек (SRS, инсайты, культура) + детский (игры)
- **Данные:** JSON в `assets/data/`, прогресс в Hive
- **Словарь:** ~5 500 проверенных пар чеченский↔русский

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
dart analyze lib/
```

Покрыты: spaced repetition engine, парсер словаря, access/learning use cases, onboarding.

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

Таб-бар: `/` Home · `/worlds` · `/review` · `/profile`
Также: `/splash`, `/onboarding`, `/dictionary`, `/path`, `/insights`, `/paywall`, `/parent`, games, stories, boss, `/legal/{privacy,terms}`.

## Данные

`assets/data/` — источник правды для приложения:
- `dictionary.json` — словарь
- `curated_vocabulary.json` — verified + lesson-слова
- `lessons.json` — уроки
- `learning_path.json` — юниты Path (с `enabled: false` для нереализованных)
- `worlds.json`, `collections.json`, `stories.json`, `bosses.json` — контент

Пайплайн словаря: `tools/sanitize_dictionary.py --copy-root` (из корня workspace).

## Документация

- `AGENTS.md` (корень workspace) — точка входа для IDE/агентов
- `nokhchiin/.agents/AGENTS.md` — детальные правила Flutter
- `design.md`, `todo.md` — архитектура и задачи

## Лицензия

Приватный проект Deshar Premium.
