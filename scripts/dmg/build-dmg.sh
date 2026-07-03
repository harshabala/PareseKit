#!/usr/bin/env bash
# Build a styled ParseKit DMG (design backgrounds + locked icon coordinates).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(node -p "require('$ROOT/package.json').version")"
DMG_DIR="$ROOT/src-tauri/target/release/bundle/dmg"
DMG_OUT="$DMG_DIR/ParseKit_${VERSION}_aarch64.dmg"
CREATE_DMG="$ROOT/scripts/dmg/create-dmg.sh"
VERIFY_DMG="$ROOT/scripts/dmg/verify-dmg-layout.sh"
DMG_ASSETS="$ROOT/packaging/dmg/assets"
BACKGROUND_1X="$DMG_ASSETS/background.png"
BACKGROUND_2X="$DMG_ASSETS/background@2x.png"
ICON_ICNS="$ROOT/src-tauri/icons/icon.icns"

STAGE_APP="${1:?Usage: build-dmg.sh <path-to-ParseKit.app>}"

if [[ ! -x "$CREATE_DMG" ]]; then
  echo "error: $CREATE_DMG not found or not executable" >&2
  exit 1
fi
chmod +x "$VERIFY_DMG"

# Procedural backgrounds match packaging/dmg/background.html layout contract.
if [[ "${SKIP_DMG_BACKGROUND_GEN:-}" != "1" ]]; then
  echo "Generating DMG backgrounds (720×460 contract)..."
  (
    cd "$ROOT/scripts/dmg"
    swift GenerateBackground.swift
    cp background.png background@2x.png "$DMG_ASSETS/"
  )
  sips -s dpiWidth 72 -s dpiHeight 72 "$BACKGROUND_1X" >/dev/null
  sips -s dpiWidth 144 -s dpiHeight 144 "$BACKGROUND_2X" >/dev/null
fi

for f in "$BACKGROUND_1X" "$BACKGROUND_2X"; do
  if [[ ! -f "$f" ]]; then
    echo "error: missing design asset $f" >&2
    exit 1
  fi
  echo "background asset OK: $f ($(stat -f%z "$f" 2>/dev/null || stat -c%s "$f") bytes)"
done

validate_png() {
  local path="$1" expect_w="$2" expect_h="$3"
  local w h
  w=$(sips -g pixelWidth "$path" 2>/dev/null | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$path" 2>/dev/null | awk '/pixelHeight/{print $2}')
  if [[ "$w" != "$expect_w" || "$h" != "$expect_h" ]]; then
    echo "error: $path is ${w}x${h}, expected ${expect_w}x${expect_h}" >&2
    exit 1
  fi
}
validate_png "$BACKGROUND_1X" 720 460
validate_png "$BACKGROUND_2X" 1440 920

mkdir -p "$DMG_DIR"

DMG_STAGE="$(mktemp -d)"
cleanup() { rm -rf "$DMG_STAGE"; }
trap cleanup EXIT

ditto --norsrc "$STAGE_APP" "$DMG_STAGE/ParseKit.app"

rm -f "$DMG_OUT"

# Locked coordinate contract — create-dmg/AppleScript position = top-left.
DMG_W=720
DMG_H=460
ICON_SIZE=128
APP_ICON_X=126
APP_ICON_Y=108
APPS_LINK_X=466
APPS_LINK_Y=108

"$CREATE_DMG" \
  --volname "ParseKit" \
  --volicon "$ICON_ICNS" \
  --background "$BACKGROUND_1X" \
  --background-retina "$BACKGROUND_2X" \
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
echo "  backgrounds: $BACKGROUND_1X + $BACKGROUND_2X"
echo "  window: ${DMG_W}×${DMG_H}  icon-size: ${ICON_SIZE}"
echo "  ParseKit.app @ (${APP_ICON_X}, ${APP_ICON_Y})  Applications @ (${APPS_LINK_X}, ${APPS_LINK_Y})"

# Mandatory layout verification on the compressed shipping artifact.
"$VERIFY_DMG" "$DMG_OUT"

# Fresh-mount simulation: copy to a new filename and verify again (no Finder cache).
FRESH_COPY="$(mktemp /tmp/ParseKit-fresh-verify.XXXXXX.dmg)"
cp "$DMG_OUT" "$FRESH_COPY"
"$VERIFY_DMG" "$FRESH_COPY"
rm -f "$FRESH_COPY"

echo "DMG build + layout verification passed"