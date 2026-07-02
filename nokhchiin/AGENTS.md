# AGENTS.md — Нохчийн (nokhchiin)

Руководство для AI-агентов и разработчиков. Репозиторий: [Turpalitto/deshar](https://github.com/Turpalitto/deshar).

## Продукт

**Нохчийн** — offline-first приложение для изучения чеченского языка (Flutter, Riverpod, GoRouter, Hive). Два трека: взрослый (SRS, инсайты, культурные капсулы) и детский (игровой формат).

## Стек

- Flutter 3.12+, Dart 3.12+
- `flutter_riverpod` — состояние
- `go_router` — навигация (в т.ч. `StatefulNavigationShell` + таб-бар)
- `hive_flutter` — локальное хранилище
- `google_fonts` (Inter), `flutter_animate`

## Архитектура

```
lib/
  core/
    design/           # Material-виджеты, AppScaffold, AppCard, тема
    design_system/    # iOS/Figma токены и премиум-компоненты
    router/           # GoRouter, fadeScale transitions
    providers/        # Riverpod providers
  features/           # Экраны по доменам (home, games, culture, …)
  domain/             # Entities, use cases, enums
  data/               # Репозитории, JSON в assets/data/
```

### Два слоя дизайна (не смешивать без причины)

| Модуль | Назначение |
|--------|------------|
| `core/design/` | Базовые Material-виджеты, `NokhchiinTheme`, spacing |
| `core/design_system/` | Figma Make визуал: токены, орнамент, tab bar, кнопки, flip-карточки |

Точка входа темы: `main.dart` → `app.dart` → `DesignSystemIntegration.enhanceWithContext` в `MaterialApp.builder`.

## Визуальный эталон — Figma Make

Источник UI (дизайн, иконки, копирайт капсул — **не** бизнес-логика):

- **URL:** https://www.figma.com/make/v2oX5GKxzHgJFcI6l10D7l/Create-app
- **fileKey:** `v2oX5GKxzHgJFcI6l10D7l`

### Токены (синхронизированы с `design_tokens.dart`)

| Светлая тема | Значение |
|--------------|----------|
| background | `#F7F4EF` |
| accent (terracotta) | `#C4724E` |
| surfaceMuted | `#F0EBE4` |
| meadow | `#3D7A5C` |
| gold | `#D4A84B` |
| culture dark | `#1E1510` |

### Компоненты design_system (порт из Figma)

- `NokhchiinAppIcon` — иконка приложения (терракота + горы + «Н»)
- `NokhchiinOrnament` — вайнахский ромбовый паттерн
- `NokhchiinSegmentProgress` — сегментный прогресс урока
- `NokhchiinButton`, `NokhchiinChip`, `NokhchiinSurfaceCard`
- `NokhchiinTabBar` — нижняя навигация (Главная · Миры · Повтор · Профиль)
- `NokhchiinFlipCard` / `NokhchiinFlashcardFace` — карточки
- `NokhchiinQuizOption` — варианты ответа с subtle green/red border

При переносе визуала из Figma **не переписывать**: providers, use cases, SRS, billing, unlock-логику, маршрутизацию.

## Ключевые экраны

| Экран | Файл | Примечание |
|-------|------|------------|
| Home | `features/home/home_screen.dart` | Figma layout: continue CTA, gifts row, XP chart, миры |
| Onboarding | `features/onboarding/onboarding_screen.dart` | «Сайн дог ду хьуна», треки adult/kids |
| Culture capsule | `features/culture/widgets/culture_capsule_card.dart` | Тёмный fullscreen `#1E1510` |
| Games | `features/games/` | Flashcards (flip + swipe), quiz (letter badges) |
| Profile | `features/profile/profile_screen.dart` | Arc ring, stats, weak spot |
| Paywall | `features/paywall/paywall_screen.dart` | Premium features list |
| Insights | `features/insights/` | Взрослый дашборд `/insights` |

## Команды

```bash
flutter pub get
flutter run -d chrome --web-port=7357
flutter test
```

## Git

- Ветка по умолчанию: `master`
- Коммиты (если пользователь просит):  
  `git -c user.name="Turpalitto" -c user.email="Turpalitto@users.noreply.github.com" commit …`
- **Не коммитить и не пушить** без явной просьбы пользователя.

## Тесты

`test/` — unit + widget. После смены копирайта онбординга проверять `onboarding_screen_test.dart` (ожидает Figma-тексты, не только l10n tagline).

## Частые ошибки

- Белый экран на web: `CustomTransitionPage` — не ставить opacity 0 на initial route; onboarding через `builder`, не `pageBuilder`.
- `IosMotion` / `context.iosTokens` — импорт из `core/design_system/design_system.dart`.
- Импорты из `core/design/widgets/`: design_system — `../../design_system/`, domain — `../../../domain/`.
