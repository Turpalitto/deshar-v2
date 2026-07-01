#!/usr/bin/env python3
"""Audit curated vocabulary: translations vs dictionary + emoji semantics."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.stdout.reconfigure(encoding="utf-8")

# Russian keyword -> expected emoji (semantic match for flashcards)
EMOJI_BY_RU_KEYWORD = {
    "стол": "🍽️",  # стол — не стул (🪑)
    "стул": "🪑",
    "кресло": "💺",
    "сидеть": "🪑",
    "ухо": "👂",
    "глаз": "👁️",
    "нос": "👃",
    "рот": "👄",
    "рука": "✋",
    "нога": "🦵",
    "палец": "☝️",
    "голова": "🗣️",
    "сердце": "❤️",
    "кошка": "🐱",
    "кот": "🐈",
    "собака": "🐶",
    "стол": "🍽️",
    "книга": "📚",
    "школа": "🏫",
    "учёба": "🏫",
    "карандаш": "✏️",
    "ручка": "✏️",
    "газета": "📰",
    "дом": "🏠",
    "окно": "🪟",
    "дверь": "🚪",
    "комната": "🛋️",
    "вода": "💧",
    "река": "🌊",
    "хлеб": "🍞",
    "молоко": "🥛",
    "чай": "🍵",
    "яблоко": "🍏",
    "мясо": "🥩",
    "суп": "🍲",
    "рыба": "🐟",
    "картофель": "🥔",
    "сыр": "🧀",
}

WRONG_EMOJI = {
    "стол": {"🪑", "💺"},  # chair emojis on «стол»
    "стул": set(),
    "ухо": set(),
    "книга": {"🏫"},
    "школа": {"📚"},
}


def norm(s: str) -> str:
    return re.sub(r"\s+", "", s.lower())


def primary_ru(russian: str) -> str:
    return russian.lower().split(",")[0].split("/")[0].strip()


def suggest_emoji(russian: str) -> str | None:
    ru = primary_ru(russian)
    for key, emo in EMOJI_BY_RU_KEYWORD.items():
        if key in ru:
            return emo
    return None


def main():
    curated = json.load(open(ROOT / "curated_vocabulary.json", encoding="utf-8"))
    dictionary = json.load(open(ROOT / "dictionary.json", encoding="utf-8"))
    by_key = {norm(e["chechen"]): e for e in dictionary["entries"]}

    emoji_issues = []
    translation_issues = []
    duplicates = []
    seen_keys: dict[str, list] = {}

    for item in curated["entries"]:
        key = norm(item["chechen"])
        seen_keys.setdefault(key, []).append(item)
        ru = primary_ru(item["russian"])
        emo = item.get("emoji", "")
        suggested = suggest_emoji(item["russian"])

        if key in WRONG_EMOJI and emo in WRONG_EMOJI.get(ru, set()):
            emoji_issues.append({
                "chechen": item["chechen"],
                "russian": item["russian"],
                "emoji": emo,
                "fix_emoji": suggested or "📖",
                "reason": f"Эмодзи {emo} не соответствует «{ru}»",
            })
        elif suggested and emo != suggested and ru in WRONG_EMOJI:
            emoji_issues.append({
                "chechen": item["chechen"],
                "russian": item["russian"],
                "emoji": emo,
                "fix_emoji": suggested,
                "reason": "Рекомендуемое соответствие",
            })

        if key in by_key:
            d_ru = primary_ru(by_key[key]["russian"])
            if d_ru != ru and ru not in by_key[key]["russian"].lower() and d_ru not in ru:
                if not (ru == "вода" and "вода" in by_key[key]["russian"].lower()):
                    translation_issues.append({
                        "chechen": item["chechen"],
                        "curated": item["russian"],
                        "dictionary": by_key[key]["russian"],
                    })

    for key, items in seen_keys.items():
        if len(items) > 1:
            duplicates.append({"chechen_key": key, "entries": items})

    # Auto-fix emoji map output
    fixes = {norm(i["chechen"]): i["fix_emoji"] for i in emoji_issues if "fix_emoji" in i}

    report = {
        "emoji_issues": emoji_issues,
        "translation_issues": translation_issues,
        "duplicate_chechen": duplicates,
        "auto_emoji_fixes": fixes,
    }
    out = ROOT / "vocabulary_emoji_audit.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"Emoji issues: {len(emoji_issues)}")
    for i in emoji_issues:
        print(f"  {i['chechen']} ({i['russian']}): {i['emoji']} -> {i.get('fix_emoji')}")
    print(f"Translation mismatches: {len(translation_issues)}")
    print(f"Duplicate chechen keys: {len(duplicates)}")
    for d in duplicates:
        print(f"  {d['chechen_key']}: {[e['russian'] for e in d['entries']]}")
    print(f"Report: {out}")


if __name__ == "__main__":
    main()
