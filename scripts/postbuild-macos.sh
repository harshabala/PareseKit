#!/usr/bin/env bash
# Sign the Tauri-built .app without rewriting Mach-O binaries (no cat/strip in place).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/src-tauri/target/release/bundle/macos/ParseDock.app"
VERSION="$(node -p "require('$ROOT/package.json').version")"
DMG_DIR="$ROOT/src-tauri/target/release/bundle/dmg"
DMG_OUT="$DMG_DIR/ParseDock_${VERSION}_aarch64.dmg"

if [[ ! -d "$APP" ]]; then
  echo "error: $APP not found — run npm run tauri build first" >&2
  exit 1
fi

echo "== postbuild-macos: ParseDock v${VERSION} =="

echo "[1/5] Stage bundle outside target/ (avoids FinderInfo on bundle wrapper) ..."
STAGE_DIR="$(mktemp -d)"
STAGE_APP="$STAGE_DIR/ParseDock.app"
ditto --norsrc "$APP" "$STAGE_APP"

echo "[2/5] Strip extended attributes on staged bundle ..."
xattr -cr "$STAGE_APP" || true
xattr -d com.apple.FinderInfo "$STAGE_APP" 2>/dev/null || true
xattr -d 'com.apple.fileprovider.fpfs#P' "$STAGE_APP" 2>/dev/null || true

echo "[3/5] Ad-hoc sign staged bundle as a unit (--deep) ..."
codesign --force --deep --sign - "$STAGE_APP"

echo "[4/5] Verify signature (strict) ..."
codesign --verify --deep --strict --verbose=2 "$STAGE_APP"
codesign -dv --verbose=2 "$STAGE_APP" 2>&1

echo "[5/5] Install signed bundle into bundle/macos (mv, no in-place Mach-O edits) ..."
rm -rf "$APP"
mv "$STAGE_APP" "$APP"
rmdir "$STAGE_DIR"

# Tauri DMG was built from the pre-sign tree; recreate from the signed .app only.
if [[ -d "$DMG_DIR" ]]; then
  echo "Recreating DMG from signed .app ..."
  rm -f "$DMG_OUT"
  hdiutil create -volname "ParseDock" -srcfolder "$APP" -ov -format UDZO "$DMG_OUT"
  echo "DMG written: $DMG_OUT"
fi

echo "postbuild-macos: OK"