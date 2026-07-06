#!/usr/bin/env python3
"""Read Finder icon positions from a DMG mount or folder .DS_Store.

Use this after YOU arrange icons in Finder:
  1. Open the DMG (or a test folder with ParseKit.app + Applications alias)
  2. View → as Icons, adjust icon size to 128×128 if needed
  3. Drag ParseKit.app and Applications until alignment looks perfect
  4. Close the Finder window (writes .DS_Store)
  5. Run: python3 scripts/dmg/capture-layout-from-finder.py /Volumes/ParseKit

Paste the output into scripts/dmg/layout.json or send it to your agent.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from ds_store import DSStore
except ImportError:
    print(
        "error: ds_store not installed. Run:\n"
        "  cd scripts/dmg && python3 -m venv .venv && .venv/bin/pip install ds_store mac_alias",
        file=sys.stderr,
    )
    sys.exit(1)


def read_ilocs(ds_path: Path) -> dict[str, tuple[int, int]]:
    out: dict[str, tuple[int, int]] = {}
    with DSStore.open(str(ds_path), "r+") as store:
        for entry in store.iter_records():
            name = entry.filename
            if name not in ("ParseKit.app", "Applications"):
                continue
            for code, value in entry.typedata.items():
                if code.decode("ascii", "ignore") != "Iloc":
                    continue
                if isinstance(value, (list, tuple)) and len(value) >= 2:
                    x, y = int(value[0]), int(value[1])
                    out[name] = (x, y)
    return out


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 1

    root = Path(sys.argv[1]).resolve()
    ds = root / ".DS_Store"
    if not ds.is_file():
        print(f"error: no .DS_Store at {ds}", file=sys.stderr)
        print("Close the Finder window after arranging icons, then retry.", file=sys.stderr)
        return 1

    ilocs = read_ilocs(ds)
    if not ilocs:
        print("error: no Iloc records for ParseKit.app / Applications", file=sys.stderr)
        return 1

    parse = ilocs.get("ParseKit.app", (0, 0))
    apps = ilocs.get("Applications", (0, 0))

    layout = {
        "window": {"width": 720, "height": 460},
        "iconSize": 128,
        "parseKit": {"x": parse[0], "y": parse[1]},
        "applications": {"x": apps[0], "y": apps[1]},
        "parseKitCenter": {"x": parse[0] + 64, "y": parse[1] + 64},
        "applicationsCenter": {"x": apps[0] + 64, "y": apps[1] + 64},
        "arrowY": min(parse[1], apps[1]) + 50,
    }

    print("# Paste into packaging/dmg/layout.json")
    print(json.dumps(layout, indent=2))
    print()
    print("# For scripts/dmg/build-dmg.sh:")
    print(f"APP_ICON_X={parse[0]}")
    print(f"APP_ICON_Y={parse[1]}")
    print(f"APPS_LINK_X={apps[0]}")
    print(f"APPS_LINK_Y={apps[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())