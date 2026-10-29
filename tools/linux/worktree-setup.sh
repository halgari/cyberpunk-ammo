#!/usr/bin/env bash
# Links the git-ignored build inputs (vanilla script bundle, redscript-cli, WolvenKit, the Lutris
# launcher) from the main checkout into a git worktree, so its tools/linux scripts work there.
#   tools/linux/worktree-setup.sh /path/to/worktree
set -euo pipefail
main="$(cd "$(dirname "$0")/../.." && git -C . rev-parse --path-format=absolute --git-common-dir)"
main="$(dirname "$main")"
wt="$(cd "${1:?worktree path}" && pwd)"
for p in reference tools/redscript-cli.exe tools/wolvenkit tools/wolvenkit-win tools/linux/launch-lutris.sh; do
  [[ -e "$main/$p" && ! -e "$wt/$p" ]] && ln -s "$main/$p" "$wt/$p"
done
echo "linked build inputs into $wt"
