#!/usr/bin/env bash
# Builds the release zip, dist/BrassMarket-<version>.zip, laid out relative to the game root so
# it extracts into any Cyberpunk 2077 install or a mod manager. The version comes from VERSION.
#   - compiles the scripts (check.sh) and rebuilds the native plugin from source;
#   - leaves out the test data (test.yaml: test NPCs, presets and rounds; never shipped);
#   - stamps the version into the tweaks (AmmoOverhaul.version), for bug reports;
#   - checks the zip: every file it must hold, nothing from the test data.
# Doesn't touch the game. docs/RELEASING.md has the whole release flow.
set -euo pipefail
source "$(dirname "$0")/common.sh"

version="$(tr -d '[:space:]' < "$ROOT/VERSION")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || { echo "VERSION '$version' isn't x.y.z" >&2; exit 1; }
dist="$ROOT/dist"
stage="$dist/stage"
zip="$dist/BrassMarket-$version.zip"
mkdir -p "$dist"

"$(dirname "$0")/check.sh" > "$dist/package-check.log" 2>&1 || {
  grep -E "ERROR|Build failed" -A3 "$dist/package-check.log" >&2; echo "compile check failed" >&2; exit 1; }
"$(dirname "$0")/build-native.sh" AmmoOverhaul > "$dist/package-native.log" 2>&1 || {
  tail -20 "$dist/package-native.log" >&2; echo "native build failed" >&2; exit 1; }

rm -rf "$stage" "$zip"
mkdir -p "$stage/r6/scripts" "$stage/r6/tweaks/AmmoOverhaul" "$stage/archive/pc/mod" "$stage/red4ext/plugins/AmmoOverhaul"
cp -r "$ROOT/src/scripts/AmmoOverhaul" "$stage/r6/scripts/"
for f in "$ROOT"/src/tweaks/AmmoOverhaul/*.yaml; do
  [[ "$(basename "$f")" == test.yaml ]] || cp "$f" "$stage/r6/tweaks/AmmoOverhaul/"
done
printf '# Written by tools/linux/package.sh.\nAmmoOverhaul.version: "%s"\n' "$version" > "$stage/r6/tweaks/AmmoOverhaul/version.yaml"
cp "$ROOT"/src/archive/*.archive "$stage/archive/pc/mod/"
cp "$ROOT/build/native/AmmoOverhaul.dll" "$stage/red4ext/plugins/AmmoOverhaul/"
# Beside the plugin, not at the zip's root: the zip extracts into the game folder.
cp "$ROOT/LICENSE" "$stage/red4ext/plugins/AmmoOverhaul/"

(cd "$stage" && zip -qr -X "$zip" r6 archive red4ext)

# The zip must hold every shipped source file and nothing of the test data.
listing="$(unzip -Z1 "$zip")"
fail=0
need() { grep -qxF "$1" <<<"$listing" || { echo "missing from zip: $1" >&2; fail=1; }; }
for f in "$ROOT"/src/scripts/AmmoOverhaul/*.reds; do need "r6/scripts/AmmoOverhaul/$(basename "$f")"; done
for f in "$ROOT"/src/tweaks/AmmoOverhaul/*.yaml; do
  [[ "$(basename "$f")" == test.yaml ]] || need "r6/tweaks/AmmoOverhaul/$(basename "$f")"
done
need r6/tweaks/AmmoOverhaul/version.yaml
need archive/pc/mod/AmmoOverhaul.archive
need red4ext/plugins/AmmoOverhaul/AmmoOverhaul.dll
need red4ext/plugins/AmmoOverhaul/LICENSE
grep -q "test.yaml" <<<"$listing" && { echo "test.yaml is in the zip" >&2; fail=1; }
if grep -rl "AO_Test" "$stage/r6/tweaks" >/dev/null; then echo "test records in the shipped tweaks" >&2; fail=1; fi
(( fail == 0 )) || { rm -f "$zip"; exit 1; }

(cd "$dist" && sha256sum "$(basename "$zip")" > "$(basename "$zip").sha256")
echo "built $zip ($(wc -l <<<"$listing") files, $(du -h "$zip" | cut -f1))"
