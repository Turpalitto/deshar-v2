# Нохчийн — Архитектура платформы

## Видение
Лучшая в мире платформа для изучения чеченского языка: дети учатся через игру, взрослые — через эффективную систему mastery + SRS.

## Стек
- **Flutter 3.44** — Android, iOS, Web, планшеты
- **Riverpod** — состояние
- **GoRouter** — навигация
- **Hive** — офлайн-хранилище прогресса
- **Google Fonts (Manrope)** — единая типографика с поддержкой чеченской кириллицы

## Clean Architecture (Feature-first)

```
lib/
├── main.dart                 # Entry + Hive init
├── app.dart                  # MaterialApp.router
├── core/
│   ├── design/               # Material shell, тема, токены, общие виджеты
│   ├── design_system/        # iOS/Figma-компоненты и адаптивные поверхности
│   ├── router/               # GoRouter
│   ├── providers/            # DI через Riverpod
│   ├── services/             # Analytics, crash reporting, notifications
│   └── widgets/              # Переиспользуемые UI
├── domain/
│   ├── entities/             # Word, Progress, User, Unit, DailySession
│   ├── repositories/         # Абстракции (порты)
│   ├── services/             # SRS Engine
│   └── usecases/             # Review, Unlock, Mastery
├── data/
│   ├── datasources/          # Assets JSON, Hive boxes
│   └── repositories/         # Имплементации
└── features/
    ├── onboarding/           # Выбор режима + возраст
    ├── home/                 # Dashboard
    ├── learning_path/        # Путь + юниты
    ├── dictionary/           # Поиск, фильтры
    ├── games/                # Карточки, викторина, пары
    ├── review/               # SRS повторение
    ├── parent/               # Кабинет родителя
    └── profile/              # Настройки
```

## Модель слова (WordEntity)
Каждое слово — отдельная сущность:
- `chechen`, `russian`, `pronunciation`
- `partOfSpeech`, `category`, `exampleCe/Ru`
- `synonyms`, `sources[]`, `tags[]`
- `emoji`, `illustrationKey`
- `audioId` — ссылка на проверенный клип из `audio_manifest.json`

## Mastery (6 уровней)
`unseen → seen → recognizing → remembering → using → mastered`

## SRS
SM-2 алгоритм в `SpacedRepetitionEngine`. Слова с `needsReview` попадают в экран «Повторение».

Первое знакомство проходит через `MarkWordSeenUseCase`; активный ответ — через
`ReviewWordUseCase`. Детское занятие оценивает каждое слово, а разговорная
викторина передаёт правильные и ошибочные ответы в тот же SRS.

## Офлайн-состояние

Hive хранит четыре независимых набора данных:

- `user_profile_v1` — профиль, серия, XP и дневные счётчики;
- `word_progress_v1` — SRS, избранное и принадлежность колодам;
- `decks_v1` — пользовательские колоды;
- `daily_sessions_v1` — фактические дневные задачи, слова, баллы и минуты.

Старые Map-записи читаются с безопасными значениями по умолчанию. Ошибка записи
прогресса или профиля пробрасывается в вызывающий код и не маскируется как успех.

## Аудио

`ChechenAudioService` валидирует manifest, диктора, диалект, лицензию, согласие
и SHA-256. Аудиоконтролы доступны в карточках, словаре, SRS, викторинах,
разговорнике и детском занятии. Публичный manifest пока не содержит клипов, а
production playback gateway ещё не подключён: UI показывает честное
«Аудио пока недоступно».

## Путь обучения
Юниты в `assets/data/learning_path.json`. Следующий юнит открывается при mastery ≥ `requiredMastery` предыдущего.

## Источники словаря
1. **Hugging Face `NM-development/nmd-ce-ru-171k-v0`** — единственный
   источник полного словаря; Библия исключается при сборке.
2. **`vocabulary_corrections.json`** — ручные, проверенные исправления
   учебной лексики.
3. **`curated_vocabulary.json`** — собранный набор приоритетных слов для
   уроков и игр.

Словарь обновляется воспроизводимо из корня монорепозитория:

```bash
python tools/build_dictionary.py --hf-dataset NM-development/nmd-ce-ru-171k-v0 --copy-assets
# или только curated-слой, если полный dictionary.json уже есть:
python tools/build_dictionary.py --curate-only --copy-assets
```

Культурные интерлюдии находятся в `assets/data/culture_capsules.json`;
контент можно вычитывать и расширять без изменения Flutter-кода.

## Запуск
```bash
cd nokhchiin
flutter pub get
flutter run
```

## Текущее покрытие продукта
- [x] Словарь — Hugging Face nmd-ce-ru-171k-v0 + curated overrides
- [x] 15 учебных юнитов и 15 связанных культурных капсул
- [x] SRS, 4 игровые механики, 8 миров, 4 коллекции и 3 босс-уровня
- [x] 2 интерактивные истории; требуется расширение после вычитки носителями
- [~] Единый иллюстративный язык — бренд-сцена и культурные изображения готовы,
  тематические иллюстрации пополняются постепенно
- [x] Детские занятия сохраняют SRS, XP, минуты и дневную историю
- [x] История «Сегодня» читает сохранённые сессии, а не пересчитывает прошлое
- [x] Строгий CI: formatter, analyze, тесты, 60% domain/data, аудиты, web,
  Android build и integration-сценарии
- [~] Аудиоинтерфейс и политика готовы; записи носителей и playback gateway
  остаются главным блокером Audio Beta

Редакционные требования и критерии готовности описаны в `PRODUCT_QUALITY.md`.
