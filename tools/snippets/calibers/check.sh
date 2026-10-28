#!/usr/bin/env bash
# Runs CET checks (each with slice/common.lua in front) and fails if any prints FAIL or nothing.
#   tools/snippets/calibers/check.sh calibers/profiles.lua slice/records.lua ...
# Lua globals go in PRE, e.g. PRE="LIVE=true;".
set -uo pipefail
cd "$(dirname "$0")/../../.."
S=tools/snippets; status=0
for f in "$@"; do
  out="$(tools/linux/cet.sh "${PRE:-} $(cat $S/slice/common.lua $S/$f)" 2>&1)"
  echo "$out"
  p=$(grep -c '^PASS' <<<"$out"); n=$(grep -c '^FAIL' <<<"$out")
  echo "== $f: $p pass, $n fail"
  (( n > 0 || p == 0 )) && status=1
done
exit $status
