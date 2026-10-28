#!/usr/bin/env bash
# Downloads the CC0 texture sets (ambientCG) and studio HDRI (Poly Haven) the icon renders use,
# into ~/.cache/ammo-overhaul/assets. Safe to re-run: skips what is already there.
set -euo pipefail
A="${AO_ASSETS:-$HOME/.cache/ammo-overhaul/assets}"
mkdir -p "$A"
for id in Metal009 Metal011 PaintedMetal004 Plastic006 Cardboard004; do
  [ -d "$A/$id" ] && continue
  curl -sfL -o "$A/$id.zip" "https://ambientcg.com/get?file=${id}_2K-JPG.zip"
  mkdir -p "$A/$id" && (cd "$A/$id" && unzip -q ../$id.zip) && rm "$A/$id.zip"
done
hdri=photo_studio_01
if [ ! -f "$A/$hdri.hdr" ]; then
  url=$(curl -sf "https://api.polyhaven.com/files/$hdri" | python3 -c "import json,sys; print(json.load(sys.stdin)['hdri']['2k']['hdr']['url'])")
  curl -sfL -o "$A/$hdri.hdr" "$url"
fi
ls "$A"
