"""Build the hub's looping video assets from the supplied 768x576 clip.

Usage: python tools/build_home_video.py INPUT.mp4 [OUTPUT_DIRECTORY]
Corner cleanup coordinates are specific to this clip, before resizing.
Produces a watermark-cleaned review MP4, Ogg soundtrack, and JPEG frame pack.
"""
import pathlib
import subprocess
import sys
import tempfile

source = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else 'assets').resolve()
out.mkdir(parents=True, exist_ok=True)
FPS = 12
DURATION = 27.5  # End before the source clip's TikTok branding outro.
cleanup = 'delogo=x=8:y=6:w=114:h=94,delogo=x=644:y=474:w=116:h=94'
subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(source), '-vf', cleanup,
                '-t', str(DURATION), '-af', f'afade=t=out:st={DURATION - 0.1}:d=0.1', '-c:v', 'libx264', '-crf', '21', '-preset', 'fast', '-c:a', 'aac',
                '-movflags', '+faststart', str(out / 'home_video.mp4')], check=True)
subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(source), '-vn',
                '-t', str(DURATION), '-af', f'afade=t=out:st={DURATION - 0.1}:d=0.1', '-c:a', 'libvorbis', '-q:a', '3', str(out / 'home_audio.ogg')], check=True)
with tempfile.TemporaryDirectory() as temporary:
    folder = pathlib.Path(temporary)
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(out / 'home_video.mp4'),
                    '-vf', f'fps={FPS},scale=384:288', '-q:v', '5',
                    str(folder / 'f%04d.jpg')], check=True)
    frames = [p.read_bytes() for p in sorted(folder.glob('f*.jpg'))]
    header = f'XHVP1 {len(frames)} {FPS}\n' + ' '.join(str(len(b)) for b in frames) + '\n'
    with (out / 'home_video.pack').open('wb') as pack:
        pack.write(header.encode())
        for frame in frames:
            pack.write(frame)
print(f'Built {len(frames)} frames at {FPS} fps ({len(frames) / FPS:.2f}s).')
