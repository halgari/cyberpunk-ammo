#!/usr/bin/env bash
# Extracts the game's gang and corp decals the faction forms print with, into
# ~/.cache/ammo-overhaul/assets/faction as PNGs. They're the game's, so they stay out of the repo.
# Needs the game installed, not running. Safe to re-run: skips what is already there.
set -euo pipefail
source "$(dirname "$0")/../linux/common.sh"
A="${AO_ASSETS:-$HOME/.cache/ammo-overhaul/assets}/faction"
[ -f "$A/w_kangtao_decal_d01.png" ] && { ls "$A"; exit 0; }
raw="$(mktemp -d)"; trap 'rm -rf "$raw"' EXIT
mkdir -p "$A"
"$ROOT/tools/linux/wolvenkit.sh" unbundle "Z:$GAME_DIR/archive/pc/content/basegame_3_nightcity.archive" -o "Z:$raw" \
  -r '(?i)(maelstrom_logo_a_01_m|maelstrom_skull_03_m|maelstrom_skull_19_m|corpo_arasaka_decal_b_m|w_arasaka_decal_01_d01|6th_street_a_graffiti_i_m|animals_dec_v0[156]|animals_dec_v11|militech_logo_[ab]_m|w_militech_decal_d01|aldecaldos_[abj]|voodoo_boys_dec_v[257]|w_kangtao_decal_d01)\.xbm$'
"$ROOT/tools/linux/wolvenkit.sh" unbundle "Z:$GAME_DIR/archive/pc/content/basegame_4_gamedata.archive" -o "Z:$raw" \
  -r '(?i)(graffiti.tyger_claws.tyger_claws|valentinos_dec_v05|valentinos_dec_v29_m|w_gangs_valentinos_d01|6th_street_a_graffiti_m_m|animals_dec_v0[156]|animals_dec_v11|militech_logo_[ab]_m|w_militech_decal_d01|aldecaldos_[abj]|voodoo_boys_dec_v[257]|w_kangtao_decal_d01)\.xbm$'
find "$raw" -name '*.xbm' | while read -r f; do
  "$ROOT/tools/linux/wolvenkit.sh" export "Z:$f" -o "Z:$A" --uext png --gamepath "Z:$GAME_DIR"
done
ls "$A"
