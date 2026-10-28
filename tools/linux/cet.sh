#!/usr/bin/env bash
# Runs Lua inside the running game through the AOHarness CET mod and prints the result.
#   tools/linux/cet.sh 'return Game.GetPlayer() ~= nil'
#   tools/linux/cet.sh -f snippet.lua [-t 30]
# Only answers while the game window is updating (not paused, not on a loading screen).
set -euo pipefail
source "$(dirname "$0")/common.sh"

timeout_sec=15
code=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) code="$(cat "$2")"; shift 2 ;;
    -t) timeout_sec="$2"; shift 2 ;;
    *) code="$1"; shift ;;
  esac
done
[[ -n "$code" ]] || { echo "no code given" >&2; exit 2; }
game_running || { echo "game is not running" >&2; exit 1; }

id="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"
out="$HARNESS_DIR/out.log"
offset=0
[[ -f "$out" ]] && offset=$(stat -c %s "$out")
printf -- '-- id: %s\n%s\n' "$id" "$code" > "$HARNESS_DIR/cmd.lua"

deadline=$(( $(date +%s) + timeout_sec ))
while (( $(date +%s) < deadline )); do
  if [[ -f "$out" ]] && (( $(stat -c %s "$out") > offset )); then
    # The harness runs on Windows, so its lines end in \r\n.
    body="$(tail -c +$((offset + 1)) "$out" | tr -d '\r' | sed -n "/^@@begin $id\$/,/^@@end $id\$/p")"
    if grep -q "^@@end $id\$" <<<"$body"; then
      sed '1d;$d' <<<"$body"
      exit 0
    fi
  fi
  sleep 0.25
done
echo "no response within ${timeout_sec}s (game paused/unfocused, still loading, or harness not installed?)" >&2
exit 1
