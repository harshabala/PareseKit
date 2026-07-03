#!/usr/bin/env python3
"""Rebuild DMG .DS_Store with dark icvp background for white Finder labels.

In-place icvp edits corrupt the buddy allocator on modern macOS. We read icvp/bwsp,
apply the navy backgroundColor fix, and write a fresh store with icon positions.
"""
from __future__ import annotations

import copy
import os
import shutil
import sys
import time

NAVY_RGB = (18 / 255.0, 23 / 255.0, 43 / 255.0)
PARSEKIT_ILOC = (126, 108)
APPLICATIONS_ILOC = (466, 108)


def patch(ds_store_path: str) -> None:
    from ds_store import DSStore

    last_err: Exception | None = None
    for _ in range(15):
        try:
            with DSStore.open(ds_store_path, "r") as src:
                icvp = copy.deepcopy(src["."]["icvp"])
                bwsp = src["."]["bwsp"]

            icvp["backgroundColorRed"] = NAVY_RGB[0]
            icvp["backgroundColorGreen"] = NAVY_RGB[1]
            icvp["backgroundColorBlue"] = NAVY_RGB[2]
            icvp["showItemInfo"] = False
            icvp["textSize"] = 1.0
            # backgroundType 2 + backgroundImageAlias must be preserved from src icvp.

            tmp_path = os.path.join("/tmp", f"parsekit-dsstore-{os.getpid()}.patched")
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

            with DSStore.open(tmp_path, "w+") as out:
                out["."]["bwsp"] = bwsp
                out["."]["icvp"] = icvp
                out["."]["icvl"] = ("type", b"icnv")
                out["ParseKit.app"]["Iloc"] = PARSEKIT_ILOC
                out["Applications"]["Iloc"] = APPLICATIONS_ILOC
                out.flush()

            shutil.copy2(tmp_path, ds_store_path)
            os.remove(tmp_path)
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
    print(f"patched {sys.argv[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())