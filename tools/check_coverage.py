#!/usr/bin/env python3
"""Fail when LCOV line coverage for selected paths falls below a threshold."""

from __future__ import annotations

import argparse
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("lcov", type=Path)
    parser.add_argument("--include", action="append", default=[])
    parser.add_argument("--minimum", type=float, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    found = 0
    hit = 0
    current_file = ""

    for line in args.lcov.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            current_file = line[3:].replace("\\", "/")
            continue
        if args.include and not any(part in current_file for part in args.include):
            continue
        if line.startswith("DA:"):
            _, count = line[3:].split(",", maxsplit=1)
            found += 1
            hit += int(count) > 0

    if found == 0:
        print("ERROR: no matching lines found in LCOV report")
        return 2

    percent = hit / found * 100
    print(
        f"Selected coverage: {percent:.2f}% "
        f"({hit}/{found} lines, minimum {args.minimum:.2f}%)"
    )
    return 0 if percent >= args.minimum else 1


if __name__ == "__main__":
    raise SystemExit(main())
