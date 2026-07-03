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

# Icon top-left positions from build contract: ParseKit (126,108), Applications (466,108).
# Iloc blobs store int32 BE-ish quads: 0000007e0000006c and 000001d20000006c.
DS_HEX=$(xxd -p "$DS_STORE" | tr -d '\n')
if [[ "$DS_HEX" != *0000007e0000006c* ]]; then
  echo "error: ParseKit.app Iloc (126,108) not found in .DS_Store" >&2
  exit 1
fi
if [[ "$DS_HEX" != *000001d20000006c* ]]; then
  echo "error: Applications Iloc (466,108) not found in .DS_Store" >&2
  exit 1
fi
echo "verify: icon positions (126,108) and (466,108) encoded in .DS_Store"

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