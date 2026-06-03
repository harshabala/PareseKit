#!/usr/bin/env bash
# Stop every ParseDock dev/build instance so only one copy can run.
set -euo pipefail

killall -9 parsedock 2>/dev/null || true
if command -v lsof >/dev/null 2>&1; then
  lsof -ti :1420 2>/dev/null | xargs kill -9 2>/dev/null || true
fi
pkill -f "tauri dev" 2>/dev/null || true
pkill -f "vite.*ParseDock" 2>/dev/null || true

echo "All ParseDock processes stopped."