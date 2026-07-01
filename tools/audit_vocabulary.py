#!/usr/bin/env python3
"""Audit curated vocabulary and dictionary coverage for Maciev + Aliroev."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.stdout.reconfigure(encoding="utf-8")

DICT = ROOT / "dictionary.json"
CURATED = ROOT / "curated_vocabulary.json"
CORRECTIONS = ROOT / "vocabulary_corrections.json"
ALIROEV = ROOT / "aliroev_ocr_entries.json"
REPORT = ROOT / "vocabulary_audit_report.json"


def norm(s: str) -> str:
    return re.sub(r"\s+", "", s.lower())


def main():
    dictionary = json.load(open(DICT, encoding="utf-8"))
    curated = json.load(open(CURATED, encoding="utf-8"))
    corrections = json.load(open(CORRECTIONS, encoding="utf-8")) if CORRECTIONS.exists() else {}

    by_key = {norm(e["chechen"]): e for e in dictionary["entries"]}
    maciev_keys = {norm(e["chechen"]) for e in dictionary["entries"] if "maciev" in e.get("sources", [])}
    aliroev_keys = {norm(e["chechen"]) for e in dictionary["entries"] if "aliroev" in e.get("sources", [])}

    curated_entries = curated.get("entries", [])
    missing_in_dict = []
    mismatches = []
    verified_ok = []

    for item in curated_entries:
        key = norm(item["chechen"])
        if key not in by_key:
            missing_in_dict.append(item)
            continue
        d = by_key[key]
        ru_dict = d["russian"].lower().split(",")[0].strip()
        ru_cur = item["russian"].lower().split(",")[0].strip()
        if ru_dict != ru_cur and ru_cur not in ru_dict and ru_dict not in ru_cur:
            mismatches.append({
                "chechen": item["chechen"],
                "curated_ru": item["russian"],
                "dictionary_ru": d["russian"],
                "sources": d.get("sources", []),
            })
        else:
            verified_ok.append(item["chechen"])

    deprecated = corrections.get("deprecated_keys", [])
    known_fixes = {f["wrong_chechen"] for f in corrections.get("curated_fixes", [])}

    report = {
        "dictionary_total": dictionary["totalEntries"],
        "maciev_in_merged": len(maciev_keys),
        "aliroev_in_merged": len(aliroev_keys),
        "aliroev_ocr_file": len(json.load(open(ALIROEV, encoding="utf-8")).get("entries", [])) if ALIROEV.exists() else 0,
        "curated_count": len(curated_entries),
        "curated_verified_ok": len(verified_ok),
        "curated_missing_in_dictionary": missing_in_dict,
        "curated_translation_mismatches": mismatches,
        "deprecated_keys": deprecated,
        "recommendations": [],
    }

    if report["aliroev_ocr_file"] < 500:
        report["recommendations"].append(
            "Aliroev OCR incomplete — run: python tools/ocr_aliroev.py --full"
        )
    if mismatches:
        report["recommendations"].append(
            f"Review {len(mismatches)} curated/dictionary translation mismatches"
        )
    if missing_in_dict:
        report["recommendations"].append(
            f"Add {len(missing_in_dict)} curated words missing from merged dictionary"
        )

    with open(REPORT, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"Dictionary: {report['dictionary_total']} entries")
    print(f"  Maciev keys: {report['maciev_in_merged']}")
    print(f"  Aliroev in merge: {report['aliroev_in_merged']} (OCR file: {report['aliroev_ocr_file']})")
    print(f"Curated: {report['curated_count']} — OK: {report['curated_verified_ok']}")
    print(f"  Missing: {len(missing_in_dict)}")
    print(f"  Mismatches: {len(mismatches)}")
    if mismatches:
        print("\nMismatches (curated vs dictionary):")
        for m in mismatches[:15]:
            print(f"  {m['chechen']}: curated={m['curated_ru']} | dict={m['dictionary_ru']}")
    print(f"\nReport -> {REPORT}")


if __name__ == "__main__":
    main()
