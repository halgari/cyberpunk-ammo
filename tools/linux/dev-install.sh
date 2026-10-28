#!/usr/bin/env bash
# Installs (or with --remove, removes) the dev-only helpers: intro skip + autoload of the test
# save (r6/scripts/AODev) and the AOHarness CET console. Linux equivalent of dev-install.ps1;
# the Lutris launch already passes -skipStartScreen and bypasses REDlauncher, so no shortcut.
set -euo pipefail
source "$(dirname "$0")/common.sh"

if [[ "${1:-}" == "--remove" ]]; then
  rm -rf "$GAME_DIR/r6/scripts/AODev" "$HARNESS_DIR"
  echo "dev helpers removed"
  exit 0
fi

mkdir -p "$GAME_DIR/r6/scripts/AODev" "$HARNESS_DIR"
cp "$ROOT"/tools/dev-scripts/*.reds "$GAME_DIR/r6/scripts/AODev/"
# A loose copy of the same intro-skip mod would add the same method twice.
rm -f "$GAME_DIR/r6/scripts/NoIntroVideos.reds"
cp "$ROOT/tools/harness/init.lua" "$HARNESS_DIR/"
echo "installed dev helpers"
