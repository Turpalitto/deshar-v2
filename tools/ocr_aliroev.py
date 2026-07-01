#!/usr/bin/env python3
"""OCR Aliroev Chechen-Russian dictionary (scanned PDF) via Tesseract + PyMuPDF."""
import re
import json
import argparse
import os
import fitz
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ALIROEV_PDF = ROOT / "Aliroev_dictionary.pdf"
OUT_RAW = ROOT / "aliroev_ocr_raw.json"
OUT_ENTRIES = ROOT / "aliroev_ocr_entries.json"

TESSDATA_CANDIDATES = [
    Path(os.environ.get("TESSDATA_PREFIX", "")) if os.environ.get("TESSDATA_PREFIX") else None,
    Path.home() / "tessdata",
    ROOT / "tools" / "tessdata",
    Path(r"C:\Program Files\Tesseract-OCR\tessdata"),
    Path("/usr/share/tesseract-ocr/4.00/tessdata"),
]


def resolve_tessdata() -> str | None:
    for p in TESSDATA_CANDIDATES:
        if p is None or not p.exists():
            continue
        if (p / "rus.traineddata").exists():
            os.environ["TESSDATA_PREFIX"] = str(p.resolve())
            return str(p.resolve())
    for p in TESSDATA_CANDIDATES:
        if p is None or not p.exists():
            continue
        os.environ["TESSDATA_PREFIX"] = str(p.resolve())
        return str(p.resolve())
    return None


TESSDATA = resolve_tessdata()


def remove_stress(text: str) -> str:
    prev = None
    while prev != text:
        prev = text
        text = re.sub(
            r"([а-яёa-z])( ([а-яёa-z]{1,6}))(?=\s|[,;.\)\]]|$)",
            r"\1\3",
            text,
            flags=re.IGNORECASE,
        )
    return text


def clean_russian(raw: str) -> str:
    raw = remove_stress(raw)
    raw = re.sub(r"\s+", " ", raw).strip()
    raw = re.sub(r"^\d+[\.\)]\s*", "", raw)
    raw = raw.split(";")[0].split(",")[0].strip()
    return raw.strip(" .,:")


def ocr_page(page: fitz.Page, dpi: int = 200) -> str:
    kwargs = {"language": "rus+eng", "dpi": dpi, "full": False}
    if TESSDATA:
        kwargs["tessdata"] = TESSDATA
    tp = page.get_textpage_ocr(**kwargs)
    return page.get_text(textpage=tp)


def parse_ocr_lines(text: str) -> list[dict]:
    """Parse OCR text into chechen-russian pairs (heuristic)."""
    entries = []
    for line in text.split("\n"):
        line = line.strip()
        if len(line) < 4 or re.match(r"^\d+$", line):
            continue
        # Pattern: chechen — russian OR chechen   russian
        m = re.match(
            r"^([а-яА-ЯӀьъa-zA-Z\-\s]{2,40}?)\s+[-—–]\s+(.+)$",
            line,
        )
        if not m:
            m = re.match(
                r"^([а-яА-ЯӀьъa-zA-Z\-\s]{2,30})\s{2,}(.+)$",
                line,
            )
        if not m:
            continue
        ce = m.group(1).strip()
        ru = clean_russian(m.group(2))
        if not ru or len(ru) < 2 or len(ru) > 60:
            continue
        if not re.search(r"[а-яА-ЯӀьъ]", ce):
            continue
        if re.search(r"[ыэюяёЫЭЮЯЁ]", ce) and "Ӏ" not in ce:
            continue
        entries.append({
            "chechen": ce[0].upper() + ce[1:] if ce else ce,
            "russian": ru[0].upper() + ru[1:] if ru else ru,
            "sources": ["aliroev"],
        })
    return entries


def run_ocr(start: int, end: int, dpi: int = 200) -> list[dict]:
    doc = fitz.open(ALIROEV_PDF)
    end = min(end, doc.page_count)
    all_entries: dict[str, dict] = {}

    for i in range(start, end):
        text = ocr_page(doc[i], dpi=dpi)
        for e in parse_ocr_lines(text):
            key = re.sub(r"\s+", "", e["chechen"].lower())
            if key and key not in all_entries:
                all_entries[key] = e
        if (i - start) % 10 == 0:
            print(f"  OCR page {i}/{end} — {len(all_entries)} entries")

    return list(all_entries.values())


def main():
    parser = argparse.ArgumentParser(description="OCR Aliroev dictionary")
    parser.add_argument("--start", type=int, default=5, help="Start page (skip intro)")
    parser.add_argument("--end", type=int, default=-1, help="End page (-1 = all)")
    parser.add_argument("--dpi", type=int, default=200)
    parser.add_argument("--full", action="store_true", help="OCR entire dictionary")
    args = parser.parse_args()

    if not TESSDATA or not Path(TESSDATA, "rus.traineddata").exists():
        print("Missing rus.traineddata. Download to tools/tessdata/rus.traineddata")
        return

    if not ALIROEV_PDF.exists():
        print(f"Missing: {ALIROEV_PDF}")
        return

    doc = fitz.open(ALIROEV_PDF)
    end = doc.page_count - 5 if args.end < 0 else args.end
    start = 5 if args.full else args.start

    print(f"OCR Aliroev: pages {start}-{end}, tessdata={TESSDATA}")
    entries = run_ocr(start, end, dpi=args.dpi)

    with open(OUT_ENTRIES, "w", encoding="utf-8") as f:
        json.dump({"source": "Алироев И.Ю. (2005)", "total": len(entries), "entries": entries}, f, ensure_ascii=False, indent=2)

    print(f"Saved {len(entries)} entries -> {OUT_ENTRIES}")
    print("Run: python build_dictionary.py --with-aliroev-ocr")


if __name__ == "__main__":
    main()
