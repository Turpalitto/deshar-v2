"""Shared dictionary normalization and quality checks for Maciev OCR data."""
from __future__ import annotations

import json
import re
from pathlib import Path

PALOCHKA = "\u04cf"
PALOCHKA_ALIASES = frozenset("1Iil|!\u0406\u0456")  # incl. Ukrainian І/і

ROOT = Path(__file__).resolve().parent.parent

_PALOCHKA_TRANSLATION = str.maketrans({
    "1": PALOCHKA,
    "I": PALOCHKA,
    "i": PALOCHKA,
    "l": PALOCHKA,
    "|": PALOCHKA,
    "!": PALOCHKA,
})

_LATIN_TO_CYRILLIC = str.maketrans({
    "A": "А", "B": "В", "C": "С", "E": "Е", "H": "Н", "K": "К", "M": "М",
    "O": "О", "P": "Р", "T": "Т", "X": "Х", "Y": "Й",
    "a": "а", "c": "с", "e": "е", "h": "н", "k": "к", "m": "м",
    "o": "о", "p": "р", "t": "т", "x": "х", "y": "й",
})

CATEGORY_LABELS = {
    "default": "Словарь",
    "greetings": "Приветствия",
    "animals": "Животные",
    "colors": "Цвета",
    "numbers": "Числа",
    "family": "Семья",
    "food": "Еда",
    "nature": "Природа",
    "body": "Тело",
    "home": "Дом",
    "verbs": "Глаголы",
}

INVALID_RU_PREFIXES = (
    "произносится",
    "межд",
    "см.",
    "см ",
    "от ",
    "к ",
    "образует",
    "означает",
    "частица",
    "послелог",
    "форма ",
    "мн. ",
    "синоним",
    "антоним",
    "сокр.",
    "сравн.",
)

INVALID_RU_CONTAINS = (
    "звукоподр",
    "эрг. п.",
    "потенц.",
    "понуд.",
    "деепр.",
)


def unify_palochka(text: str) -> str:
    return "".join(PALOCHKA if ch in PALOCHKA_ALIASES else ch for ch in text)


def normalize_palochka(text: str) -> str:
    return unify_palochka(text.translate(_PALOCHKA_TRANSLATION))


def fix_chechen_ocr(text: str) -> str:
    text = normalize_palochka(text.strip())
    if re.search(r"[A-Za-z]", text):
        text = text.translate(_LATIN_TO_CYRILLIC)
        text = normalize_palochka(text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def remove_stress(text: str) -> str:
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


def fix_russian_spacing(text: str) -> str:
    text = remove_stress(text)
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"([а-яё])([А-ЯЁ])", r"\1 \2", text)
    for pattern, repl in (
        (r"Произноситсясо", "Произносится со"),
        (r"всамомделе", "в самом деле"),
        (r"частьплуга", "часть плуга"),
        (r"([а-яё]+ый)([а-яё]{3,})", r"\1 \2"),
        (r"([а-яё]+ой)([а-яё]{3,})", r"\1 \2"),
        (r"([а-яё]+ая)([а-яё]{3,})", r"\1 \2"),
        (r"([а-яё]+ое)([а-яё]{3,})", r"\1 \2"),
        (r"([а-яё]+ие)([а-яё]{3,})", r"\1 \2"),
        (r"([а-яё]+ть)([а-яё]{3,})", r"\1 \2"),
        (r"([а-яё]+ск)([а-яё]{3,})", r"\1 \2"),
        (r"море([а-яё])", r"море \1"),
        (r"([а-яё])море", r"\1 море"),
    ):
        text = re.sub(pattern, repl, text, flags=re.IGNORECASE)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def clean_russian(raw: str) -> str:
    raw = fix_russian_spacing(raw)
    raw = re.sub(r"^\d+\)\s*", "", raw)
    raw = re.sub(r"\[.*?\]", "", raw)
    raw = re.sub(r"\(.*?\)", "", raw)
    raw = re.sub(r"[◊*].*$", "", raw)
    raw = re.sub(r"['\"].*?['\"]", "", raw)
    raw = raw.split(";")[0].strip()
    raw = raw.split("—")[0].strip()
    raw = raw.split("–")[0].strip()
    if "," in raw and len(raw.split(",")) > 2:
        raw = raw.split(",")[0].strip()
    return raw.strip(" .,;:")


def capitalize_chechen(word: str) -> str:
    return word[0].upper() + word[1:] if word else word


def capitalize_russian(text: str) -> str:
    return text[0].upper() + text[1:] if text else text


def norm_key(chechen: str) -> str:
    return re.sub(r"\s+", "", normalize_palochka(chechen.lower()))


def norm_russian(russian: str) -> str:
    return re.sub(r"\s+", " ", russian.lower().strip())


def entry_key(chechen: str, russian: str) -> str:
    return f"{norm_key(chechen)}|{norm_russian(russian)}"


def is_valid_chechen(word: str) -> bool:
    if not word or len(word) < 1 or len(word) > 45:
        return False
    if any(c in word for c in "[]()◊«»*"):
        return False
    if word.startswith("-") or word[0].isdigit():
        return False
    if re.search(r"[A-Za-z]", word):
        return False
    if re.search(r"[ыэюяёЫЭЮЯЁ]", word) and PALOCHKA not in word and "ь" not in word:
        return False
    if not re.search(r"[а-яА-ЯӀьъ]", word):
        return False
    return True


def is_valid_russian(text: str) -> bool:
    if not text or len(text) < 2 or len(text) > 48:
        return False
    low = text.lower()
    if low.startswith(INVALID_RU_PREFIXES):
        return False
    if any(marker in low for marker in INVALID_RU_CONTAINS):
        return False
    if "[" in text or "]" in text:
        return False
    if re.search(r"[A-Za-z]", text):
        return False
    if re.search(r"[Ӏӏ]", text):
        return False
    if re.search(r"гӀ|хӀ|къ|ьур|Ӏа|Ӏо|Ӏе|Ӏу", text, re.IGNORECASE):
        return False
    if len(text.split()) > 5:
        return False
    tokens = [t.lower() for t in re.findall(r"[а-яА-ЯёЁ]+", text)]
    if len(tokens) >= 2 and len(tokens) != len(set(tokens)) and len(tokens) <= 6:
        return False
    if not re.search(r"[а-яА-ЯёЁ]", text):
        return False
    if re.fullmatch(r"[\W\d_]+", text):
        return False
    grammar_markers = (
        "частиц", "формах", "форма ", "межд", "выражается", "означает",
        "послелог", "мн. от", "синоним", "антоним", "сравнительн",
        "звукоподр", "дееприч", "причаст", "понудительн",
    )
    if any(marker in low for marker in grammar_markers):
        return False
    return True


def is_likely_inflection(chechen: str, russian: str) -> bool:
    kc = norm_key(chechen)
    kr = norm_key(russian)
    if len(kc) < 4 or len(kr) < 4:
        return False
    if kc in kr and len(kr) <= len(kc) + 5:
        return True
    if kr in kc and len(kc) <= len(kr) + 5:
        return True
    ce = re.sub(r"[^а-яӀь]", "", kc)
    ru = re.sub(r"[^а-я]", "", kr)
    if len(ce) >= 4 and ru.startswith(ce[: min(5, len(ce))]) and abs(len(ru) - len(ce)) <= 5:
        return True
    if ru.endswith(("нан", "анан", "енан")) and len(ru) <= len(ce) + 6:
        return True
    return False


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
    if re.search(r"[A-Za-z]", chechen):
        score -= 50
    if "[" in russian or "]" in russian:
        score -= 50
    return score


def category_label(category: str | None) -> str:
    if not category:
        return "Мациев"
    return CATEGORY_LABELS.get(category, category)


def should_show_transcription(chechen: str, pronunciation: str | None) -> str | None:
    if not pronunciation:
        return None
    p = pronunciation.strip()
    if not p:
        return None
    ce = chechen.strip()
    if normalize_palochka(p.replace("·", "").replace(" ", "").lower()) == normalize_palochka(ce.replace(" ", "").lower()):
        return None
    if p.lower() == ce.lower():
        return None
    return p


def sanitize_entry(entry: dict, *, min_quality: int = 60) -> dict | None:
    chechen = fix_chechen_ocr(entry.get("chechen", ""))
    russian = clean_russian(entry.get("russian", ""))
    chechen = capitalize_chechen(chechen)
    russian = capitalize_russian(russian)

    if not is_valid_chechen(chechen) or not is_valid_russian(russian):
        return None
    if is_likely_inflection(chechen, russian):
        return None

    score = quality_score(chechen, russian)
    if score < min_quality:
        return None

    out = {**entry, "chechen": chechen, "russian": russian, "quality": score}
    category = entry.get("category")
    if category == "default":
        category = None
    out["category"] = category

    pronunciation = should_show_transcription(chechen, entry.get("pronunciation"))
    if pronunciation:
        out["pronunciation"] = pronunciation
    else:
        out.pop("pronunciation", None)

    sources = list(entry.get("sources", []))
    if category and category in CATEGORY_LABELS and category != "default":
        if "verified" not in sources:
            sources.append("verified")
    out["sources"] = sources
    return out


def load_corrections() -> tuple[dict[str, dict], set[str], list[dict]]:
    path = ROOT / "vocabulary_corrections.json"
    if not path.exists():
        return {}, set(), []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    overrides = {norm_key(k): v for k, v in data.get("overrides", {}).items()}
    deprecated = {norm_key(k) for k in data.get("deprecated_keys", [])}
    return overrides, deprecated, data.get("curated_fixes", [])


def apply_curated_fixes(entries: list[dict], fixes: list[dict]) -> list[dict]:
    result = []
    for entry in entries:
        ce = entry["chechen"]
        ru = entry.get("russian", "")
        skip = False
        replace = None
        for fix in fixes:
            wrong_ce = fix.get("wrong_chechen")
            wrong_ru = fix.get("wrong_russian")
            if wrong_ce and norm_key(wrong_ce) == norm_key(ce):
                if wrong_ru and norm_russian(wrong_ru) != norm_russian(ru):
                    continue
                if fix.get("correct_chechen"):
                    replace = {
                        **entry,
                        "chechen": fix["correct_chechen"],
                        "russian": fix.get("russian", ru),
                        "emoji": fix.get("correct_emoji", entry.get("emoji")),
                        "sources": list(set(entry.get("sources", []) + ["verified"])),
                        "quality": 100,
                    }
                else:
                    skip = True
                break
        if skip:
            continue
        result.append(replace or entry)
    return result


def apply_corrections(merged: dict[str, dict], overrides: dict[str, dict], deprecated: set[str]) -> dict[str, dict]:
    to_remove = [k for k, entry in merged.items() if norm_key(entry["chechen"]) in deprecated]
    for key in to_remove:
        merged.pop(key, None)

    for override_key, entry in overrides.items():
        dupes = [k for k, existing in merged.items() if norm_key(existing["chechen"]) == override_key]
        for key in dupes:
            merged.pop(key, None)
        sanitized = sanitize_entry(entry, min_quality=50)
        if sanitized:
            merged[entry_key(sanitized["chechen"], sanitized["russian"])] = sanitized

    return merged


def merge_sanitized_entries(*groups: list[dict]) -> list[dict]:
    merged: dict[str, dict] = {}
    for entries in groups:
        for entry in entries:
            key = entry_key(entry["chechen"], entry["russian"])
            if key not in merged:
                merged[key] = entry
                continue
            existing = merged[key]
            qa = existing.get("quality", 50)
            qb = entry.get("quality", 50)
            if qb > qa:
                merged[key] = {**entry, "sources": list(set(existing.get("sources", []) + entry.get("sources", [])))}
            else:
                merged[key] = {
                    **existing,
                    "sources": list(set(existing.get("sources", []) + entry.get("sources", []))),
                    "category": existing.get("category") or entry.get("category"),
                    "emoji": existing.get("emoji") or entry.get("emoji"),
                }
    result = list(merged.values())
    result.sort(key=lambda x: x["chechen"].lower())
    return result
