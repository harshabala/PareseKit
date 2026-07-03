#!/usr/bin/env bash
# Build a styled ParseKit DMG (design backgrounds + locked icon coordinates).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(node -p "require('$ROOT/package.json').version")"
DMG_DIR="$ROOT/src-tauri/target/release/bundle/dmg"
DMG_OUT="$DMG_DIR/ParseKit_${VERSION}_aarch64.dmg"
CREATE_DMG="$ROOT/scripts/dmg/create-dmg.sh"
DMG_ASSETS="$ROOT/packaging/dmg/assets"
BACKGROUND_1X="$DMG_ASSETS/background.png"
BACKGROUND_2X="$DMG_ASSETS/background@2x.png"
ICON_ICNS="$ROOT/src-tauri/icons/icon.icns"

STAGE_APP="${1:?Usage: build-dmg.sh <path-to-ParseKit.app>}"

if [[ ! -x "$CREATE_DMG" ]]; then
  echo "error: $CREATE_DMG not found or not executable" >&2
  exit 1
fi

# Procedural backgrounds match packaging/dmg/background.html (Open Design PNG exports were mis-cropped).
if [[ "${SKIP_DMG_BACKGROUND_GEN:-}" != "1" ]]; then
  echo "Generating DMG backgrounds (720×460 contract)..."
  (
    cd "$ROOT/scripts/dmg"
    swift GenerateBackground.swift
    cp background.png background@2x.png "$DMG_ASSETS/"
  )
  # Finder maps pixels→points via DPI: 1× @72dpi, 2× @144dpi (otherwise Retina misaligns art).
  sips -s dpiWidth 72 -s dpiHeight 72 "$BACKGROUND_1X" >/dev/null
  sips -s dpiWidth 144 -s dpiHeight 144 "$BACKGROUND_2X" >/dev/null
fi

for f in "$BACKGROUND_1X" "$BACKGROUND_2X"; do
  if [[ ! -f "$f" ]]; then
    echo "error: missing design asset $f" >&2
    echo "hint: copy delivered background.png and background@2x.png into packaging/dmg/assets/" >&2
    exit 1
  fi
done

# Validate dimensions (handoff contract).
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

# Locked coordinate contract — must match packaging/dmg/background.html layout.
# create-dmg positions icons by top-left; wells center at (190,172) and (530,172).
DMG_W=720
DMG_H=460
ICON_SIZE=128
APP_ICON_X=126   # 190 - ICON_SIZE/2
APP_ICON_Y=108   # 172 - ICON_SIZE/2
APPS_LINK_X=466  # 530 - ICON_SIZE/2
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
echo "  backgrounds: $BACKGROUND_1X + $BACKGROUND_2X → .background/ on volume"
echo "  window: ${DMG_W}×${DMG_H}  icon-size: ${ICON_SIZE}"
echo "  ParseKit.app @ (${APP_ICON_X}, ${APP_ICON_Y})  Applications @ (${APPS_LINK_X}, ${APPS_LINK_Y})"

# Post-build verification on mounted image (best-effort).
VERIFY_MOUNT="$(mktemp -d /tmp/parsekit-dmg-assets-verify.XXXXXX)"
if hdiutil attach -nobrowse -readonly -mountpoint "$VERIFY_MOUNT" "$DMG_OUT" >/dev/null 2>&1; then
  for bg in background.png "background@2x.png"; do
    if [[ ! -f "$VERIFY_MOUNT/.background/$bg" ]]; then
      echo "warn: .background/$bg missing inside DMG" >&2
    fi
  done
  visible=$(ls -1A "$VERIFY_MOUNT" 2>/dev/null | grep -v '^\.' | grep -v '^ParseKit.app$' | grep -v '^Applications$' | grep -v '^\.background$' || true)
  if [[ -n "$visible" ]]; then
    echo "warn: unexpected visible DMG entries: $visible" >&2
  fi
  hdiutil detach "$VERIFY_MOUNT" -quiet 2>/dev/null || true
  rmdir "$VERIFY_MOUNT" 2>/dev/null || true
fi