#!/usr/bin/env python3
"""Extract Chechen-Russian vocabulary from Maciev A.G. dictionary PDF."""
import re
import json
import fitz

PDF_PATH = r"C:\АББА\Maciev_dictionary.pdf"
OUT_JSON = r"C:\АББА\dictionary.json"
OUT_LESSONS = r"C:\АББА\lessons_data.json"

SKIP_MARKERS = (
    "понуд.", "потенц.", "прил.", "см. ", "масд.", "прич.", "нареч.",
    "деепр.", "звукоподр.", "мн. от ", "эрг. п.", "перен.",
    "субъект ", "объект ", "только мн.", "лингв.", "геогр.", "рел.",
    "с.-х.", "мед.", "воен.", "полит.", "экон.", "ист.", "физ.",
    "мор.", "бот.", "зоол.", "хим.", "мат.", "спорт.", "муз.",
)

# Curated lessons: chechen headword (lowercase) -> lesson config
CURATED_LESSONS = {
    "greetings": {
        "title": "Приветствия", "chechenTitle": "Маршалла", "icon": "👋",
        "color": "linear-gradient(135deg, #10b981, #06b6d4)",
        "words": [
            ("маршалла", "Привет / Здравствуйте", "👋", "Традиционное чеченское пожелание мира"),
            ("баркалла", "Спасибо", "🙏", "Выражение благодарности"),
            ("Ӏуьйре дика", "Доброе утро", "🌅", "Пожелание благословенного утра"),
            ("де дика", "Добрый день", "☀️", "Приветствие днём"),
            ("суьйре дика", "Добрый вечер", "🌇", "Вечернее приветствие"),
            ("марша Ӏайла", "До свидания", "🚶", "Пожелание оставаться с миром"),
            ("хьоьга баркалла", "Тебе спасибо", "💚", "Благодарность конкретному человеку"),
            ("дика ду", "Хорошо", "👍", "Всё в порядке"),
            ("вайн дерриг", "Всего доброго", "✨", "Пожелание на прощание"),
        ],
    },
    "animals": {
        "title": "Животные", "chechenTitle": "Дийнаташ", "icon": "🐾",
        "color": "linear-gradient(135deg, #f59e0b, #ea580c)",
        "words": [
            ("цициг", "Кошка", "🐱", "Домашнее животное"),
            ("жӀаьла", "Собака", "🐶", "Верный друг человека"),
            ("говр", "Лошадь", "🐴", "Гордое горное животное"),
            ("борз", "Волк", "🐺", "Символ смелости и силы"),
            ("ча", "Медведь", "🐻", "Хозяин леса"),
            ("цхьогал", "Лиса", "🦊", "Хитрое рыжее животное"),
            ("лу", "Олень", "🦌", "Горный обитатель"),
            ("цӀокъ", "Барс", "🐆", "Снежный леопард Кавказа"),
            ("гаттар", "Корова", "🐄", "Даёт молоко"),
            ("беж", "Овца", "🐑", "Стадное животное"),
            ("никх", "Пчела", "🐝", "Трудолюбивое насекомое"),
            ("котам", "Петух", "🐓", "Просыпается первым"),
        ],
    },
    "colors": {
        "title": "Цвета", "chechenTitle": "Бесаш", "icon": "🎨",
        "color": "linear-gradient(135deg, #ec4899, #f43f5e)",
        "words": [
            ("цӀе", "Красный", "🔴", "Цвет огня и роз"),
            ("сийна", "Синий", "🔵", "Цвет неба и моря"),
            ("баьццара", "Зелёный", "🟢", "Цвет травы и листьев"),
            ("можа", "Жёлтый", "🟡", "Цвет солнца"),
            ("кӀайн", "Белый", "⚪", "Цвет снега"),
            ("Ӏаьржа", "Чёрный", "⚫", "Цвет ночи"),
            ("сироз", "Серый", "🩶", "Нейтральный цвет"),
            ("кӀайн-можа", "Белый и жёлтый", "🌼", "Светлые оттенки"),
        ],
    },
    "numbers": {
        "title": "Числа (1–10)", "chechenTitle": "Терахьаш", "icon": "🔢",
        "color": "linear-gradient(135deg, #3b82f6, #4f46e5)",
        "words": [
            ("цхьаъ", "Один (1)", "1️⃣", "Первая цифра"),
            ("шиъ", "Два (2)", "2️⃣", "Пара"),
            ("кхоъ", "Три (3)", "3️⃣", "Тройка"),
            ("диъ", "Четыре (4)", "4️⃣", "Четвёрка"),
            ("пхиъ", "Пять (5)", "5️⃣", "Пять пальцев"),
            ("ялх", "Шесть (6)", "6️⃣", "Шесть граней кубика"),
            ("ворхӀ", "Семь (7)", "7️⃣", "Семь цветов радуги"),
            ("бархӀ", "Восемь (8)", "8️⃣", "Восемь"),
            ("исс", "Девять (9)", "9️⃣", "Девять"),
            ("итт", "Десять (10)", "🔟", "Десять пальцев"),
        ],
    },
    "family": {
        "title": "Семья", "chechenTitle": "Доьзал", "icon": "❤️",
        "color": "linear-gradient(135deg, #10b981, #059669)",
        "words": [
            ("нана", "Мама", "👩", "Мать"),
            ("да", "Папа", "👨", "Отец"),
            ("ваша", "Брат", "👦", "Брат"),
            ("йиша", "Сестра", "👧", "Сестра"),
            ("деда", "Дедушка", "👴", "Дед по отцу"),
            ("денана", "Бабушка", "👵", "Бабушка"),
            ("бен", "Сын", "👶", "Ребёнок мужского пола"),
            ("йоь", "Дочь", "👧", "Ребёнок женского пола"),
            ("доьзал", "Семья", "👨‍👩‍👧", "Родные люди"),
            ("зуда", "Жена", "💍", "Супруга"),
            ("маьла", "Муж", "💍", "Супруг"),
        ],
    },
    "food": {
        "title": "Еда и напитки", "chechenTitle": "Кхача", "icon": "🍎",
        "color": "linear-gradient(135deg, #8b5cf6, #6d28d9)",
        "words": [
            ("хи", "Вода", "💧", "Источник жизни"),
            ("шура", "Молоко", "🥛", "Полезный напиток"),
            ("бепиг", "Хлеб", "🍞", "Главный продукт"),
            ("чай", "Чай", "🍵", "Горячий напиток"),
            ("Ӏаж", "Яблоко", "🍏", "Сочный фрукт"),
            ("жижиг", "Мясо", "🥩", "Богатырская сила"),
            ("кхаж", "Суп", "🍲", "Горячее блюдо"),
            ("хьажу", "Сыр", "🧀", "Молочный продукт"),
            ("кхи", "Рыба", "🐟", "Морской деликатес"),
            ("картоф", "Картофель", "🥔", "Овощ"),
        ],
    },
    "nature": {
        "title": "Природа", "chechenTitle": "Ӏалам", "icon": "🌳",
        "color": "linear-gradient(135deg, #06b6d4, #0e7490)",
        "words": [
            ("маьлхан", "Солнце", "☀️", "Согревает землю"),
            ("лам", "Гора", "🏔️", "Вершины Кавказа"),
            ("зезаг", "Цветок", "🌷", "Красота природы"),
            ("хьун", "Лес", "🌲", "Дом зверей"),
            ("стигал", "Небо", "🌌", "Над головой"),
            ("догӀа", "Дождь", "🌧️", "Поит растения"),
            ("лё", "Снег", "❄️", "Белое покрывало"),
            ("хьаст", "Ветер", "💨", "Дует с гор"),
            ("хи", "Вода / Река", "🌊", "Течёт по долинам"),
            ("Ӏалам", "Природа / Мир", "🌍", "Всё вокруг нас"),
        ],
    },
    "body": {
        "title": "Тело", "chechenTitle": "Ден", "icon": "🫀",
        "color": "linear-gradient(135deg, #f43f5e, #be123c)",
        "words": [
            ("корта", "Голова", "🗣️", "Главная часть тела"),
            ("бӀаьрга", "Глаз", "👁️", "Орган зрения"),
            ("лерг", "Ухо", "👂", "Орган слуха"),
            ("муьга", "Нос", "👃", "Обоняние"),
            ("бага", "Рот", "👄", "Для еды и речи"),
            ("когӀам", "Рука", "✋", "Пять пальцев"),
            ("когӀам бӀаьрга", "Палец", "☝️", "На руке"),
            ("куьг", "Нога", "🦵", "Для ходьбы"),
            ("белш", "Сердце", "❤️", "Бьётся в груди"),
            ("кхи", "Кровь", "🩸", "Течёт по венам"),
        ],
    },
    "home": {
        "title": "Дом и быт", "chechenTitle": "ЦӀий", "icon": "🏠",
        "color": "linear-gradient(135deg, #6366f1, #4338ca)",
        "words": [
            ("цӀий", "Дом", "🏠", "Жилище"),
            ("хьаьжкхечо", "Комната", "🛋️", "Помещение в доме"),
            ("хьаьж", "Окно", "🪟", "Свет в дом"),
            ("наьӀар", "Дверь", "🚪", "Вход в дом"),
            ("стол", "Стол", "🪑", "За ним едят"),
            ("гӀант", "Стул", "💺", "Сиденье"),
            ("дешар", "Книга", "📚", "Источник знаний"),
            ("къолам", "Ручка / Карандаш", "✏️", "Для письма"),
            ("газета", "Газета", "📰", "Новости"),
            ("дешар", "Школа", "🏫", "Место учёбы"),
        ],
    },
    "verbs": {
        "title": "Глаголы", "chechenTitle": "Дешар", "icon": "⚡",
        "color": "linear-gradient(135deg, #eab308, #ca8a04)",
        "words": [
            ("ваха", "Идти / Пойти", "🚶", "Движение пешком"),
            ("гӀирса", "Бежать", "🏃", "Быстрое движение"),
            ("лаьш", "Сидеть", "🪑", "Принимать сидячую позу"),
            ("тӀаьхьа", "Стоять", "🧍", "Находиться на ногах"),
            ("Ӏойла", "Спать", "😴", "Ночной отдых"),
            ("Ӏа", "Есть / Кушать", "🍽️", "Принимать пищу"),
            ("мийла", "Пить", "🥤", "Утолять жажду"),
            ("дийца", "Говорить", "💬", "Общаться словами"),
            ("деша", "Читать", "📖", "Воспринимать текст"),
            ("язда", "Писать", "✍️", "Создавать текст"),
            ("хьажа", "Смотреть", "👀", "Наблюдать глазами"),
            ("луш", "Слушать", "👂", "Воспринимать звуки"),
        ],
    },
}


def remove_stress(text: str) -> str:
    """Remove Maciev dictionary stress marks (space before stressed syllable)."""
    prev = None
    while prev != text:
        prev = text
        # Merge: letter + space + short syllable fragment (1-4 chars)
        text = re.sub(
            r"([а-яА-ЯёЁa-zA-Z])( [а-яёЁa-zA-Z]{1,4})(?=[\s;,.\)\]◊]|$)",
            r"\1\2",
            text,
        )
    return text


def clean_russian(raw: str) -> str:
    raw = remove_stress(raw)
    raw = re.sub(r"\s+", " ", raw).strip()
    raw = re.sub(r"^\d+\)\s*", "", raw)
    raw = re.sub(r"\[.*?\]", "", raw)
    raw = re.sub(r"\(.*?\)", "", raw)
    raw = re.sub(r"[◊].*$", "", raw)
    raw = raw.split(";")[0].strip()
    # Keep only first meaning if comma-separated synonyms
    if "," in raw and len(raw.split(",")) > 2:
        raw = raw.split(",")[0].strip()
    return raw.strip(" .,;:")


def capitalize_chechen(word: str) -> str:
    if not word:
        return word
    return word[0].upper() + word[1:]


def is_valid_chechen(word: str) -> bool:
    if not word or len(word) < 2 or len(word) > 35:
        return False
    if any(c in word for c in "[]()◊"):
        return False
    if re.search(r"[ыэюяёЫЭЮЯЁ]", word) and "Ӏ" not in word:
        return False
    # Must contain Chechen-specific chars or be pure Chechen alphabet
    if not re.search(r"[а-яА-ЯӀьъ]", word):
        return False
    return True


def is_valid_russian(text: str) -> bool:
    if not text or len(text) < 2 or len(text) > 60:
        return False
    if text.lower().startswith(("от ", "к ", "см.", "см ")):
        return False
    # Must contain Cyrillic
    if not re.search(r"[а-яА-ЯёЁ]", text):
        return False
    return True


def parse_entry_line(line: str) -> tuple[str, str] | None:
    line = line.strip()
    if not line or len(line) < 4:
        return None
    if re.match(r"^\d+\.?\s*$", line):
        return None

    for marker in SKIP_MARKERS:
        if marker in line.lower():
            return None

    if line.startswith(("а) ", "б) ", "в) ", "г) ", "◊")):
        return None

    # Skip page numbers
    if re.match(r"^\d{1,3}$", line):
        return None

    match = re.match(
        r"^([а-яА-ЯӀьъa-zA-Z0-9\-\s]+?)"
        r"(?:\s+\[[^\]]*\])?"
        r"\s+(.+)$",
        line,
    )
    if not match:
        return None

    chechen = match.group(1).strip()
    rest = match.group(2)

    if not is_valid_chechen(chechen):
        return None

    bracket_end = rest.find("]")
    if bracket_end != -1:
        rest = rest[bracket_end + 1:].strip()

    meaning = re.search(r"(?:^|\s)1\)\s*(.+)", rest)
    if meaning:
        russian = clean_russian(meaning.group(1))
    else:
        russian = clean_russian(rest)

    if not is_valid_russian(russian):
        return None

    chechen = re.sub(r"\s+", " ", chechen).strip()
    chechen = re.sub(r"\d+$", "", chechen).strip()

    return chechen, russian


def simple_pronunciation(chechen: str) -> str:
    if len(chechen) <= 5:
        return chechen
    mid = len(chechen) // 2
    return chechen[:mid] + "-" + chechen[mid:]


def lookup_entry(entries_map: dict, chechen_key: str) -> dict | None:
    key = chechen_key.lower().replace(" ", "")
    for k, v in entries_map.items():
        if k.lower().replace(" ", "") == key:
            return v
    return None


def main():
    doc = fitz.open(PDF_PATH)
    entries_map: dict[str, dict] = {}

    start_page = 30
    end_page = doc.page_count - 10

    for page_num in range(start_page, end_page):
        text = doc[page_num].get_text()
        for line in text.split("\n"):
            parsed = parse_entry_line(line.strip())
            if not parsed:
                continue
            chechen, russian = parsed
            key = chechen.lower()
            if key not in entries_map:
                entries_map[key] = {
                    "chechen": capitalize_chechen(chechen),
                    "russian": russian[0].upper() + russian[1:] if russian else russian,
                    "pronunciation": simple_pronunciation(chechen),
                }

    all_list = sorted(entries_map.values(), key=lambda x: x["chechen"].lower())

    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(
            {
                "source": "Мациев А.Г. Чеченско-русский словарь",
                "sourceUrl": "https://ps95.ru/wp-content/uploads/2018/07/Maciev_A.G_Chechensko-russkiy_slovar.pdf",
                "totalEntries": len(all_list),
                "entries": all_list,
            },
            f,
            ensure_ascii=False,
        )

    # Build curated lessons, enriching from dictionary when available
    lesson_output = []
    used_chechen = set()

    for lesson_id, cfg in CURATED_LESSONS.items():
        words = []
        for item in cfg["words"]:
            chechen_key, russian, emoji, hint = item[0], item[1], item[2], item[3]
            key_norm = chechen_key.lower().replace(" ", "")
            if key_norm in used_chechen:
                continue
            used_chechen.add(key_norm)

            dict_entry = lookup_entry(entries_map, chechen_key)
            chechen_display = dict_entry["chechen"] if dict_entry else capitalize_chechen(chechen_key)
            russian_display = russian  # prefer curated translation
            pronunciation = dict_entry["pronunciation"] if dict_entry else simple_pronunciation(chechen_key)

            words.append({
                "chechen": chechen_display,
                "russian": russian_display,
                "pronunciation": pronunciation,
                "emoji": emoji,
                "hint": hint,
            })

        if len(words) >= 3:
            lesson_output.append({
                "id": lesson_id,
                "title": cfg["title"],
                "chechenTitle": cfg["chechenTitle"],
                "icon": cfg["icon"],
                "color": cfg["color"],
                "words": words,
            })

    with open(OUT_LESSONS, "w", encoding="utf-8") as f:
        json.dump(lesson_output, f, ensure_ascii=False, indent=2)

    import os
    size_kb = os.path.getsize(OUT_JSON) // 1024
    print(f"Extracted {len(all_list)} dictionary entries ({size_kb} KB)")
    print(f"Built {len(lesson_output)} curated lessons")


if __name__ == "__main__":
    main()
