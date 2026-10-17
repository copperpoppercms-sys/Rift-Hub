"""
Pack a directory of f####.jpg frames (e.g. tools/track_crop.py's output) into the
single-file "XHPK1" format assets/frames.pack expects:
  "XHPK1 <count>\n<size1> <size2> ... <sizeN>\n<raw bytes concatenated>"

Usage: python3 build_pack.py <frames_dir> <out_pack_path>
"""
import sys
import glob
import os

frames_dir = sys.argv[1]
out_path = sys.argv[2]

files = sorted(glob.glob(os.path.join(frames_dir, "f*.jpg")))
if not files:
    raise SystemExit("no frames found in " + frames_dir)

blobs = [open(f, "rb").read() for f in files]
sizes = [str(len(b)) for b in blobs]

header = f"XHPK1 {len(blobs)}\n".encode("ascii")
sizes_line = (" ".join(sizes) + "\n").encode("ascii")

with open(out_path, "wb") as out:
    out.write(header)
    out.write(sizes_line)
    for b in blobs:
        out.write(b)

print(f"packed {len(blobs)} frames, {os.path.getsize(out_path)} bytes -> {out_path}")
