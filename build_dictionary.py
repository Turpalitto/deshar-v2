#!/usr/bin/env python3
"""Build merged Chechen-Russian dictionary from Maciev PDF + curated + Aliroev OCR."""
import re
import json
import argparse
import fitz
from pathlib import Path

ROOT = Path(r"C:\АББА")
MACIEV_PDF = ROOT / "Maciev_dictionary.pdf"
CURATED_JSON = ROOT / "curated_vocabulary.json"
CORRECTIONS_JSON = ROOT / "vocabulary_corrections.json"
ALIROEV_OCR_JSON = ROOT / "aliroev_ocr_entries.json"
OUT_DICT = ROOT / "dictionary.json"
OUT_LESSONS = ROOT / "lessons_data.json"

SKIP_MARKERS = (
    "понуд.", "потенц.", "прил.", "см. ", "масд.", "прич.", "нареч.",
    "деепр.", "звукоподр.", "мн. от ", "эрг. п.", "перен.",
    "субъект ", "объект ", "только мн.", "лингв.", "геогр.", "рел.",
    "с.-х.", "мед.", "воен.", "полит.", "экон.", "ист.", "физ.",
    "мор.", "бот.", "зоол.", "хим.", "мат.", "спорт.", "муз.",
)

LESSON_META = {
    "greetings": ("Приветствия", "Маршалла", "👋", "linear-gradient(135deg, #1a73e8, #1557b0)"),
    "animals": ("Животные", "Дийнаташ", "🐾", "linear-gradient(135deg, #e8710a, #c5620a)"),
    "colors": ("Цвета", "Бесаш", "🎨", "linear-gradient(135deg, #d01884, #a91369)"),
    "numbers": ("Числа 1–10", "Терахьаш", "🔢", "linear-gradient(135deg, #1a73e8, #174ea6)"),
    "family": ("Семья", "Доьзал", "❤️", "linear-gradient(135deg, #0d904f, #0a6e3c)"),
    "food": ("Еда и напитки", "Кхача", "🍎", "linear-gradient(135deg, #7c3aed, #5b21b6)"),
    "nature": ("Природа", "Ӏалам", "🌳", "linear-gradient(135deg, #0891b2, #0e7490)"),
    "body": ("Тело", "Ден", "🫀", "linear-gradient(135deg, #dc2626, #b91c1c)"),
    "home": ("Дом и быт", "ЦӀий", "🏠", "linear-gradient(135deg, #4f46e5, #3730a3)"),
    "verbs": ("Глаголы", "Дешар", "⚡", "linear-gradient(135deg, #ca8a04, #a16207)"),
}

STOP_RU = {
    "и", "или", "на", "в", "во", "с", "со", "к", "ко", "от", "до", "за", "по",
    "при", "без", "для", "о", "об", "из", "у", "а", "б", "но", "же", "ли",
}


def remove_stress(text: str) -> str:
    """Remove Maciev stress marks (space before stressed syllable)."""
    if not text:
        return text
    prev = None
    while prev != text:
        prev = text
        text = re.sub(
            r"([а-яёa-z])( ([а-яёa-z]{1,6}))(?=\s|[,;.\)\]◊—–\-]|$)",
            r"\1\3",
            text,
            flags=re.IGNORECASE,
        )
    return text


def clean_russian(raw: str) -> str:
    raw = remove_stress(raw)
    raw = re.sub(r"\s+", " ", raw).strip()
    raw = re.sub(r"^\d+\)\s*", "", raw)
    raw = re.sub(r"\[.*?\]", "", raw)
    raw = re.sub(r"\(.*?\)", "", raw)
    raw = re.sub(r"[◊].*$", "", raw)
    raw = re.sub(r"['\"].*?['\"]", "", raw)
    raw = raw.split(";")[0].strip()
    raw = raw.split("—")[0].strip()
    raw = raw.split("–")[0].strip()
    if "," in raw:
        parts = [p.strip() for p in raw.split(",")]
        raw = parts[0]
    return raw.strip(" .,;:")


def capitalize_chechen(word: str) -> str:
    return word[0].upper() + word[1:] if word else word


def norm_key(chechen: str) -> str:
    return re.sub(r"\s+", "", chechen.lower())


def is_valid_chechen(word: str) -> bool:
    if not word or len(word) < 1 or len(word) > 45:
        return False
    if any(c in word for c in "[]()◊«»"):
        return False
    if word.startswith("-") or word[0].isdigit():
        return False
    if re.search(r"[ыэюяёЫЭЮЯЁ]", word) and "Ӏ" not in word and "ь" not in word:
        return False
    if not re.search(r"[а-яА-ЯӀьъA-Za-z]", word):
        return False
    return True


def is_valid_russian(text: str) -> bool:
    if not text or len(text) < 2 or len(text) > 55:
        return False
    low = text.lower()
    if low.startswith(("от ", "к ", "см.", "см ", "см.", "образует", "означает", "частица", "послелог")):
        return False
    if not re.search(r"[а-яА-ЯёЁ]", text):
        return False
    if re.search(r"[A-Za-z]{3,}", text):
        return False
    return True


def quality_score(chechen: str, russian: str) -> int:
    score = 100
    if len(chechen) > 30:
        score -= 30
    if len(russian) > 35:
        score -= 25
    if ";" in russian or "—" in russian:
        score -= 20
    if re.search(r"\d", russian):
        score -= 10
    if len(chechen.split()) > 4:
        score -= 25
    return score


def parse_maciev_line(line: str) -> tuple[str, str] | None:
    line = line.strip()
    if not line or len(line) < 4 or re.match(r"^\d+\.?\s*$", line):
        return None
    for marker in SKIP_MARKERS:
        if marker in line.lower():
            return None
    if line.startswith(("а) ", "б) ", "в) ", "г) ", "◊")):
        return None

    match = re.match(
        r"^([а-яА-ЯӀьъa-zA-Z0-9\-\s]+?)(?:\s+\[[^\]]*\])?\s+(.+)$",
        line,
    )
    if not match:
        return None

    chechen = re.sub(r"\s+", " ", match.group(1).strip())
    chechen = re.sub(r"\d+$", "", chechen).strip()
    rest = match.group(2)
    if not is_valid_chechen(chechen):
        return None

    if "]" in rest:
        rest = rest[rest.find("]") + 1:].strip()
    meaning = re.search(r"(?:^|\s)1\)\s*(.+)", rest)
    russian = clean_russian(meaning.group(1) if meaning else rest)
    if not is_valid_russian(russian):
        return None
    if quality_score(chechen, russian) < 50:
        return None
    return chechen, russian


def parse_maciev(pdf_path: Path) -> dict[str, dict]:
    doc = fitz.open(pdf_path)
    entries: dict[str, dict] = {}
    for page_num in range(30, doc.page_count - 10):
        for line in doc[page_num].get_text().split("\n"):
            parsed = parse_maciev_line(line.strip())
            if not parsed:
                continue
            chechen, russian = parsed
            key = norm_key(chechen)
            if key not in entries:
                entries[key] = {
                    "chechen": capitalize_chechen(chechen),
                    "russian": russian[0].upper() + russian[1:],
                    "sources": ["maciev"],
                    "quality": quality_score(chechen, russian),
                }
    return entries


def load_corrections() -> tuple[dict[str, dict], set[str]]:
    """Verified overrides and deprecated Maciev parse errors."""
    if not CORRECTIONS_JSON.exists():
        return {}, set()
    with open(CORRECTIONS_JSON, encoding="utf-8") as f:
        data = json.load(f)
    overrides: dict[str, dict] = {}
    for key, entry in data.get("overrides", {}).items():
        overrides[norm_key(key)] = entry
    deprecated = {norm_key(k) for k in data.get("deprecated_keys", [])}
    return overrides, deprecated


def apply_corrections(merged: dict[str, dict], overrides: dict[str, dict], deprecated: set[str]) -> dict[str, dict]:
    for key in deprecated:
        merged.pop(key, None)
    for key, entry in overrides.items():
        merged[key] = {
            **entry,
            "pronunciation": simple_pronunciation(entry["chechen"]),
            "sources": entry.get("sources", ["verified"]),
            "quality": entry.get("quality", 100),
        }
    return merged


def load_curated() -> dict[str, dict]:
    with open(CURATED_JSON, encoding="utf-8") as f:
        data = json.load(f)
    entries: dict[str, dict] = {}
    for item in data["entries"]:
        key = norm_key(item["chechen"])
        entries[key] = {
            "chechen": item["chechen"],
            "russian": item["russian"],
            "category": item.get("category"),
            "emoji": item.get("emoji", "📖"),
            "hint": item.get("hint", ""),
            "sources": item.get("sources", ["curated"]),
            "quality": 100,
        }
    return entries


def load_aliroev_ocr() -> dict[str, dict]:
    if not ALIROEV_OCR_JSON.exists():
        return {}
    with open(ALIROEV_OCR_JSON, encoding="utf-8") as f:
        data = json.load(f)
    entries: dict[str, dict] = {}
    for item in data.get("entries", []):
        key = norm_key(item["chechen"])
        entries[key] = {
            "chechen": item["chechen"],
            "russian": item["russian"],
            "sources": list(set(item.get("sources", []) + ["aliroev"])),
            "quality": 85,
        }
    return entries


def merge_entries(maciev: dict, curated: dict, aliroev: dict | None = None) -> list[dict]:
    merged: dict[str, dict] = {}
    aliroev = aliroev or {}
    for key, entry in maciev.items():
        merged[key] = {
            **entry,
            "pronunciation": simple_pronunciation(entry["chechen"]),
        }
    for key, entry in aliroev.items():
        if key not in merged:
            merged[key] = {
                **entry,
                "pronunciation": simple_pronunciation(entry["chechen"]),
            }
        else:
            src = list(set(merged[key].get("sources", []) + entry.get("sources", [])))
            merged[key]["sources"] = src
    for key, entry in curated.items():
        merged[key] = {
            "chechen": entry["chechen"],
            "russian": entry["russian"],
            "pronunciation": simple_pronunciation(entry["chechen"]),
            "category": entry.get("category"),
            "emoji": entry.get("emoji", "📖"),
            "hint": entry.get("hint", ""),
            "sources": entry.get("sources", ["curated"]),
            "quality": 100,
        }
    result = list(merged.values())
    result.sort(key=lambda x: x["chechen"].lower())
    return result


def simple_pronunciation(chechen: str) -> str:
    parts = chechen.split()
    if len(parts) > 1:
        return " · ".join(parts)
    if len(chechen) <= 5:
        return chechen
    mid = len(chechen) // 2
    return chechen[:mid] + "·" + chechen[mid:]


def build_lessons(curated: dict) -> list[dict]:
    by_cat: dict[str, list] = {k: [] for k in LESSON_META}
    seen_per_cat: dict[str, set] = {k: set() for k in LESSON_META}

    for entry in curated.values():
        cat = entry.get("category")
        if not cat or cat not in LESSON_META:
            continue
        key = norm_key(entry["chechen"])
        if key in seen_per_cat[cat]:
            continue
        seen_per_cat[cat].add(key)
        by_cat[cat].append({
            "chechen": entry["chechen"],
            "russian": entry["russian"],
            "pronunciation": simple_pronunciation(entry["chechen"]),
            "emoji": entry.get("emoji", "📖"),
            "hint": entry.get("hint") or f"Слово из словаря: {entry['russian']}",
        })

    lessons = []
    for cat_id, (title, ce_title, icon, color) in LESSON_META.items():
        words = by_cat[cat_id]
        if len(words) < 3:
            continue
        lessons.append({
            "id": cat_id,
            "title": title,
            "chechenTitle": ce_title,
            "icon": icon,
            "color": color,
            "words": words,
        })
    return lessons


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--with-aliroev-ocr", action="store_true")
    args = parser.parse_args()

    print("Parsing Maciev dictionary...")
    maciev = parse_maciev(MACIEV_PDF) if MACIEV_PDF.exists() else {}
    print(f"  Maciev: {len(maciev)} entries")

    aliroev = {}
    if args.with_aliroev_ocr:
        print("Loading Aliroev OCR entries...")
        aliroev = load_aliroev_ocr()
        print(f"  Aliroev OCR: {len(aliroev)} entries")

    print("Loading curated vocabulary...")
    curated = load_curated()
    print(f"  Curated: {len(curated)} entries")

    merged = merge_entries(maciev, curated, aliroev)
    overrides, deprecated = load_corrections()
    merged_dict = {norm_key(e["chechen"]): e for e in merged}
    merged_dict = apply_corrections(merged_dict, overrides, deprecated)
    merged = list(merged_dict.values())
    merged.sort(key=lambda x: x["chechen"].lower())
    print(f"  Merged: {len(merged)} entries (after corrections)")

    with open(OUT_DICT, "w", encoding="utf-8") as f:
        json.dump({
            "sources": [
                {"id": "maciev", "title": "Мациев А.Г. Чеченско-русский словарь",
                 "url": "https://ps95.ru/wp-content/uploads/2018/07/Maciev_A.G_Chechensko-russkiy_slovar.pdf"},
                {"id": "aliroev", "title": "Алироев И.Ю. Чеченско-русский словарь (2005)",
                 "url": "https://karchava.wordpress.com/wp-content/uploads/2012/09/aliroev_i_yu_-_chechensko-russky_slovar_-_2005.pdf"},
                {"id": "curated", "title": "Проверенная учебная лексика"},
            ],
            "totalEntries": len(merged),
            "entries": merged,
        }, f, ensure_ascii=False)

    lessons = build_lessons(curated)
    with open(OUT_LESSONS, "w", encoding="utf-8") as f:
        json.dump(lessons, f, ensure_ascii=False, indent=2)

  # lessons_data.js
    with open(ROOT / "lessons_data.js", "w", encoding="utf-8") as f:
        f.write("window.MACIEV_LESSONS = ")
        json.dump(lessons, f, ensure_ascii=False)
        f.write(";\n")

    print(f"Built {len(lessons)} lessons")
    for l in lessons:
        print(f"  {l['id']}: {len(l['words'])} words")


if __name__ == "__main__":
    main()
