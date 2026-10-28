#!/usr/bin/env bash
# Builds src/archive/AmmoOverhaul.archive (the ammo icon atlas, committed so deploying and
# packaging don't need WolvenKit) from art/icons:
#   1. make_icons.py: the atlas png and its part UVs;
#   2. WolvenKit (Windows build on Proton, tools/linux/wolvenkit.sh) imports the png into an
#      .xbm, keeping the texture settings of a vanilla icon atlas used as the template;
#   3. make_inkatlas.py writes the .inkatlas from the vanilla atlas json; WolvenKit turns it into
#      CR2W and packs both files.
# The vanilla template comes from the game's archives (extracted once into build/icons/vanilla
# with the Linux WolvenKit build, which can't convert textures but can extract).
set -euo pipefail
cd "$(dirname "$0")/../.."
source tools/linux/common.sh
WKL="dotnet tools/wolvenkit/WolvenKit.CLI.dll"
B="$ROOT/build/icons"
DEPOT='ammooverhaul\icons'
VAN="$B/vanilla/base/gameplay/gui/common/icons/items"

python3 tools/icons/make_icons.py
if [[ ! -f "$VAN/item_icons5.inkatlas" ]]; then
  mkdir -p "$B/vanilla"
  $WKL extract "$GAME_DIR/archive/pc/content" -o "$B/vanilla" -r 'item_icons5\.(inkatlas|xbm)$' >/dev/null
fi
rm -rf "$B/raw" "$B/pack" "$B/json"
mkdir -p "$B/raw/ammooverhaul/icons" "$B/pack/ammooverhaul/icons" "$B/json"
cp art/build/ao_ammo_icons.png "$B/raw/ammooverhaul/icons/"
cp "$VAN/item_icons5.xbm" "$B/pack/ammooverhaul/icons/ao_ammo_icons.xbm"
tools/linux/wolvenkit.sh import "Z:$B/raw" -k -o "Z:$B/pack" | grep -E "Imported|rror" || true

$WKL convert serialize "$VAN/item_icons5.inkatlas" -o "$B/json" >/dev/null
python3 tools/icons/make_inkatlas.py "$B/json/item_icons5.inkatlas.json" art/build/ao_ammo_icons.uvs.json \
  "$DEPOT\\ao_ammo_icons.xbm" "$B/json/ao_ammo_icons.inkatlas.json"
$WKL convert deserialize "$B/json/ao_ammo_icons.inkatlas.json" -o "$B/pack/ammooverhaul/icons" >/dev/null
ls "$B/pack/ammooverhaul/icons"

rm -rf "$B/out"; mkdir -p "$B/out" src/archive
tools/linux/wolvenkit.sh pack "Z:$B/pack" -o "Z:$B/out" | grep -E "rror" || true
mv -f "$B/out/pack.archive" src/archive/AmmoOverhaul.archive
ls -la src/archive
