#!/usr/bin/env bash
# Build a styled ParseKit DMG (background, icon positions, Applications drop link).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(node -p "require('$ROOT/package.json').version")"
DMG_DIR="$ROOT/src-tauri/target/release/bundle/dmg"
DMG_OUT="$DMG_DIR/ParseKit_${VERSION}_aarch64.dmg"
BUNDLE_DMG="$DMG_DIR/bundle_dmg.sh"
DMG_ASSETS="$ROOT/scripts/dmg"
BACKGROUND="$DMG_ASSETS/background@2x.png"
ICON_ICNS="$ROOT/src-tauri/icons/icon.icns"

STAGE_APP="${1:?Usage: build-dmg.sh <path-to-ParseKit.app>}"

if [[ ! -x "$BUNDLE_DMG" ]]; then
  echo "error: bundle_dmg.sh not found — run npm run tauri build first" >&2
  exit 1
fi

mkdir -p "$DMG_DIR"

echo "Generating DMG backgrounds (1x + 2x)..."
(
  cd "$DMG_ASSETS"
  swift GenerateBackground.swift
)

if [[ ! -f "$BACKGROUND" ]]; then
  echo "error: missing $BACKGROUND after GenerateBackground.swift" >&2
  exit 1
fi

DMG_STAGE="$(mktemp -d)"
cleanup() { rm -rf "$DMG_STAGE"; }
trap cleanup EXIT

ditto --norsrc "$STAGE_APP" "$DMG_STAGE/ParseKit.app"

cat > "$DMG_STAGE/.install-readme.txt" << 'README'
ParseKit install tips:
• Drag ParseKit.app into Applications (not Desktop).
• Eject this disk image, then open ParseKit from Applications.
• If macOS blocks launch: paste the Terminal command shown on the installer background.
README
chflags hidden "$DMG_STAGE/.install-readme.txt" 2>/dev/null || true

rm -f "$DMG_OUT"

# Locked coordinate contract — must match GenerateBackground.swift and tauri.conf.json
DMG_W=720
DMG_H=460
ICON_SIZE=128
# Icon center positions (create-dmg / Finder layout coordinates)
APP_ICON_X=190
APP_ICON_Y=172
APPS_LINK_X=530
APPS_LINK_Y=172

"$BUNDLE_DMG" \
  --volname "ParseKit" \
  --volicon "$ICON_ICNS" \
  --background "$BACKGROUND" \
  --window-pos 200 120 \
  --window-size "$DMG_W" "$DMG_H" \
  --icon-size "$ICON_SIZE" \
  --text-size 13 \
  --hide-extension "ParseKit.app" \
  --icon "ParseKit.app" "$APP_ICON_X" "$APP_ICON_Y" \
  --app-drop-link "$APPS_LINK_X" "$APPS_LINK_Y" \
  "$DMG_OUT" \
  "$DMG_STAGE"

echo "Styled DMG: $DMG_OUT"
echo "  window: ${DMG_W}×${DMG_H}  icon-size: ${ICON_SIZE}"
echo "  ParseKit.app @ (${APP_ICON_X}, ${APP_ICON_Y})  Applications @ (${APPS_LINK_X}, ${APPS_LINK_Y})"