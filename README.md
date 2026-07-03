# Нохчийн — Платформа изучения чеченского языка

**Репозиторий:** [github.com/Turpalitto/deshar-v2](https://github.com/Turpalitto/deshar-v2) (последняя версия)

## Что создано

### Flutter-приложение (`nokhchiin/`)
Production-ready архитектура уровня Khan Academy + Duolingo:

- **Clean Architecture** — domain / data / features
- **Два режима** — детский (3–6, 6–9, 9–12) и взрослый
- **Mastery Learning** — 6 уровней владения словом
- **SRS (SM-2)** — интервальное повторение
- **Путь обучения** — 11 юнитов с блокировкой до освоения
- **7800+ слов** — Мациев + Алироев (curated) + учебник
- **Мини-игры** — карточки, викторина, пары
- **Словарь** — поиск, транскрипция, избранное (озвучка — за фиче-флагом)
- **Кабинет родителя** — статистика
- **Офлайн** — Hive + assets

### Инструменты (`tools/`)
- `tools/build_dictionary.py` — слияние PDF Мациева + curated + Алироев
- `tools/expand_curated.py` — расширение curated до 1000+ из dictionary.json
- `tools/analyze_dict.py`, `tools/audit_*.py` — аудит словаря
- `tools/output/` — отчёты и промежуточные файлы
- `curated_vocabulary.json` — 1050+ проверенных слов

### Legacy Web (`legacy/`)
Устаревший HTML/JS прототип — заменён Flutter-приложением.

## Запуск

```bash
cd nokhchiin
flutter pub get
flutter run          # Android / iOS / Chrome
flutter run -d chrome
```

## Обновление словаря из PDF

```bash
# Скачайте Maciev_dictionary.pdf в корень репозитория (не в git)
python tools/build_dictionary.py --copy-assets
```

Флаг `--copy-assets` копирует `dictionary.json` и `lessons.json` в `nokhchiin/assets/data/`.

## Источники
- [Мациев А.Г.](https://ps95.ru/wp-content/uploads/2018/07/Maciev_A.G_Chechensko-russkiy_slovar.pdf)
- [Алироев И.Ю. (2005)](https://karchava.wordpress.com/wp-content/uploads/2012/09/aliroev_i_yu_-_chechensko-russky_slovar_-_2005.pdf)

## Документация
См. `nokhchiin/ARCHITECTURE.md`
