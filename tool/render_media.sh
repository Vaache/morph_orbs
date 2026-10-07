#!/usr/bin/env bash
# Renders the README media: frames via the media test, then GIF + MP4 via
# ffmpeg and labelled PNG grids via tool/label_grid.py. Output: doc/media/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAMES="${TMPDIR:-/tmp}/morph_orbs_frames"
OUT="$ROOT/doc/media"
FPS=24

rm -rf "$FRAMES"
mkdir -p "$FRAMES" "$OUT"

(cd "$ROOT" && ORB_MEDIA_DIR="$FRAMES" flutter test test/media)

gif() {
  local name="$1" scale="$2" fps="${3:-$FPS}"
  ffmpeg -y -loglevel error -framerate "$FPS" -i "$FRAMES/$name/%04d.png" \
    -vf "fps=$fps,scale=$scale:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=96:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
    -loop 0 "$OUT/$name.gif"
  ffmpeg -y -loglevel error -framerate "$FPS" -i "$FRAMES/$name/%04d.png" \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p -crf 20 \
    "$OUT/$name.mp4"
}

gif flow 320
gif failstop 320
gif morphs 320
gif variants 720 12
gif states 840 12

python3 "$ROOT/tool/label_grid.py" \
  "$FRAMES/variants/0096.png" "$OUT/variants.png" 6 300 \
  orbits ring ribbon rubik globe wave web braid morph pulse swarm helix nebula vortex echo constellate bloom
python3 "$ROOT/tool/label_grid.py" \
  "$FRAMES/states/0090.png" "$OUT/states.png" 7 300 \
  idle thinking processing generating success error stopped

du -sh "$OUT"/*
