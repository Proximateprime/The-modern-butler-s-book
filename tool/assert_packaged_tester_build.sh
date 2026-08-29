#!/usr/bin/env bash
# Hosted testers must stay on the missing-key / packaged-copy path.
# Never dart-define a phrasing provider key into web or APK.
# Never ship a Groq key or Play keystore in git.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TOKEN_RE='gsk_[A-Za-z0-9]{20,}'

if [[ -f .env ]] || compgen -G '.env.*' >/dev/null; then
  echo "Refusing: env file in the tree. Do not ship secrets with testers." >&2
  exit 1
fi

if env | grep -E '^GROQ' >/dev/null; then
  echo "Refusing: phrasing-provider env is set. Testers use packaged copy." >&2
  exit 1
fi

if git ls-files --error-unmatch '*.jks' '*.keystore' 'key.properties' \
    'android/key.properties' 2>/dev/null | grep -q .; then
  echo "Refusing: Play keystore or key.properties is tracked." >&2
  exit 1
fi

if git grep -nI -E "$TOKEN_RE" -- ':!.git' >/dev/null; then
  echo "Refusing: Groq-shaped token in tracked files." >&2
  git grep -nI -E "$TOKEN_RE" -- ':!.git' >&2 || true
  exit 1
fi

if git grep -nI -E -- 'dart-define=.?GROQ_API_KEY' -- '.github' >/dev/null; then
  echo "Refusing: phrasing key must not be passed into CI builds." >&2
  exit 1
fi

scan_tree() {
  local dir="$1"
  local label="$2"
  if [[ ! -d "$dir" ]]; then
    echo "Refusing: missing $dir for $label scan (fail closed)." >&2
    exit 1
  fi
  if ! find "$dir" -type f -print -quit | grep -q .; then
    echo "Refusing: no files in $dir for $label scan (fail closed)." >&2
    exit 1
  fi
  # Every regular file, including compressed/binary members (WASM, assets).
  if find "$dir" -type f -print0 | xargs -0 grep -a -E -n -- "$TOKEN_RE"; then
    echo "Refusing to publish: secret-like token in $label" >&2
    exit 1
  fi
}

if [[ "${1:-}" == "--scan-web" ]]; then
  scan_tree build/web "web build"
  exit 0
fi

if [[ "${1:-}" == "--scan-apk" ]]; then
  APK="${2:-build/app/outputs/flutter-apk/app-release.apk}"
  if [[ ! -f "$APK" ]]; then
    echo "Refusing: missing APK $APK (fail closed)." >&2
    exit 1
  fi
  TMP="$(mktemp -d)"
  cleanup() { rm -rf "$TMP"; }
  trap cleanup EXIT
  if ! unzip -q -o "$APK" -d "$TMP"; then
    echo "Refusing: APK extract failed (fail closed)." >&2
    exit 1
  fi
  scan_tree "$TMP" "APK members"
  exit 0
fi
