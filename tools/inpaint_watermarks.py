"""
Remove a fixed-position watermark overlay (e.g. a TikTok corner bug) from a frame
sequence by inpainting it instead of blacking it out -- a solid black box reads as an
obvious rectangle, especially over bright backgrounds or once the footage is cropped in
tight; inpainting reconstructs that patch from the surrounding pixels instead.

Usage: python3 inpaint_watermarks.py <src_frames_dir> <out_dir>

BOXES below are specific to the current source clip's watermark position/size at
whatever resolution the frames were extracted at (e.g. via ffmpeg -vf scale=W:H) --
re-measure them (see the tl_check/br_check crop-and-eyeball approach, or a
pixel-variance map across a few seconds of frames) any time the source clip changes.
"""
import cv2
import glob
import os
import sys
import numpy as np

SRC_DIR = sys.argv[1]
OUT_DIR = sys.argv[2]

BOXES = [(0, 0, 131, 75), (625, 353, 143, 79)]

os.makedirs(OUT_DIR, exist_ok=True)
files = sorted(glob.glob(os.path.join(SRC_DIR, "f*.jpg")))
if not files:
    raise SystemExit("no frames found in " + SRC_DIR)

for f in files:
    img = cv2.imread(f)
    mask = np.zeros(img.shape[:2], dtype=np.uint8)
    for (x, y, w, h) in BOXES:
        mask[y:y + h, x:x + w] = 255
    out = cv2.inpaint(img, mask, 7, cv2.INPAINT_TELEA)
    cv2.imwrite(os.path.join(OUT_DIR, os.path.basename(f)), out, [cv2.IMWRITE_JPEG_QUALITY, 80])

print(f"inpainted {len(files)} frames -> {OUT_DIR}")
