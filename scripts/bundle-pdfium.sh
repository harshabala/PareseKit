#!/usr/bin/env bash
# Copy libpdfium.dylib next to ParseKit binaries so LiteParse can load it at runtime.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$ROOT/src-tauri/binaries}"

for profile in release debug; do
  CANDIDATE="$ROOT/src-tauri/target/$profile/deps/libpdfium.dylib"
  if [[ -f "$CANDIDATE" ]]; then
    SRC="$CANDIDATE"
    break
  fi
done

if [[ -z "${SRC:-}" ]]; then
  echo "error: libpdfium.dylib not found under src-tauri/target/{release,debug}/deps" >&2
  echo "hint: run npm run build:sidecar first (liteparse-pdfium-sys copies the dylib on compile)" >&2
  exit 1
fi

mkdir -p "$DEST"
cp "$SRC" "$DEST/libpdfium.dylib"
chmod 644 "$DEST/libpdfium.dylib"
echo "Bundled libpdfium.dylib → $DEST/libpdfium.dylib (from $SRC)"