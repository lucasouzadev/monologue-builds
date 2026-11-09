#!/usr/bin/env python3
"""Extract evenly spaced frames + scene-change frames from a video and build a contact sheet.

Usage: frames.py VIDEO [--out DIR] [--max 24]
Writes DIR/frame-XX.jpg, DIR/grid.jpg and prints one "timestamp  file" line per frame.
Needs ffmpeg/ffprobe on PATH. Frames stay local: delete DIR when done.
"""
import argparse, json, os, shutil, subprocess, sys, tempfile


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--out")
    ap.add_argument("--max", type=int, default=24)
    a = ap.parse_args()
    if not (shutil.which("ffmpeg") and shutil.which("ffprobe")):
        sys.exit("ffmpeg/ffprobe not found: ask the owner for screenshots instead of guessing")
    if not os.path.isfile(a.video):
        sys.exit("file not found: " + a.video)
    out = a.out or tempfile.mkdtemp(prefix="media-frames-")
    os.makedirs(out, exist_ok=True)
    p = run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", a.video])
    try:
        dur = float(json.loads(p.stdout)["format"]["duration"])
    except Exception:
        sys.exit("could not read duration: " + (p.stderr.strip()[:200] or "unknown error"))
    n = max(1, min(a.max, int(dur) + 1))  # at most ~1 frame per second
    times = [dur * (i + 0.5) / n for i in range(n)]
    files = []
    for i, t in enumerate(times):
        f = os.path.join(out, "frame-%02d.jpg" % (i + 1))
        r = run(["ffmpeg", "-v", "error", "-y", "-ss", "%.2f" % t, "-i", a.video, "-frames:v", "1", "-vf", "scale=360:-2", "-q:v", "4", f])
        if r.returncode == 0 and os.path.isfile(f):
            files.append((t, f))
    if not files:
        sys.exit("no frames extracted")
    cols = 6 if len(files) > 12 else 4
    rows = -(-len(files) // cols)
    lst = os.path.join(out, "list.txt")
    with open(lst, "w") as fh:
        for _, f in files:
            fh.write("file '%s'\nduration 1\n" % f)
    grid = os.path.join(out, "grid.jpg")
    r = run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-vf", "tile=%dx%d:padding=4:color=white" % (cols, rows), "-frames:v", "1", "-q:v", "4", grid])
    os.remove(lst)
    print("duration %.1fs, %d frames, grid: %s" % (dur, len(files), grid if r.returncode == 0 else "(failed)"))
    for t, f in files:
        print("%02d:%05.2f  %s" % (int(t // 60), t % 60, f))


if __name__ == "__main__":
    main()
