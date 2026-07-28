# Нохчийн — Платформа изучения чеченского языка

**Репозиторий:** [github.com/Turpalitto/deshar-v2](https://github.com/Turpalitto/deshar-v2) (последняя версия)

## Что создано

### Flutter-приложение (`nokhchiin/`)
Production-ready архитектура уровня Khan Academy + Duolingo:

- **Clean Architecture** — domain / data / features
- **Два режима** — детский (3–6, 6–9, 9–12) и взрослый
- **Возрастные занятия** — картинка/аудио, распознавание или активный ввод
- **Mastery Learning** — 6 уровней владения словом
- **SRS (SM-2)** — интервальное повторение
- **Путь обучения** — 15 юнитов с блокировкой до освоения
- **134 000+ слов/фраз** — Hugging Face nmd-ce-ru-171k-v0 (Bible исключён)
- **145 curated-записей** — учебное ядро с явным уровнем редакционной проверки
- **Мини-игры** — карточки, викторина, пары
- **Словарь** — поиск, транскрипция, избранное
- **Культурные капсулы** — 15 коротких интерлюдий, по одной для каждого юнита
- **Кабинет родителя** — статистика
- **Реальная история занятий** — слова, задачи, результат, повторения и минуты
- **Офлайн** — Hive + assets
- **Release gate** — формат, analyze, тесты, контентные аудиты, web и Android

Аудиоинтерфейс, политика записей носителей и manifest реализованы. Публичный
каталог записей пока пуст, поэтому приложение честно показывает состояние
«Аудио пока недоступно». Весь учебный контент пока открыт: без активного
paywall, лимитов и закрытых уровней.

### Инструменты (`tools/`)
- `tools/build_dictionary.py` — импорт из HF датасета + сборка curated
- `tools/audit_emoji_vocabulary.py` — валидация curated
- `tools/output/` — отчёты и long-form записи

### Legacy Web (`legacy/`)
Устаревший HTML/JS прототип — заменён Flutter-приложением.

## Запуск

```bash
cd nokhchiin
flutter pub get
flutter run          # Android / iOS / Chrome
flutter run -d chrome
flutter test --coverage
flutter analyze
```

Контент и платформенные сборки проверяются командами:

```bash
python tools/validate_content.py
python tools/audit_dictionary_package.py
cd nokhchiin
flutter build web --no-tree-shake-icons
flutter build apk --debug
```

## Обновление словаря

```bash
# Полный импорт из Hugging Face датасета
pip install datasets pandas pyarrow
python tools/build_dictionary.py --hf-dataset NM-development/nmd-ce-ru-171k-v0 --copy-assets

# Или пересборка curated без перезагрузки датасета
python tools/build_dictionary.py --curate-only --copy-assets
```

Флаг `--copy-assets` копирует `dictionary.json` и `curated_vocabulary.json` в `nokhchiin/assets/data/`.

## Источник данных
- [Hugging Face: NM-development/nmd-ce-ru-171k-v0](https://huggingface.co/datasets/NM-development/nmd-ce-ru-171k-v0)

## Документация
См. `nokhchiin/ARCHITECTURE.md`
