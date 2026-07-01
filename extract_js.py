import re
from pathlib import Path
html = Path(r"C:\АББА\index.html").read_text(encoding="utf-8")
idx = html.find('<script src="lessons_data.js"></script>')
idx2 = html.find("<script>", idx)
idx3 = html.find("</script>", idx2)
js = html[idx2 + 8 : idx3].strip()
Path(r"C:\АББА\app.js").write_text(js, encoding="utf-8")
print(f"Extracted {len(js)} chars")
