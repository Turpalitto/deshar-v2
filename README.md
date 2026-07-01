# Нохчийн — Платформа изучения чеченского языка

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
- **Словарь** — поиск, озвучка, избранное
- **Кабинет родителя** — статистика
- **Офлайн** — Hive + assets

### Инструменты (`tools/`)
- `build_dictionary.py` — слияние PDF Мациева + curated + Алироев
- `curated_vocabulary.json` — 108 проверенных слов (полные формы)

### Legacy Web (`index.html`)
Прототип в корне — заменён Flutter-приложением.

## Запуск

```bash
cd nokhchiin
flutter pub get
flutter run          # Android / iOS / Chrome
flutter run -d chrome
```

## Обновление словаря из PDF

```bash
python build_dictionary.py
Copy-Item dictionary.json nokhchiin/assets/data/
Copy-Item lessons_data.json nokhchiin/assets/data/lessons.json
```

## Источники
- [Мациев А.Г.](https://ps95.ru/wp-content/uploads/2018/07/Maciev_A.G_Chechensko-russkiy_slovar.pdf)
- [Алироев И.Ю. (2005)](https://karchava.wordpress.com/wp-content/uploads/2012/09/aliroev_i_yu_-_chechensko-russky_slovar_-_2005.pdf)

## Документация
См. `nokhchiin/ARCHITECTURE.md`
