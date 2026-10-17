"""
Python 3 + opencv-python-headless (pin to 4.x -- 5.x dropped CascadeClassifier/Haar data
from the wheel). Re-crop a source frame sequence to follow the subject's head/face
("head lock") instead of a static center crop.

Usage: python3 track_crop.py <src_frames_dir> <out_dir>
  src_frames_dir: f####.jpg frames straight from ffmpeg (same resolution the
                  WATERMARK_BOXES/CUTS constants below were measured against -- 576x576).
  out_dir:        written at OUT_W x OUT_H, ready to feed into build_pack.py.

Re-run this (and re-time CUTS, re-measure WATERMARK_BOXES) any time the source clip
changes; both are specific to the current footage, not reusable as-is for a different one.
"""
import cv2
import glob
import os
import sys
import numpy as np

SRC_DIR = sys.argv[1]
OUT_DIR = sys.argv[2]
FPS = 20
OUT_W, OUT_H = 460, 560
MAX_CROP_H = 576
ASPECT = OUT_W / OUT_H
EMA_ALPHA = 0.25
MAX_STEP = 40

# how tight to crop, keyed by how much we actually trust the target for that frame.
# A held-lock frame has no real detection behind it for THIS shot's content -- cropping
# it as tight as a real tracked face just zooms into a random, meaningless patch of
# whatever happens to be at that old position. Confidence drives zoom, not just position.
ZOOM_BY_TIER = {"tracked": 3.3, "medoid": 1.8, "held": 1.0}
# "medoid" is a single real detection, not a confirmed smooth track -- one detection's
# exact center is often slightly off, and tight zoom amplifies that into looking like a
# random crop. Staying wide here keeps it centered on something real without punishing a
# few pixels of error. "held" gets no zoom at all: a shot with zero face hits has nothing
# real to center on, and MAX_CROP_H here means the original frame passes through
# basically uncropped -- the intended full composition, not an arbitrary zoomed window.
MIN_CROP_H_BY_TIER = {"tracked": 300, "medoid": 460, "held": MAX_CROP_H}

# same cut points the Lua schedule uses -- each shot is tracked independently so a miss
# in one shot can never inherit a locked-on position from a completely different shot
CUTS = [0.0, 0.467, 1.3, 2.133, 2.933, 3.733, 4.833, 5.767, 6.9,
        8.1, 9.0, 10.1, 11.0, 11.8, 12.667, 13.5, 13.8]
SEGMENTS = [(round(CUTS[i] * FPS), round(CUTS[i + 1] * FPS)) for i in range(len(CUTS) - 1)]

# the two watermark boxes baked in at 576x576 (see the drawbox pass used to build the
# very first version of this pack)
WATERMARK_BOXES = [(0, 0, 230, 100), (366, 462, 210, 114)]

os.makedirs(OUT_DIR, exist_ok=True)

frontal = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
profile = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_profileface.xml")

files = sorted(glob.glob(os.path.join(SRC_DIR, "f*.jpg")))
if not files:
    raise SystemExit("no frames found in " + SRC_DIR)

def inpaint_watermarks(img):
    mask = np.zeros(img.shape[:2], dtype=np.uint8)
    for (x, y, w, h) in WATERMARK_BOXES:
        mask[y:y + h, x:x + w] = 255
    return cv2.inpaint(img, mask, 7, cv2.INPAINT_TELEA)

MAX_FACE = (150, 150)  # confirmed-good hits in this clip top out around 140px

def detect(gray):
    candidates = []
    for cascade in (frontal, profile):
        found = cascade.detectMultiScale(gray, scaleFactor=1.08, minNeighbors=5, minSize=(50, 50), maxSize=MAX_FACE)
        candidates.extend(tuple(b) for b in found)
    flipped = cv2.flip(gray, 1)
    found = profile.detectMultiScale(flipped, scaleFactor=1.08, minNeighbors=5, minSize=(50, 50), maxSize=MAX_FACE)
    W = gray.shape[1]
    for (x, y, w, h) in found:
        candidates.append((W - x - w, y, w, h))
    if not candidates:
        return None
    x, y, w, h = max(candidates, key=lambda b: b[2] * b[3])
    return (x + w / 2.0, y + h / 2.0, h)

images = [inpaint_watermarks(cv2.imread(f)) for f in files]
h0, w0 = images[0].shape[:2]
GENERIC_DEFAULT = (w0 / 2.0, h0 * 0.40, h0 * 0.20)

raw = []
for img in images:
    gray = cv2.equalizeHist(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY))
    raw.append(detect(gray))

hit_count = sum(1 for r in raw if r is not None)
print(f"{hit_count}/{len(raw)} direct face hits")

MIN_HITS = 4       # fewer real detections than this in a shot isn't enough to trust frame-by-frame
MAX_SPREAD = 140   # px; hits scattered wider than this are false positives, not a real pan

# carried across segments on purpose (unlike everything else, which resets per shot):
# a shot with zero face hits is usually a genuine faceless insert (a legs/hands cutaway),
# and "always a head on frame" means holding the last real lock through it rather than
# either reverting to a generic guess or showing that faceless content raw
lock = GENERIC_DEFAULT

targets = [None] * len(raw)
tiers = [None] * len(raw)
for start, end in SEGMENTS:
    start = max(0, start)
    end = min(len(raw), end)
    if start >= end:
        continue
    seg = raw[start:end]
    seg_hits = [r for r in seg if r is not None]

    xs = [h[0] for h in seg_hits]
    spread_ok = seg_hits and (max(xs) - min(xs)) <= MAX_SPREAD
    if len(seg_hits) >= MIN_HITS and spread_ok:
        # dense, consistent detections -- track them frame by frame (fill-forward,
        # back-fill the leading gap, damp+smooth) so real motion within the shot follows.
        # The smoothing starts from the carried lock, not cold, so the camera eases from
        # wherever it last was into this shot's track instead of snapping.
        filled = []
        last = None
        for r in seg:
            if r is not None:
                last = r
            filled.append(last)
        first_known = next(r for r in filled if r is not None)
        filled = [r if r is not None else first_known for r in filled]

        damped = [lock]
        for cx, cy, fh in filled:
            pcx, pcy, _ = damped[-1]
            dx, dy = cx - pcx, cy - pcy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist > MAX_STEP:
                scale = MAX_STEP / dist
                cx, cy = pcx + dx * scale, pcy + dy * scale
            damped.append((cx, cy, fh))
        damped = damped[1:]

        smoothed = [lock]
        for cx, cy, fh in damped:
            pcx, pcy, pfh = smoothed[-1]
            smoothed.append((
                pcx + EMA_ALPHA * (cx - pcx),
                pcy + EMA_ALPHA * (cy - pcy),
                pfh + EMA_ALPHA * (fh - pfh),
            ))
        smoothed = smoothed[1:]

        for i, t in zip(range(start, end), smoothed):
            targets[i] = t
            tiers[i] = "tracked"
        lock = smoothed[-1]
    elif len(seg_hits) >= 2:
        # too sparse or too scattered to be a real pan -- hold one stable position for
        # the whole shot instead of chasing noise. Picking the single detected hit
        # closest to the centroid (the medoid) keeps the target an actual real
        # detection; averaging x/y/h independently per axis instead would Frankenstein
        # together the x from one hit and the y from a completely different one
        mean_x = sum(h[0] for h in seg_hits) / len(seg_hits)
        mean_y = sum(h[1] for h in seg_hits) / len(seg_hits)
        medoid = min(seg_hits, key=lambda h: (h[0] - mean_x) ** 2 + (h[1] - mean_y) ** 2)
        for i in range(start, end):
            targets[i] = medoid
            tiers[i] = "medoid"
        lock = medoid
    else:
        # no face, or a single uncorroborated hit -- not enough evidence on its own,
        # hold the last real lock through it
        for i in range(start, end):
            targets[i] = lock
            tiers[i] = "held"

for t in ("tracked", "medoid", "held"):
    print(f"{tiers.count(t)} frames at tier '{t}'")

for f, img, (cx, cy, fh), tier in zip(files, images, targets, tiers):
    H, W = img.shape[:2]

    crop_h = max(MIN_CROP_H_BY_TIER[tier], min(MAX_CROP_H, fh * ZOOM_BY_TIER[tier]))
    crop_w = crop_h * ASPECT
    if crop_w > W:
        crop_w = W
        crop_h = crop_w / ASPECT

    cy_eff = cy - fh * 0.12  # a little more chest room than headroom
    x0 = max(0, min(W - crop_w, cx - crop_w / 2))
    y0 = max(0, min(H - crop_h, cy_eff - crop_h / 2))

    x0, y0, crop_w, crop_h = int(round(x0)), int(round(y0)), int(round(crop_w)), int(round(crop_h))
    crop = img[y0:y0 + crop_h, x0:x0 + crop_w]

    interp = cv2.INTER_AREA if crop_h >= OUT_H else cv2.INTER_CUBIC
    out = cv2.resize(crop, (OUT_W, OUT_H), interpolation=interp)
    cv2.imwrite(os.path.join(OUT_DIR, os.path.basename(f)), out, [cv2.IMWRITE_JPEG_QUALITY, 90])

print(f"wrote {len(files)} cropped frames -> {OUT_DIR}")
