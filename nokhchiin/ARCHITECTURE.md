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
│   ├── services/             # Audio, будущий AI
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
- `audioCeUrl`, `audioRuUrl` (записи носителей)

## Mastery (6 уровней)
`unseen → seen → recognizing → remembering → using → mastered`

## SRS
SM-2 алгоритм в `SpacedRepetitionEngine`. Слова с `needsReview` попадают в экран «Повторение».

## Путь обучения
Юниты в `assets/data/learning_path.json`. Следующий юнит открывается при mastery ≥ `requiredMastery` предыдущего.

## Источники словаря
1. **Мациев А.Г.** — `tools/build_dictionary.py` → PDF парсинг
2. **Алироев И.Ю. (2005)** — curated entries (PDF скан, OCR в roadmap)
3. **curated_vocabulary.json** — проверенная лексика (приоритет)

## Импорт PDF
```bash
cd C:\АББА
python build_dictionary.py
# Обновляет dictionary.json → копируется в nokhchiin/assets/data/
```

## AI (заготовка)
- `AiTutorRepository` — интерфейс готов
- `AiTutorRepositoryStub` — заглушка
- Будущее: генерация упражнений, историй, проверка произношения

## Запуск
```bash
cd nokhchiin
flutter pub get
flutter run
```

## Roadmap
- [ ] OCR словаря Алироева (Tesseract)
- [ ] Иллюстрации единого стиля
- [ ] Записи носителей языка
- [ ] Истории и комиксы
- [ ] Босс-уровни, коллекции, миры
- [ ] AI-преподаватель
