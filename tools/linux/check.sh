#!/usr/bin/env bash
# Offline compile check: compiles src/scripts plus the framework scripts against the vanilla
# 2.50 bundle with redscript-cli on GE-Proton, in its own prefix (never the game's).
# Needs tools/redscript-cli.exe and reference/final.redscripts.vanilla (see HANDOFF.md).
set -euo pipefail
source "$(dirname "$0")/common.sh"

bundle="$ROOT/reference/final.redscripts.vanilla"
cli="$ROOT/tools/redscript-cli.exe"
[[ -f "$bundle" && -f "$cli" ]] || { echo "missing $bundle or $cli" >&2; exit 2; }
out="$(mktemp --suffix=.redscripts)"
trap 'rm -f "$out"' EXIT

args=(compile -b "Z:$bundle" -o "Z:$out" -s "Z:$ROOT/src/scripts")
for plugin in TweakXL ArchiveXL Codeware; do
  dir="$GAME_DIR/red4ext/plugins/$plugin/Scripts"
  [[ -d "$dir" ]] && args+=(-s "Z:$dir")
done
mkdir -p "$TOOLS_PREFIX"
# redscript-cli exits 0 even when the build fails, so judge by its output.
log="$(proton_wine "$cli" "${args[@]}")"
echo "$log"
! grep -q 'Build failed' <<<"$log"
