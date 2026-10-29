#!/usr/bin/env bash
# Runs a command while holding the one-game lock, so parallel workers (several git worktrees) take
# turns at compiling, deploying, restarting and testing in the single game install.
#   tools/linux/game-lock.sh bash -c 'tools/linux/restart-game.sh --kill; tools/linux/deploy.sh && ...'
# Run it from the checkout whose code should be built: the scripts use their own checkout's src.
set -uo pipefail
lock="${TMPDIR:-/tmp}/ammo-overhaul-game.lock"
exec 9>"$lock"
if ! flock -n 9; then
  echo "waiting for game lock" >&2
  flock 9
fi
"$@"
