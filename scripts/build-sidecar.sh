#!/usr/bin/env bash
set -euo pipefail

TRIPLE=$(rustc -Vv | grep host | awk '{print $2}')

if [ -z "$TRIPLE" ]; then
  echo "Error: could not determine host triple from rustc. Is rustc installed?" >&2
  exit 1
fi

mkdir -p src-tauri/binaries

bun build sidecar/index.js --compile --outfile "src-tauri/binaries/parsedock-sidecar-$TRIPLE"
