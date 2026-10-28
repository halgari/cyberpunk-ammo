#!/usr/bin/env bash
# Screenshot of the game without touching the user's screen: the game window is kept on a
# headless Hyprland output (AO-CAP, workspace 8) that renders off screen, and grim captures it.
#   tools/linux/game-shot.sh out.png      # creates the output and moves the game there if needed
#   tools/linux/game-shot.sh --remove     # removes the output; the game goes back to a real monitor
set -euo pipefail
OUT=AO-CAP
if [[ "${1:-}" == --remove ]]; then hyprctl output remove $OUT >/dev/null; exit 0; fi
file=${1:?usage: game-shot.sh out.png}
if ! hyprctl monitors -j | grep -q "\"$OUT\""; then
  hyprctl output create headless $OUT >/dev/null; sleep 1
fi
ws=$(hyprctl monitors -j | python3 -c "import json,sys;print([m['activeWorkspace']['id'] for m in json.load(sys.stdin) if m['name']=='$OUT'][0])")
game=$(hyprctl clients -j | python3 -c "import json,sys;print(next((str(c['workspace']['id']) for c in json.load(sys.stdin) if c['class']=='steam_app_1091500'), ''))")
[[ -n "$game" ]] || { echo "game window not found" >&2; exit 1; }
if [[ "$game" != "$ws" ]]; then
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$ws\", follow = false, window = \"class:steam_app_1091500\" })" >/dev/null
  sleep 1
fi
grim -o $OUT "$file"
