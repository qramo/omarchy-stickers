#!/usr/bin/env bash
# Inline the alpha-mask assets into gacha-template.html and write index.html (the GitHub Pages entry point).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 -I - "$ROOT" <<'PY'
import base64, sys
root = sys.argv[1]
t = open(f"{root}/gacha-template.html").read()
for key, f in [("__KANA__", "kana.png"), ("__WORD__", "word.png"), ("__ICON__", "icon.png")]:
    t = t.replace(key, "data:image/png;base64," + base64.b64encode(open(f"{root}/gacha-assets/{f}", "rb").read()).decode())
open(f"{root}/index.html", "w").write(t)
print("wrote index.html", len(t), "bytes")
PY
