#!/usr/bin/env bash
# Verify shipped DMG has persisted Finder layout (.DS_Store + backgrounds + icon positions).
set -euo pipefail

DMG_PATH="${1:?Usage: verify-dmg-layout.sh <path-to.dmg>}"

MOUNT_DIR="$(mktemp -d /tmp/parsekit-dmg-verify.XXXXXX)"
cleanup() {
  hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
  rmdir "$MOUNT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "verify: mounting ${DMG_PATH}"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null

DS_STORE="${MOUNT_DIR}/.DS_Store"
if [[ ! -f "$DS_STORE" ]]; then
  echo "error: .DS_Store missing in shipped DMG" >&2
  exit 1
fi

DS_SIZE=$(stat -f%z "$DS_STORE" 2>/dev/null || stat -c%s "$DS_STORE")
if [[ "$DS_SIZE" -lt 1024 ]]; then
  echo "error: .DS_Store too small (${DS_SIZE} bytes)" >&2
  exit 1
fi
echo "verify: .DS_Store ${DS_SIZE} bytes"

for bg in background.png "background@2x.png"; do
  if [[ ! -f "${MOUNT_DIR}/.background/${bg}" ]]; then
    echo "error: missing .background/${bg}" >&2
    exit 1
  fi
done
echo "verify: background assets present"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ASSETS="$ROOT/packaging/dmg/assets"
bg_px() {
  sips -g pixelWidth -g pixelHeight "$1" 2>/dev/null | awk '/pixel/{print $2}' | tr '\n' 'x' | sed 's/x$//'
}
BG1="${MOUNT_DIR}/.background/background.png"
BG2="${MOUNT_DIR}/.background/background@2x.png"
echo "verify: embedded 1× background $(bg_px "$BG1") (expect 720x460)"
echo "verify: embedded @2x background $(bg_px "$BG2") (expect 1440x920)"
if [[ "$(sips -g pixelWidth "$BG1" 2>/dev/null | awk '/pixelWidth/{print $2}')" != "720" ]] \
  || [[ "$(sips -g pixelHeight "$BG1" 2>/dev/null | awk '/pixelHeight/{print $2}')" != "460" ]]; then
  echo "error: .background/background.png wrong dimensions" >&2
  exit 1
fi
if [[ "$(sips -g pixelWidth "$BG2" 2>/dev/null | awk '/pixelWidth/{print $2}')" != "1440" ]] \
  || [[ "$(sips -g pixelHeight "$BG2" 2>/dev/null | awk '/pixelHeight/{print $2}')" != "920" ]]; then
  echo "error: .background/background@2x.png wrong dimensions" >&2
  exit 1
fi
if [[ -f "$ASSETS/background.png" && -f "$ASSETS/background@2x.png" ]]; then
  if ! cmp -s "$ASSETS/background.png" "$BG1"; then
    echo "error: DMG 1× background differs from frozen asset" >&2
    exit 1
  fi
  if ! cmp -s "$ASSETS/background@2x.png" "$BG2"; then
    echo "error: DMG @2x background differs from frozen asset" >&2
    exit 1
  fi
  echo "verify: embedded backgrounds byte-identical to packaging/dmg/assets (Retina asset shipped)"
fi

if ! strings "$DS_STORE" | grep -q 'Iloc'; then
  echo "error: .DS_Store missing Iloc (icon positions)" >&2
  exit 1
fi
if ! strings "$DS_STORE" | grep -q 'icvp'; then
  echo "error: .DS_Store missing icvp (view/background options)" >&2
  exit 1
fi
if ! strings "$DS_STORE" | grep -q 'backgroundImageAlias'; then
  echo "error: .DS_Store missing backgroundImageAlias" >&2
  exit 1
fi
echo "verify: Iloc + icvp + backgroundImageAlias present"

# Icon top-left positions from packaging/dmg/layout.json (Iloc = int32 BE x + y).
LAYOUT_JSON="$(cd "$(dirname "$0")/../.." && pwd)/packaging/dmg/layout.json"
read_layout() {
  node -p "const j=require('$LAYOUT_JSON'); $1"
}
APP_X="$(read_layout 'j.parseKit.x')"
APP_Y="$(read_layout 'j.parseKit.y')"
APPS_X="$(read_layout 'j.applications.x')"
APPS_Y="$(read_layout 'j.applications.y')"
APP_HEX=$(printf '%08x%08x' "$APP_X" "$APP_Y")
APPS_HEX=$(printf '%08x%08x' "$APPS_X" "$APPS_Y")
DS_HEX=$(xxd -p "$DS_STORE" | tr -d '\n')
if [[ "$DS_HEX" != *"$APP_HEX"* ]]; then
  echo "error: ParseKit.app Iloc (${APP_X},${APP_Y}) / ${APP_HEX} not found in .DS_Store" >&2
  exit 1
fi
if [[ "$DS_HEX" != *"$APPS_HEX"* ]]; then
  echo "error: Applications Iloc (${APPS_X},${APPS_Y}) / ${APPS_HEX} not found in .DS_Store" >&2
  exit 1
fi
echo "verify: icon positions (${APP_X},${APP_Y}) and (${APPS_X},${APPS_Y}) encoded in .DS_Store"

# Only user-visible entries at volume root (find avoids colorized ls output).
unexpected=()
while IFS= read -r entry; do
  name=$(basename "$entry")
  case "$name" in
    ParseKit.app|Applications) ;;
    *) unexpected+=("$name") ;;
  esac
done < <(find "$MOUNT_DIR" -maxdepth 1 -mindepth 1 ! -name '.*' -print 2>/dev/null)
if [[ ${#unexpected[@]} -gt 0 ]]; then
  echo "error: unexpected visible DMG entries: ${unexpected[*]}" >&2
  exit 1
fi

echo "verify: DMG layout OK — ${DMG_PATH}"