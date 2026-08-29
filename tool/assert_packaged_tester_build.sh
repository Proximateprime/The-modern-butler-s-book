#!/usr/bin/env bash
# Hosted testers must stay on the missing-key / packaged-copy path.
# Never dart-define a phrasing provider key into web or APK.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]] || compgen -G '.env.*' >/dev/null; then
  echo "Refusing: env file in the tree. Do not ship secrets with testers." >&2
  exit 1
fi

if env | grep -E '^GROQ' >/dev/null; then
  echo "Refusing: phrasing-provider env is set. Testers use packaged copy." >&2
  exit 1
fi

if [[ "${1:-}" == "--scan-web" ]]; then
  if find build/web -type f \( -name '*.js' -o -name '*.json' -o -name '*.html' \) \
      -print0 | xargs -0 grep -E -n 'gsk_[A-Za-z0-9]{20,}'; then
    echo "Refusing to publish: secret-like token in web build" >&2
    exit 1
  fi
  exit 0
fi

if [[ "${1:-}" == "--scan-apk" ]]; then
  APK="${2:-build/app/outputs/flutter-apk/app-release.apk}"
  if strings "$APK" | grep -E 'gsk_[A-Za-z0-9]{20,}'; then
    echo "Refusing to upload: secret-like token in APK" >&2
    exit 1
  fi
  exit 0
fi
