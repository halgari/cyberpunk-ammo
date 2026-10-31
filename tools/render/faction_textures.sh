#!/usr/bin/env bash
# Extracts the game's Maelstrom and Arasaka decals the faction forms print with, into
# ~/.cache/ammo-overhaul/assets/faction as PNGs. They're the game's, so they stay out of the repo.
# Needs the game installed, not running. Safe to re-run: skips what is already there.
set -euo pipefail
source "$(dirname "$0")/../linux/common.sh"
A="${AO_ASSETS:-$HOME/.cache/ammo-overhaul/assets}/faction"
[ -f "$A/w_arasaka_decal_01_d01.png" ] && { ls "$A"; exit 0; }
raw="$(mktemp -d)"; trap 'rm -rf "$raw"' EXIT
mkdir -p "$A"
"$ROOT/tools/linux/wolvenkit.sh" unbundle "Z:$GAME_DIR/archive/pc/content/basegame_3_nightcity.archive" -o "Z:$raw" \
  -r '(?i)(maelstrom_logo_a_01_m|maelstrom_skull_03_m|maelstrom_skull_19_m|corpo_arasaka_decal_b_m|w_arasaka_decal_01_d01)\.xbm$'
find "$raw" -name '*.xbm' | while read -r f; do
  "$ROOT/tools/linux/wolvenkit.sh" export "Z:$f" -o "Z:$A" --uext png --gamepath "Z:$GAME_DIR"
done
ls "$A"
