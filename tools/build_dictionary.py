#!/usr/bin/env python3
"""Единственный источник правды для словаря приложения.

Строит `dictionary.json` и `curated_vocabulary.json` ИСКЛЮЧИТЕЛЬНО из
Hugging Face датасета NM-development/nmd-ce-ru-171k-v0
(https://huggingface.co/datasets/NM-development/nmd-ce-ru-171k-v0).

Заменяет собой весь старый Maciev/Aliroev PDF+OCR пайплайн
(extract_dictionary.py, ocr_aliroev.py, dictionary_quality.py,
sanitize_dictionary.py, build_dictionary.py(old), expand_curated.py) —
эти файлы удалены, история — в git.

Режимы запуска
---------------

1. С нуля из датасета (основной путь):

    pip install datasets pandas pyarrow --break-system-packages
    python tools/build_dictionary.py --hf-dataset NM-development/nmd-ce-ru-171k-v0

   Скрипт сам скачает датасет через `datasets.load_dataset` (сеть нужна
   только на этом шаге). Либо, если parquet уже скачан вручную:

    python tools/build_dictionary.py --parquet path/to/train.parquet

2. Пересборка `curated_vocabulary.json` без повторного импорта (если
   `dictionary.json` уже актуален и трогать его не нужно):

    python tools/build_dictionary.py --curate-only

Что делает
----------

1. Импорт: исключает Bible-строки, чистит пробелы, убирает точные и
   near-дубли (нормализация регистра/пробелов/пунктуации перед сравнением),
   отрезает экстремально длинные записи (>200 символов чеченского текста —
   это ~3.5% строк, но ~24% объёма: многостраничные цитаты, а не словарные
   пары) в отдельный `dictionary_extra_sentences.json` (не бандлится в
   приложение, хранится отдельно на случай, если пригодится позже).
2. Компактная сериализация: НЕ хранит поля, если они равны дефолтному
   значению (`hint` == шаблон "Слово из словаря: {ru}", `emoji` == "📖",
   `quality` == 100, `category` == null) — экономит ~60% размера файла без
   потери информации (Dart/TS слой уже понимает эти поля как optional
   с такими дефолтами).
3. Кураторская выборка: строит `curated_vocabulary.json` — вручную
   провалидированные overrides (`vocabulary_corrections.json`) как
   гарантированно верное ядро + прицельный майнинг под все 15 юнитов
   курса (`nokhchiin/assets/data/learning_path.json`), включая 5 ранее
   пустых (school, adjectives, phrases, dialogues, stories). Майнинг —
   ТОЛЬКО точный lookup существующих ru-переводов в уже импортированном
   датасете — никаких свободных эвристик по кускам текста, которые раньше
   приводили к перепутанным парам вроде "Спасибо -> Баркалла" (см. audit).

Usage:
    python build_dictionary.py --hf-dataset NM-development/nmd-ce-ru-171k-v0 --copy-assets
    python build_dictionary.py --parquet ./nmd_ce_ru.parquet --copy-assets
    python build_dictionary.py --curate-only --copy-assets
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "nokhchiin" / "assets" / "data"

MAX_CHECHEN_LEN = 200  # длинные записи (литература/цитаты) уходят отдельно
EMOJI_DEFAULT = "📖"
QUALITY_DEFAULT = 100
HINT_TEMPLATE = "Слово из словаря: {ru}"


# --------------------------------------------------------------------------
# 1. Импорт из HF датасета
# --------------------------------------------------------------------------

def map_source(src: str) -> str:
    s = (src or "").strip().lower()
    table = {
        "matsiev": "maciev", "maciev": "maciev",
        "aliroev": "aliroev",
        "bersanov": "bersanov", "anatomy": "bersanov",
        "computer": "computer",
        "num2words": "num2words", "savoirfairelinux": "num2words",
        "baltoslav": "baltoslav",
        "daymohk": "daymohk",
        "gatitos": "gatitos",
        "radio marsho": "radio", "radiomarsho": "radio",
    }
    for key, val in table.items():
        if key in s:
            return val
    if any(k in s for k in ("bakarov", "aydamirov", "abuzar", "zelimkhan")):
        return "literature"
    if any(k in s for k in ("bible", "synodal", "institute of bible")):
        return "bible"
    return "other"


def is_bible(src: str) -> bool:
    return map_source(src) == "bible"


def clean_text(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip())


def dedup_key(ce: str, ru: str) -> str:
    """Нормализованный ключ для дедупа: регистр/пробелы/пунктуация не важны."""
    norm = lambda s: re.sub(r"[^\wӀӏ]+", "", s.lower())
    return f"{norm(ce)}|{norm(ru)}"


def load_dataframe(args: argparse.Namespace):
    if args.parquet:
        import pyarrow.parquet as pq
        return pq.read_table(str(args.parquet)).to_pandas()

    from datasets import load_dataset
    ds = load_dataset(args.hf_dataset, split="train")
    return ds.to_pandas()


def build_dictionary(args: argparse.Namespace) -> dict:
    df = load_dataframe(args)
    print(f"raw rows: {len(df)}")

    df["ce"] = df["ce"].astype(str).map(clean_text)
    df["ru"] = df["ru"].astype(str).map(clean_text)
    df = df[(df["ce"].str.len() > 0) & (df["ru"].str.len() > 0)]
    df = df[(df["ce"] != "nan") & (df["ru"] != "nan")]

    df = df[~df["source"].map(is_bible)]
    print(f"after bible exclusion: {len(df)}")

    seen: set[str] = set()
    entries: list[dict] = []
    extra_sentences: list[dict] = []
    for row in df.itertuples(index=False):
        ce, ru, src = row.ce, row.ru, row.source
        key = dedup_key(ce, ru)
        if key in seen:
            continue
        seen.add(key)
        entry = {"chechen": ce, "russian": ru, "sources": [map_source(src)]}
        if len(ce) > MAX_CHECHEN_LEN:
            extra_sentences.append(entry)
        else:
            entries.append(entry)

    print(f"after dedup: {len(entries)} core + {len(extra_sentences)} long-form (excluded from bundle)")
    entries.sort(key=lambda e: (e["russian"].lower(), e["chechen"].lower()))
    return {
        "sources": SOURCES_META,
        "totalEntries": len(entries),
        "entries": entries,
        "_extra_sentences": extra_sentences,
    }


SOURCES_META = [
    {"id": "maciev", "title": "Мациев А.Г. Чеченско-русский словарь"},
    {"id": "aliroev", "title": "Алироев И.Ю. Чеченско-русский словарь (2005)"},
    {"id": "bersanov", "title": "Берсанов Р.У. Словарь анатомии"},
    {"id": "computer", "title": "Словарь компьютерной лексики"},
    {"id": "num2words", "title": "num2words (savoirfairelinux)"},
    {"id": "baltoslav", "title": "baltoslav.eu"},
    {"id": "daymohk", "title": "Журнал Даймохк"},
    {"id": "gatitos", "title": "Gatitos"},
    {"id": "radio", "title": "Radio Marsho"},
    {"id": "literature", "title": "Художественная литература"},
    {"id": "other", "title": "Прочее (nmd-ce-ru-171k-v0)"},
    {"id": "curated", "title": "Проверенная учебная лексика"},
]


# --------------------------------------------------------------------------
# 2. Компактная сериализация (без дублирующих дефолтных полей)
# --------------------------------------------------------------------------

def compact_entry(e: dict) -> dict:
    out = {"chechen": e["chechen"], "russian": e["russian"], "sources": e["sources"]}
    cat = e.get("category")
    if cat:
        out["category"] = cat
    emoji = e.get("emoji")
    if emoji and emoji != EMOJI_DEFAULT:
        out["emoji"] = emoji
    hint = e.get("hint")
    if hint and hint != HINT_TEMPLATE.format(ru=e["russian"]):
        out["hint"] = hint
    quality = e.get("quality")
    if quality is not None and quality != QUALITY_DEFAULT:
        out["quality"] = quality
    pron = e.get("pronunciation")
    if pron:
        out["pronunciation"] = pron
    return out


# --------------------------------------------------------------------------
# 3. Кураторская выборка (curated_vocabulary.json) — точный lookup, без догадок
# --------------------------------------------------------------------------

RU_CATEGORY_KEYWORDS = {
    "greetings": ("привет", "спасибо", "здравств", "прощ", "пожалуйста"),
    "animals": ("живот", "птиц", "рыб", "насек", "кот", "собак", "лошад", "коров", "овц"),
    "colors": ("цвет", "красн", "син", "зелён", "жёлт", "бел", "чёрн", "сер"),
    "numbers": ("число", "один", "два", "три", "четыре", "пять", "шесть", "семь", "восемь", "девять", "десять"),
    "family": ("мать", "отец", "брат", "сестр", "сын", "дочь", "семь", "жена", "муж", "дед", "баб"),
    "food": ("еда", "пищ", "хлеб", "молок", "мяс", "вода", "чай", "суп", "фрукт", "овощ"),
    "nature": ("гора", "река", "лес", "небо", "солнц", "дожд", "снег", "ветер", "земл", "мор", "озер"),
    "body": ("голова", "глаз", "ухо", "нос", "рот", "рука", "нога", "сердц", "тело", "палец"),
    "home": ("дом", "комнат", "окно", "двер", "стол", "стул"),
    "verbs": ("идти", "бежать", "сидеть", "стоять", "спать", "есть", "пить", "говорить", "читать", "писать"),
    "school": ("школа", "учитель", "ученик", "урок", "тетрад", "ручка", "класс", "учебник", "экзамен", "доска", "парта"),
}

ADJECTIVE_LOOKUPS = [
    "большой", "маленький", "хороший", "плохой", "красивый", "новый", "старый",
    "высокий", "низкий", "тёплый", "холодный", "быстрый", "медленный",
    "сильный", "слабый", "умный", "добрый", "злой", "чистый", "длинный",
    "короткий", "широкий", "узкий", "лёгкий", "тяжёлый",
]
PHRASE_LOOKUPS = [
    "как дела", "до свидания", "извините", "где ты", "я не понимаю",
    "приятного аппетита", "с днём рождения", "добро пожаловать",
    "который час", "сколько это стоит", "будьте здоровы", "хорошего дня",
]
DIALOGUE_LOOKUPS = [
    "как тебя зовут", "меня зовут", "сколько тебе лет", "откуда ты",
    "где ты живёшь", "как твои дела", "что ты делаешь", "куда ты идёшь",
]

EMOJI_BY_CATEGORY = {
    "greetings": "👋", "animals": "🐾", "colors": "🎨", "numbers": "🔢",
    "family": "❤️", "food": "🍎", "nature": "🌳", "body": "🫀", "home": "🏠",
    "verbs": "⚡", "school": "🏫", "adjectives": "✨", "phrases": "💬",
    "dialogues": "🗣️", "stories": "📚",
}

STOP_MARKERS = ("см.", "понуд.", "прил.", "нареч.", "мн. от", "субъект", "объект")


def is_learnable(ce: str, ru: str) -> bool:
    if not (1 <= len(ce) <= 25) or not (1 <= len(ru) <= 45):
        return False
    if any(c in ce for c in "()[]-+◊\"") or ce.startswith("-"):
        return False
    if re.search(r"\d{2,}", ce):
        return False
    if any(s in ru.lower() for s in STOP_MARKERS):
        return False
    return True


def cap(s: str) -> str:
    return s[0].upper() + s[1:] if s else s


def build_curated(dictionary_entries: list[dict]) -> dict:
    by_norm_ru: dict[str, list[dict]] = {}
    by_key: dict[str, dict] = {}

    for e in dictionary_entries:
        by_norm_ru.setdefault(e["russian"].strip().lower(), []).append(e)

    def add(ce: str, ru: str, category: str, sources: list[str], hint: str | None = None,
            emoji: str | None = None):
        key = re.sub(r"\s+", "", ce.lower())
        if key in by_key:
            return
        by_key[key] = {
            "chechen": cap(ce),
            "russian": cap(ru),
            "category": category,
            "emoji": emoji or EMOJI_BY_CATEGORY.get(category, EMOJI_DEFAULT),
            "hint": hint or f"Слово из словаря: {ru}",
            "sources": sources,
        }

    corrections_path = ROOT / "vocabulary_corrections.json"
    if corrections_path.exists():
        corrections = json.loads(corrections_path.read_text(encoding="utf-8"))
        for item in corrections.get("overrides", {}).values():
            add(item["chechen"], item["russian"], item.get("category") or "default",
                list(dict.fromkeys([*item.get("sources", []), "curated"])), item.get("hint"),
                emoji=item.get("emoji"))

    per_category_target = 25
    counts = {c: 0 for c in RU_CATEGORY_KEYWORDS}
    for e in dictionary_entries:
        ce, ru = e["chechen"], e["russian"]
        if not is_learnable(ce, ru):
            continue
        ru_low = ru.lower()
        for cat, keys in RU_CATEGORY_KEYWORDS.items():
            if counts[cat] >= per_category_target:
                continue
            if any(k in ru_low for k in keys):
                add(ce, ru, cat, list(dict.fromkeys([*e["sources"], "curated"])))
                counts[cat] += 1
                break

    def exact_lookup(term: str) -> list[dict]:
        return by_norm_ru.get(term, [])

    for term in ADJECTIVE_LOOKUPS:
        for e in exact_lookup(term):
            if is_learnable(e["chechen"], e["russian"]):
                add(e["chechen"], e["russian"], "adjectives",
                    list(dict.fromkeys([*e["sources"], "curated"])))
                break

    for term in PHRASE_LOOKUPS:
        for e in exact_lookup(term):
            if len(e["chechen"]) <= 40:
                add(e["chechen"], e["russian"], "phrases",
                    list(dict.fromkeys([*e["sources"], "curated"])))
                break

    for term in DIALOGUE_LOOKUPS:
        for e in exact_lookup(term):
            if len(e["chechen"]) <= 60:
                add(e["chechen"], e["russian"], "dialogues",
                    list(dict.fromkeys([*e["sources"], "curated"])))
                break

    story_count = 0
    for e in dictionary_entries:
        if story_count >= 15:
            break
        if "literature" not in e["sources"]:
            continue
        ce = e["chechen"]
        if 20 <= len(ce) <= 90 and ce.endswith((".", "!", "?")):
            add(ce, e["russian"], "stories", list(dict.fromkeys([*e["sources"], "curated"])))
            story_count += 1

    entries = sorted(by_key.values(), key=lambda x: x["chechen"].lower())
    return {"sources": SOURCES_META, "totalEntries": len(entries), "entries": entries}


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    print(f"  -> {path} ({path.stat().st_size / 1024:.0f} KB)")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--hf-dataset", default="NM-development/nmd-ce-ru-171k-v0")
    p.add_argument("--parquet", type=Path, default=None, help="Локальный parquet вместо скачивания")
    p.add_argument("--curate-only", action="store_true",
                    help="Не пересобирать dictionary.json, только curated_vocabulary.json из существующего")
    p.add_argument("--copy-assets", action="store_true", help="Скопировать в nokhchiin/assets/data/")
    args = p.parse_args()

    if args.curate_only:
        dict_data = json.loads((ROOT / "dictionary.json").read_text(encoding="utf-8"))
    else:
        dict_data = build_dictionary(args)
        extra = dict_data.pop("_extra_sentences")
        compact_dict = {
            "sources": dict_data["sources"],
            "totalEntries": dict_data["totalEntries"],
            "entries": [compact_entry(e) for e in dict_data["entries"]],
        }
        print("\nЗапись dictionary.json:")
        write_json(ROOT / "dictionary.json", compact_dict)
        if args.copy_assets:
            write_json(ASSETS / "dictionary.json", compact_dict)
        if extra:
            write_json(ROOT / "tools" / "output" / "dictionary_extra_sentences.json",
                       {"totalEntries": len(extra), "entries": extra})
        dict_data = compact_dict

    print("\nКурирование curated_vocabulary.json:")
    curated = build_curated(dict_data["entries"])
    write_json(ROOT / "curated_vocabulary.json", curated)
    if args.copy_assets:
        write_json(ASSETS / "curated_vocabulary.json", curated)

    from collections import Counter
    cat_counts = Counter(e["category"] for e in curated["entries"])
    print(f"\ncurated total: {len(curated['entries'])}")
    for cat, n in cat_counts.most_common():
        print(f"  {cat}: {n}")


if __name__ == "__main__":
    main()
