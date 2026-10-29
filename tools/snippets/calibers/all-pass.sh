#!/usr/bin/env bash
# Runs each test command given and fails if any exits non-zero or prints a FAIL line; prints each
# command's last summary line. Some older drivers (slice/uncommon.sh) exit 0 on FAIL.
#   tools/snippets/calibers/all-pass.sh "tools/snippets/calibers/check.sh calibers/records.lua" ...
# A watchdog stops the run (exit 2) when the game freezes (no harness heartbeat for FROZEN_AFTER s,
# default 30, as cet.sh) or exits mid-step, saving a screenshot to FROZEN_SHOT; a step running longer than
# STEP_TIMEOUT s (default 900) is killed and fails.
cd "$(dirname "$0")/../../.."
source tools/linux/common.sh
FROZEN_SHOT="${FROZEN_SHOT:-${TMPDIR:-/tmp}/ammo-overhaul-frozen.png}"
status=0
for c in "$@"; do
  out_file="$(mktemp)"; ran_game=0; game_running && ran_game=1
  setsid bash -c "$c" >"$out_file" 2>&1 &
  pid=$!; start=$(date +%s); why=""
  while kill -0 "$pid" 2>/dev/null; do
    sleep 2
    if (( ran_game )) && ! game_running; then why="game exited"
    elif game_frozen "${FROZEN_AFTER:-30}"; then why="game frozen (no frame for $(heartbeat_age) s)"
    elif (( $(date +%s) - start > ${STEP_TIMEOUT:-900} )); then why="step timed out after ${STEP_TIMEOUT:-900} s"
    fi
    [[ -n "$why" ]] && { kill -- -"$pid" 2>/dev/null; break; }
  done
  wait "$pid" 2>/dev/null; rc=$?
  # cet.sh gives up on a frozen game by itself, so the step can end before the loop sees it.
  [[ -z "$why" ]] && game_frozen "${FROZEN_AFTER:-30}" && why="game frozen (no frame for $(heartbeat_age) s)"
  out="$(cat "$out_file")"; rm -f "$out_file"
  fails=$(grep -c '^FAIL' <<<"$out"); passes=$(grep -c '^PASS' <<<"$out")
  echo "$c: $passes pass, $fails fail (exit $rc)"
  grep '^FAIL' <<<"$out" | head -5
  if [[ -n "$why" ]]; then
    echo "FAIL $why during: $c"
    [[ "$why" == game\ frozen* ]] && tools/linux/game-shot.sh "$FROZEN_SHOT" >/dev/null 2>&1 && echo "screenshot: $FROZEN_SHOT"
    [[ "$why" == step\ timed* ]] || { echo "remaining steps skipped"; exit 2; }
  fi
  (( rc != 0 || fails > 0 || passes == 0 )) && status=1
done
exit $status
