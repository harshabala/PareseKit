#!/usr/bin/env bash
# Build a styled ParseKit DMG — frozen static background + Finder icon overlay.
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

bg_dims() {
  magick identify -format "%wx%h" "$1" 2>/dev/null || echo "missing"
}

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

# ── Static background only (default) ─────────────────────────────────────────
# Artwork lives in packaging/dmg/assets/ and is never modified by this script.
# Opt-in regeneration (emergency only): FORCE_DMG_BACKGROUND_REGEN=1
if [[ "${FORCE_DMG_BACKGROUND_REGEN:-}" == "1" ]]; then
  echo "warning: FORCE_DMG_BACKGROUND_REGEN=1 — regenerating backgrounds (not for release builds)" >&2
  MASTER_BG="$DMG_ASSETS/background-master.png"
  (
    cd "$ROOT/scripts/dmg"
    swift GenerateBackground.swift
    cp background-master.png "$MASTER_BG"
  )
  magick "$MASTER_BG" -filter Lanczos -resize 1440x920! -strip PNG32:"$BACKGROUND_2X"
  magick "$MASTER_BG" -filter Lanczos -resize 720x460! -strip PNG24:"$BACKGROUND_1X"
  sips -s dpiWidth 72 -s dpiHeight 72 "$BACKGROUND_1X" >/dev/null
  sips -s dpiWidth 144 -s dpiHeight 144 "$BACKGROUND_2X" >/dev/null
else
  echo "DMG background: static (no resize, no re-encode, no regeneration)"
fi

for f in "$BACKGROUND_1X" "$BACKGROUND_2X"; do
  if [[ ! -f "$f" ]]; then
    echo "error: missing frozen asset $f" >&2
    exit 1
  fi
done

validate_png "$BACKGROUND_1X" 720 460
validate_png "$BACKGROUND_2X" 1440 920

echo "  1× asset:  $BACKGROUND_1X ($(bg_dims "$BACKGROUND_1X")) $(stat -f%z "$BACKGROUND_1X" 2>/dev/null || stat -c%s "$BACKGROUND_1X") bytes"
echo "  @2x asset: $BACKGROUND_2X ($(bg_dims "$BACKGROUND_2X")) $(stat -f%z "$BACKGROUND_2X" 2>/dev/null || stat -c%s "$BACKGROUND_2X") bytes"
echo "  embed:     byte-copy via create-dmg.sh → .background/ (UDZO is lossless)"

mkdir -p "$DMG_DIR"

DMG_STAGE="$(mktemp -d)"
cleanup() { rm -rf "$DMG_STAGE"; }
trap cleanup EXIT

ditto --norsrc "$STAGE_APP" "$DMG_STAGE/ParseKit.app"

rm -f "$DMG_OUT"

# Locked coordinate contract — single source: packaging/dmg/layout.json
LAYOUT_JSON="$ROOT/packaging/dmg/layout.json"
if [[ ! -f "$LAYOUT_JSON" ]]; then
  echo "error: missing $LAYOUT_JSON" >&2
  exit 1
fi
read_layout() {
  node -p "const j=require('$LAYOUT_JSON'); $1"
}
DMG_W="$(read_layout 'j.window.width')"
DMG_H="$(read_layout 'j.window.height')"
ICON_SIZE="$(read_layout 'j.iconSize')"
APP_ICON_X="$(read_layout 'j.parseKit.x')"
APP_ICON_Y="$(read_layout 'j.parseKit.y')"
APPS_LINK_X="$(read_layout 'j.applications.x')"
APPS_LINK_Y="$(read_layout 'j.applications.y')"

DMG_VOLNAME="${DMG_VOLNAME:-ParseKit}"
if [[ "${DMG_UNIQUE_VOLNAME:-}" == "1" ]]; then
  DMG_VOLNAME="ParseKit-test-$(date +%Y%m%d%H%M%S)"
fi

"$CREATE_DMG" \
  --volname "$DMG_VOLNAME" \
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
echo "  volume name: ${DMG_VOLNAME}"
echo "  window: ${DMG_W}×${DMG_H} (36:23)"
echo "  backgrounds: static $BACKGROUND_1X + $BACKGROUND_2X"
echo "  icon-size: ${ICON_SIZE}"
echo "  ParseKit.app @ (${APP_ICON_X}, ${APP_ICON_Y})  Applications @ (${APPS_LINK_X}, ${APPS_LINK_Y})"

"$VERIFY_DMG" "$DMG_OUT"

FRESH_COPY="$(mktemp /tmp/ParseKit-fresh-verify.XXXXXX.dmg)"
cp "$DMG_OUT" "$FRESH_COPY"
"$VERIFY_DMG" "$FRESH_COPY"
rm -f "$FRESH_COPY"

echo "DMG build + layout verification passed"