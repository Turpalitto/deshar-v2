# Нохчийн — Архитектура платформы

## Видение
Лучшая в мире платформа для изучения чеченского языка: дети учатся через игру, взрослые — через эффективную систему mastery + SRS.

## Стек
- **Flutter 3.44** — Android, iOS, Web, планшеты
- **Riverpod** — состояние
- **GoRouter** — навигация
- **Hive** — офлайн-хранилище прогресса
- **Google Fonts (Nunito)** — премиальная типографика

## Clean Architecture (Feature-first)

```
lib/
├── main.dart                 # Entry + Hive init
├── app.dart                  # MaterialApp.router
├── core/
│   ├── theme/                # Дизайн-система 2026
│   ├── router/               # GoRouter
│   ├── providers/            # DI через Riverpod
│   ├── services/             # Analytics, crash reporting, notifications
│   └── widgets/              # Переиспользуемые UI
├── domain/
│   ├── entities/             # Word, Progress, User, Unit
│   ├── repositories/         # Абстракции (порты)
│   ├── services/             # SRS Engine
│   └── usecases/             # Review, Unlock, Mastery
├── data/
│   ├── datasources/          # Assets JSON, Hive
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
- `emoji`, `illustrationKey` (будущие иллюстрации)
- `audioCeUrl`, `audioRuUrl` — зарезервированные nullable-поля модели; в текущей сборке аудио нет

## Mastery (6 уровней)
`unseen → seen → recognizing → remembering → using → mastered`

## SRS
SM-2 алгоритм в `SpacedRepetitionEngine`. Слова с `needsReview` попадают в экран «Повторение».

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

## Roadmap
- [x] Словарь — Hugging Face nmd-ce-ru-171k-v0 (заменил PDF/OCR)
- [~] Иллюстрации единого стиля — первая культурная пара добавлена; нужны
  изображения для остальных учебных тем после редакторской вычитки.
- [ ] Записи носителей языка
- [ ] Истории и комиксы
- [ ] Босс-уровни, коллекции, миры
