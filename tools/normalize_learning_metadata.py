#!/usr/bin/env python3
"""Add explicit, conservative metadata to source-attested lesson cards."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "nokhchiin" / "assets" / "data"
INTERNAL_SOURCES = {"lessons", "curated", "verified"}


def norm(value: str) -> str:
    normalized = value.strip().casefold().replace("ё", "е").strip(" .!?…")
    return " ".join(normalized.split())


def main() -> int:
    dictionary = json.loads(
        (DATA / "dictionary.json").read_text(encoding="utf-8-sig")
    )
    sources_by_pair: dict[tuple[str, str], list[str]] = {}
    for entry in dictionary["entries"]:
        sources_by_pair[(norm(entry["chechen"]), norm(entry["russian"]))] = list(
            entry.get("sources", [])
        )

    path = DATA / "lessons.json"
    lessons = json.loads(path.read_text(encoding="utf-8-sig"))
    changed = 0
    for lesson in lessons:
        for card in lesson.get("words", []):
            pair = (norm(card["chechen"]), norm(card["russian"]))
            dictionary_sources = sources_by_pair.get(pair, [])
            external = [
                source
                for source in card.get("sources", [])
                if source not in INTERNAL_SOURCES
            ]
            attested = bool(dictionary_sources or external)

            desired_status = card.get("reviewStatus")
            if desired_status in (None, "draft") and attested:
                desired_status = "source_checked"
                card["reviewStatus"] = desired_status
                changed += 1
            elif desired_status is None:
                desired_status = "source_checked" if attested else "draft"
                card["reviewStatus"] = desired_status
                changed += 1

            if "frequencyTier" not in card:
                card["frequencyTier"] = "common"
                changed += 1

            if "sourceRef" not in card:
                candidates = [*dictionary_sources, *external]
                if candidates:
                    card["sourceRef"] = candidates[0]
                    changed += 1

    path.write_text(
        json.dumps(lessons, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Normalized learning metadata: {changed} field(s) added")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
