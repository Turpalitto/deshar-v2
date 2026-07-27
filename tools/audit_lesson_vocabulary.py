#!/usr/bin/env python3
"""Audit every lesson card against the bundled lexicographic dataset.

The audit deliberately distinguishes a dictionary match from native-speaker
approval.  A pair can be lexicographically attested and still need editorial
review when it is used in a phrase or a particular teaching context.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "nokhchiin" / "assets" / "data"


def normalized(value: str) -> str:
    value = value.strip().casefold().replace("ё", "е")
    value = value.strip(" .!?…")
    return re.sub(r"\s+", " ", value)


def load_json(name: str) -> Any:
    return json.loads((DATA / name).read_text(encoding="utf-8-sig"))


def dictionary_indexes() -> tuple[
    dict[str, list[dict[str, Any]]], dict[str, list[dict[str, Any]]]
]:
    entries = load_json("dictionary.json")["entries"]
    by_chechen: dict[str, list[dict[str, Any]]] = defaultdict(list)
    by_russian: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for entry in entries:
        by_chechen[normalized(entry["chechen"])].append(entry)
        by_russian[normalized(entry["russian"])].append(entry)
    return by_chechen, by_russian


def query(terms: list[str], *, contains: bool = False) -> int:
    _, by_russian = dictionary_indexes()
    for term in terms:
        print(f"## {term}")
        needle = normalized(term)
        if contains:
            matches = [
                entry
                for russian, entries in by_russian.items()
                if needle in russian
                for entry in entries
            ]
        else:
            matches = by_russian.get(needle, [])
        for entry in matches:
            sources = ", ".join(entry.get("sources", []))
            print(f"- {entry['chechen']} [{sources}]")
        if not matches:
            print("- no exact dictionary match")
    return 0


def query_chechen(terms: list[str]) -> int:
    by_chechen, _ = dictionary_indexes()
    for term in terms:
        print(f"## {term}")
        matches = by_chechen.get(normalized(term), [])
        for entry in matches:
            sources = ", ".join(entry.get("sources", []))
            print(f"- {entry['russian']} [{sources}]")
        if not matches:
            print("- no exact dictionary match")
    return 0


def audit() -> int:
    lessons = load_json("lessons.json")
    by_chechen, _ = dictionary_indexes()
    failures: list[str] = []
    attested = 0
    total = 0

    def check_card(card: dict[str, Any], marker: str) -> None:
        nonlocal attested, total
        total += 1
        chechen = card["chechen"]
        russian = card["russian"]
        matches = by_chechen.get(normalized(chechen), [])
        exact = [
            entry
            for entry in matches
            if normalized(entry["russian"]) == normalized(russian)
        ]
        declared_sources = set(card.get("sources", []))
        external = declared_sources - {
            "maciev",
            "hugging-face",
            "lessons",
            "curated",
            "verified",
        }

        if exact:
            attested += 1
            return
        if external and card.get("reviewStatus") == "source_checked":
            attested += 1
            return

        senses = ", ".join(
            dict.fromkeys(entry["russian"] for entry in matches[:8])
        )
        failures.append(
            f"{marker} {chechen} = {russian}"
            + (f"; dictionary senses: {senses}" if senses else "; form absent")
        )

    for lesson in lessons:
        for index, word in enumerate(lesson["words"], start=1):
            check_card(word, f"lesson {lesson['id']}[{index}]")

    curated = load_json("curated_vocabulary.json")["entries"]
    for index, word in enumerate(curated, start=1):
        check_card(word, f"curated[{index}]")

    lesson_total = sum(len(lesson["words"]) for lesson in lessons)
    print(
        "Vocabulary audit: "
        f"{lesson_total} lesson cards + {len(curated)} curated cards; "
        f"{attested}/{total} source-attested"
    )
    for failure in failures:
        print(f"ERROR: {failure}", file=sys.stderr)
    if failures:
        print(f"FAILED: {len(failures)} unverified card(s)")
        return 1
    print("PASSED: every card has an exact dictionary or declared external-source match")
    print("Native-speaker review is still required for teaching context and pronunciation.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--query-russian", nargs="*", metavar="TERM")
    parser.add_argument("--contains-russian", nargs="*", metavar="TEXT")
    parser.add_argument("--query-chechen", nargs="*", metavar="TERM")
    args = parser.parse_args()
    if args.query_russian:
        return query(args.query_russian)
    if args.contains_russian:
        return query(args.contains_russian, contains=True)
    if args.query_chechen:
        return query_chechen(args.query_chechen)
    return audit()


if __name__ == "__main__":
    raise SystemExit(main())
