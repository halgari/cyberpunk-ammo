#!/usr/bin/env bash
# Copies the mod into the game, replacing its folders wholesale so deleted source files don't
# linger. Equivalent of `package.ps1 -Deploy` without the zip. Refuses to deploy scripts that
# don't compile (a failed compile in game disables every script mod); --no-check skips that.
set -euo pipefail
source "$(dirname "$0")/common.sh"

if [[ "${1:-}" != "--no-check" ]]; then
  if ! log="$("$(dirname "$0")/check.sh" 2>&1)"; then
    grep -E "ERROR|Build failed" -A3 <<<"$log" >&2
    echo "compile check failed, not deploying" >&2
    exit 1
  fi
fi

for pair in "src/scripts/AmmoOverhaul:r6/scripts/AmmoOverhaul" "src/tweaks/AmmoOverhaul:r6/tweaks/AmmoOverhaul"; do
  src="$ROOT/${pair%%:*}"
  dst="$GAME_DIR/${pair##*:}"
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -r "$src" "$dst"
  echo "deployed ${pair##*:}"
done
