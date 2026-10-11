#!/usr/bin/env python3
"""Audit a Godot pack for missing imported payloads.

This exists because of a real shipped defect: `godot --headless --import` aborts
the whole scan (it never reaches `reimport_files()`) when any file needs an
external tool that cannot be configured in headless mode - a `.blend` needs
Blender, an `.fbx` needs FBX2glTF. The import step then looks successful, the
exporter still writes every `.import` destination path into the pack, and each
of those entries lands with size 0. The result installs and boots but has no
textures, no fonts and capsule-shaped players.

Godot's own pack directory lists every file with its size, so an empty payload
is directly detectable. Stdlib only: no pip install needed on a CI runner.

Usage: tools/audit_pck.py <pack> [--min-ctex N] [--min-sample N] ...
"""

import argparse
import collections
import os
import struct
import sys

MAGIC = b"GDPC"
HEADER_DIR_OFFSET = 32  # u64 pointer to the directory, which Godot writes last
ENTRY_FIXED = 36  # u64 offset + u64 size + md5[16] + u32 flags

# Extension -> (description, minimum file count, minimum total bytes)
REQUIRED = {
    ".ctex": ("textures", 4000, 20 << 20),
    ".fontdata": ("fonts", 20, 0),
    ".sample": ("audio", 300, 0),
    ".scn": ("scenes", 150, 0),
    ".gdc": ("scripts", 100, 0),
}


def read_directory(raw):
    if raw[:4] != MAGIC:
        raise SystemExit("not a Godot pack (bad magic)")
    dir_off, = struct.unpack_from("<Q", raw, HEADER_DIR_OFFSET)
    if not 0 < dir_off < len(raw):
        raise SystemExit(f"implausible directory offset {dir_off}")
    count, = struct.unpack_from("<I", raw, dir_off)
    off = dir_off + 4
    entries = []
    for _ in range(count):
        plen, = struct.unpack_from("<I", raw, off)
        name = raw[off + 4:off + 4 + plen].decode("utf-8", "replace").rstrip("\x00")
        end = off + 4 + plen
        foff, fsize = struct.unpack_from("<QQ", raw, end)
        entries.append((name, foff, fsize))
        off = end + ENTRY_FIXED
    return dir_off, entries


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pack")
    ap.add_argument("--label", default="")
    args = ap.parse_args()

    raw = open(args.pack, "rb").read()
    dir_off, entries = read_directory(raw)

    counts = collections.Counter()
    totals = collections.Counter()
    empty = []
    for name, _off, size in entries:
        ext = os.path.splitext(name)[1].lower()
        counts[ext] += 1
        totals[ext] += size
        if size == 0:
            empty.append(name)

    label = args.label or os.path.basename(args.pack)
    print(f"=== {label} ===")
    print(f"entries {len(entries):,}   data {dir_off / 1048576:.1f} MiB   "
          f"size {len(raw) / 1048576:.1f} MiB")
    for ext, (desc, need, min_bytes) in REQUIRED.items():
        print(f"  {desc:<9} {counts[ext]:>6} files  {totals[ext] / 1048576:>8.1f} MiB")

    problems = []
    if empty:
        problems.append(f"{len(empty)} packed files are empty (first: {empty[:4]})")
    for ext, (desc, need, min_bytes) in REQUIRED.items():
        if counts[ext] < need:
            problems.append(f"only {counts[ext]} {desc} ({ext}) packed, expected >= {need}")
        if totals[ext] < min_bytes:
            problems.append(f"{desc} payload is {totals[ext]} bytes, expected >= {min_bytes}")

    # Independent of the directory: real texture data has to be in the data section.
    texture_headers = raw[:dir_off].count(b"GST2")
    print(f"  texture headers found in data section: {texture_headers}")
    if texture_headers < 4000:
        problems.append(f"only {texture_headers} texture headers in the data section")

    if problems:
        for p in problems:
            print(f"::error::{p}")
        return 1
    print("pack audit OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
