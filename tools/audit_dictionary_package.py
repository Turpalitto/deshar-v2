#!/usr/bin/env python3
"""Report the bundled dictionary split and fail on structural regressions."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "nokhchiin" / "assets" / "data"


def main() -> int:
    full_path = DATA / "dictionary.json"
    core_path = DATA / "curated_vocabulary.json"
    full = json.loads(full_path.read_text(encoding="utf-8-sig"))
    core = json.loads(core_path.read_text(encoding="utf-8-sig"))
    full_entries = full.get("entries", [])
    core_entries = core.get("entries", [])

    errors: list[str] = []
    if full.get("totalEntries") != len(full_entries):
        errors.append("dictionary totalEntries does not match entries length")
    if core.get("totalEntries") != len(core_entries):
        errors.append("curated totalEntries does not match entries length")
    if not core_entries or len(core_entries) >= len(full_entries):
        errors.append("curated core must be a non-empty strict subset")

    phrase_like = sum(
        1 for entry in full_entries if " " in entry.get("chechen", "").strip()
    )
    print(
        "Dictionary package: "
        f"core={len(core_entries)} entries/{core_path.stat().st_size} bytes; "
        f"full={len(full_entries)} entries/{full_path.stat().st_size} bytes; "
        f"phrase-like={phrase_like}"
    )
    print(
        "Runtime policy: curated core opens first; full bundled offline package "
        "loads only after explicit user selection and is cached per launch"
    )
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
