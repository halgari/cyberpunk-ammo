#!/usr/bin/env bash
# Kills Cyberpunk 2077 (if running), relaunches it through Lutris and waits until the dev
# autoload has put us in a save and the harness answers.
#   tools/linux/restart-game.sh [--no-wait] [--kill]   (--kill: just stop the game)
set -euo pipefail
source "$(dirname "$0")/common.sh"

if game_running; then
  pkill -f "$GAME_PROCESS" || true
  for _ in $(seq 60); do game_running || break; sleep 0.5; done
  game_running && { echo "game still running after kill" >&2; exit 1; }
  echo "game stopped"
fi
[[ "${1:-}" == "--kill" ]] && exit 0

# `lutris lutris:rungameid/N` stops the game when Lutris exits, and with no window open it exits
# within seconds. So run Lutris's own exported launch script (`lutris -b cyberpunk-2077`, saved
# as launch-lutris.sh), detached. That script leaves out PROTONPATH, which Lutris only sets at
# launch; without it umu-run would pick its default Proton instead of the game's GE-Proton.
# GAMEID gives the window the class steam_app_1091500 (the Hyprland rule matches it) and turns
# on umu's Cyberpunk protonfixes.
launcher="$(dirname "$0")/launch-lutris.sh"
[[ -f "$launcher" ]] || { echo "missing $launcher: run 'lutris -b cyberpunk-2077' in tools/linux and rename it" >&2; exit 2; }
PROTONPATH="$PROTON" GAMEID="${GAMEID:-umu-1091500}" STORE="${STORE:-gog}" setsid -f bash "$launcher" >"${TMPDIR:-/tmp}/ammo-overhaul-game.log" 2>&1
echo "game launching"
[[ "${1:-}" == "--no-wait" ]] && exit 0

deadline=$(( $(date +%s) + 300 ))
while (( $(date +%s) < deadline )); do
  sleep 5
  game_running || continue
  # The main menu has a player puppet too; only a loaded save is out of pre-game.
  if r="$("$(dirname "$0")/cet.sh" -t 5 'return tostring(Game.GetSystemRequestsHandler():IsPreGame()) .. " " .. tostring(Game.GetPlayer() ~= nil)' 2>/dev/null)" \
     && [[ "$r" == *"=> false true"* ]]; then
    # Scriptable systems get OnPlayerAttach a few seconds after pre-game ends.
    sleep 15
    echo "in game"
    exit 0
  fi
done
echo "game not in a save after 300 s" >&2
exit 1
