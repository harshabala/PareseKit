#!/usr/bin/env python3
"""Rebuild DMG .DS_Store with dark icvp background so Finder uses white labels.

Finder label color follows icvp backgroundColor*, not the PNG. create-dmg often
leaves these at white (1,1,1), producing dark/gray labels on image backgrounds.
See: https://github.com/create-dmg/create-dmg/issues/197
"""
from __future__ import annotations

import copy
import os
import sys
import time

# Match packaging/dmg/background.html base (#12172B).
NAVY_RGB = (18 / 255.0, 23 / 255.0, 43 / 255.0)

# Locked icon top-left positions (must match build-dmg.sh).
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

            try:
                os.replace(tmp_path, ds_store_path)
            except OSError:
                import shutil

                shutil.copy2(tmp_path, ds_store_path)
            finally:
                if os.path.exists(tmp_path):
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
    print(f"patched {sys.argv[1]} (icvp backgroundColor → navy, white Finder labels)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())