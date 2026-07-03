#!/usr/bin/env python3
"""Patch DMG .DS_Store icvp in-place so Finder uses white labels on dark backgrounds.

Finder label color follows icvp backgroundColor*, not the PNG. create-dmg leaves
these at white (1,1,1), producing dark labels. In-place patch preserves AppleScript
settings (hide extension, icon positions, background alias).
"""
from __future__ import annotations

import copy
import sys
import time

# Match packaging/dmg/background.html base (#12172B).
NAVY_RGB = (18 / 255.0, 23 / 255.0, 43 / 255.0)


def patch(ds_store_path: str) -> None:
    from ds_store import DSStore

    last_err: Exception | None = None
    for _ in range(15):
        try:
            store = DSStore.open(ds_store_path, "r+")
            icvp = copy.deepcopy(store["."]["icvp"])
            icvp["backgroundColorRed"] = NAVY_RGB[0]
            icvp["backgroundColorGreen"] = NAVY_RGB[1]
            icvp["backgroundColorBlue"] = NAVY_RGB[2]
            icvp["showItemInfo"] = False
            store["."]["icvp"] = icvp
            store.flush()
            store.close()
            return
        except KeyError as err:
            last_err = err
            time.sleep(1)
        except Exception as err:
            last_err = err
            time.sleep(1)

    raise RuntimeError(f"failed to patch {ds_store_path}") from last_err


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <path-to-.DS_Store>", file=sys.stderr)
        return 1
    patch(sys.argv[1])
    print(f"patched {sys.argv[1]} (icvp backgroundColor → navy)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())