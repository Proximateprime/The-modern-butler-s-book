#!/usr/bin/env bash
# Copy Flutter web output so legacy GitHub Pages (main /) serves the app
# instead of the Jekyll README. Does not embed secrets.
#
# Expects: flutter build web --release --base-href "/The-modern-butler-s-book/"
# Writes:  site/ (assets) and root index.html + .nojekyll (homepage trampoline).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WEB="${ROOT}/build/web"
if [[ ! -f "${WEB}/index.html" ]]; then
  echo "missing ${WEB}/index.html — run flutter build web first" >&2
  exit 1
fi

rm -rf "${ROOT}/site"
mkdir -p "${ROOT}/site"
cp -a "${WEB}/." "${ROOT}/site/"
# Jekyll must not process Flutter files (underscored assets, etc.).
touch "${ROOT}/site/.nojekyll"
touch "${ROOT}/.nojekyll"

# Root URL stays /The-modern-butler-s-book/; scripts/assets live under /site/.
python3 - <<'PY'
from pathlib import Path
html = Path("site/index.html").read_text(encoding="utf-8")
root = html.replace(
    'href="/The-modern-butler-s-book/"',
    'href="/The-modern-butler-s-book/site/"',
    1,
)
if 'The Modern Butler' not in root and "The Modern Butler" not in html:
    raise SystemExit("refusing to write index.html without Flutter title")
Path("index.html").write_text(root, encoding="utf-8")
PY

if [[ "${1:-}" == "--commit" ]]; then
  git add .nojekyll index.html site
  if git diff --staged --quiet; then
    echo "Pages web source already in sync"
    exit 0
  fi
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git commit -m "chore: sync tester Flutter web for GitHub Pages [skip ci]"
  git push origin HEAD:main
fi
