"""Import HF dataset NM-development/nmd-ce-ru-171k-v0 into app dictionary format.

Excludes Bible. Keeps all other sources (Matsiev, Gatitos, Bersanov,
computer vocab, num2words, baltoslav, daymohk, Radio Marsho, literature).

Usage:
    python import_hf_dataset.py
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import pyarrow.parquet as pq

PARQUET = Path(r"C:\Users\TURPAL\AppData\Local\Temp\opencode\nmd_ce_ru.parquet")
ASSETS = Path(r"C:\АББА\nokhchiin\assets\data")
ROOT = Path(r"C:\АББА")

EMOJI_DEFAULT = "📖"


def map_source(src: str) -> str:
    s = src.strip().lower()
    if "matsiev" in s or "maciev" in s:
        return "maciev"
    if "aliroev" in s:
        return "aliroev"
    if "bersanov" in s or "anatomy" in s:
        return "bersanov"
    if "computer" in s or "computer vocab" in s:
        return "computer"
    if "num2words" in s or "savoirfairelinux" in s:
        return "num2words"
    if "baltoslav" in s:
        return "baltoslav"
    if "daymohk" in s:
        return "daymohk"
    if "gatitos" in s:
        return "gatitos"
    if "radio marsho" in s or "radiomarsho" in s:
        return "radio"
    if "bakarov" in s or "aydamirov" in s or "abuzar" in s or "zelimkhan" in s:
        return "literature"
    if "bible" in s or "synodal" in s or "institute of bible" in s:
        return "bible"
    return "other"


def is_bible(src: str) -> bool:
    s = src.strip().lower()
    return "bible" in s or "synodal" in s or "institute of bible" in s


def clean_text(s: str) -> str:
    s = s.strip()
    s = re.sub(r"\s+", " ", s)
    return s


def main() -> None:
    table = pq.read_table(str(PARQUET))
    df = table.to_pandas()

    print(f"raw rows: {len(df)}")

    df["ce"] = df["ce"].astype(str).map(clean_text)
    df["ru"] = df["ru"].astype(str).map(clean_text)
    df = df[df["ce"].str.len() > 0]
    df = df[df["ru"].str.len() > 0]
    df = df[df["ce"] != "nan"]
    df = df[df["ru"] != "nan"]

    df = df[~df["source"].map(is_bible)]
    print(f"after bible exclusion: {len(df)}")

    df["source_id"] = df["source"].map(map_source)

    df = df.drop_duplicates(subset=["ce", "ru"], keep="first")
    print(f"after dedup: {len(df)}")

    entries = []
    for _, row in df.iterrows():
        ce = row["ce"]
        ru = row["ru"]
        src = row["source_id"]
        entries.append({
            "chechen": ce,
            "russian": ru,
            "category": None,
            "emoji": EMOJI_DEFAULT,
            "hint": f"Слово из словаря: {ru}",
            "sources": [src],
            "quality": 100,
        })

    entries.sort(key=lambda e: (e["russian"].lower(), e["chechen"].lower()))

    sources_meta = [
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
        {"id": "other", "title": "Прочее"},
        {"id": "curated", "title": "Проверенная учебная лексика"},
    ]

    out = {
        "sources": sources_meta,
        "totalEntries": len(entries),
        "entries": entries,
    }

    dict_path = ASSETS / "dictionary.json"
    dict_path.write_text(
        json.dumps(out, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"wrote {dict_path} ({dict_path.stat().st_size // 1024} KB)")

    root_copy = ROOT / "dictionary.json"
    root_copy.write_text(
        json.dumps(out, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"wrote {root_copy} ({root_copy.stat().st_size // 1024} KB)")

    print(f"\ntotal entries: {len(entries)}")
    by_src: dict[str, int] = {}
    for e in entries:
        for s in e["sources"]:
            by_src[s] = by_src.get(s, 0) + 1
    for k, v in sorted(by_src.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
