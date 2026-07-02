#!/usr/bin/env python3
"""Sanitize bundled dictionary JSON (OCR fixes, validation, dedupe)."""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from dictionary_quality import (
    CATEGORY_LABELS,
    apply_corrections,
    apply_curated_fixes,
    entry_key,
    load_corrections,
    merge_sanitized_entries,
    sanitize_entry,
)

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "nokhchiin" / "assets" / "data"
DICT_PATH = ASSETS / "dictionary.json"
CURATED_PATH = ASSETS / "curated_vocabulary.json"

LESSONS_PATH = ASSETS / "lessons.json"
LESSON_CATEGORIES = {k for k in CATEGORY_LABELS if k != "default"}


def load_lesson_entries() -> list[dict]:
    if not LESSONS_PATH.exists():
        return []
    with open(LESSONS_PATH, encoding="utf-8") as f:
        lessons = json.load(f)
    entries: list[dict] = []
    for lesson in lessons:
        cat = lesson.get("id")
        for word in lesson.get("words", []):
            entries.append({
                "chechen": word["chechen"],
                "russian": word["russian"],
                "category": cat,
                "emoji": word.get("emoji", "📖"),
                "hint": word.get("hint", ""),
                "sources": ["curated", "verified", "lessons"],
                "quality": 100,
            })
    return entries



def sanitize_file(path: Path, *, min_quality: int) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    entries = data.get("entries", data if isinstance(data, list) else [])
    cleaned: list[dict] = []
    for item in entries:
        sanitized = sanitize_entry(item, min_quality=min_quality)
        if sanitized:
            cleaned.append(sanitized)
    return cleaned


def write_dictionary(path: Path, entries: list[dict], meta: dict | None = None) -> None:
    payload = {
        "sources": (meta or {}).get("sources", []),
        "totalEntries": len(entries),
        "entries": entries,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)


def write_curated(path: Path, entries: list[dict], meta: dict | None = None) -> None:
    payload = {
        "sources": (meta or {}).get("sources", []),
        "totalEntries": len(entries),
        "entries": entries,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def is_curated_entry(entry: dict) -> bool:
    sources = entry.get("sources", [])
    category = entry.get("category")
    if "verified" in sources or "curated" in sources:
        if category in LESSON_CATEGORIES:
            return True
        if entry.get("quality", 0) >= 95 and category:
            return True
    if category in LESSON_CATEGORIES and entry.get("quality", 0) >= 80:
        return True
    return False


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--min-quality", type=int, default=60)
    parser.add_argument("--copy-root", action="store_true", help="Also update root-level JSON copies")
    args = parser.parse_args()

    with open(DICT_PATH, encoding="utf-8") as f:
        dict_meta = json.load(f)
    with open(CURATED_PATH, encoding="utf-8") as f:
        curated_meta = json.load(f)

    print("Sanitizing entries...")
    dict_raw = sanitize_file(DICT_PATH, min_quality=args.min_quality)
    curated_raw = sanitize_file(CURATED_PATH, min_quality=args.min_quality)
    print(f"  dictionary.json: {len(dict_raw)}")
    print(f"  curated_vocabulary.json: {len(curated_raw)}")

    lesson_raw = load_lesson_entries()
    print(f"  lessons.json: {len(lesson_raw)}")

    overrides, deprecated, curated_fixes = load_corrections()
    curated_raw = apply_curated_fixes(curated_raw, curated_fixes)

    merged = merge_sanitized_entries(lesson_raw, curated_raw, dict_raw)
    merged_dict = {entry_key(e["chechen"], e["russian"]): e for e in merged}
    merged_dict = apply_corrections(merged_dict, overrides, deprecated)
    merged = list(merged_dict.values())
    merged.sort(key=lambda x: x["chechen"].lower())
    print(f"  Merged unique: {len(merged)}")

    curated_out = [e for e in merged if is_curated_entry(e)]
    curated_out.sort(key=lambda x: x["chechen"].lower())

    write_dictionary(DICT_PATH, merged, dict_meta)
    write_curated(CURATED_PATH, curated_out, curated_meta)
    print(f"Wrote dictionary.json: {len(merged)} entries")
    print(f"Wrote curated_vocabulary.json: {len(curated_out)} entries")

    if args.copy_root:
        shutil.copy2(DICT_PATH, ROOT / "dictionary.json")
        shutil.copy2(CURATED_PATH, ROOT / "curated_vocabulary.json")
        print("Copied to repo root")


if __name__ == "__main__":
    main()
