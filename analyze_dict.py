import json
with open(r"C:\АББА\dictionary.json", encoding="utf-8") as f:
    d = json.load(f)
bad = [e for e in d["entries"] if len(e["chechen"]) > 25 or "]" in e["chechen"] or "(" in e["chechen"] or e["chechen"].startswith("-")]
with open(r"C:\АББА\bad_entries.txt", "w", encoding="utf-8") as out:
    out.write(f"Total bad: {len(bad)}\n\n")
    for e in bad[:50]:
        out.write(f"{e['chechen']} -> {e['russian']}\n")
keys = ["маршалла", "цициг", "нана", "ваха", "деша", "хьун", "маьлхан", "Ӏуьйре"]
with open(r"C:\АББА\lookup.txt", "w", encoding="utf-8") as out:
    for k in keys:
        found = [e for e in d["entries"] if e["chechen"].lower().replace(" ", "") == k.replace(" ", "")]
        out.write(f"{k}: {found[:2]}\n")
