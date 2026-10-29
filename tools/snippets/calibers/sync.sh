#!/usr/bin/env bash
# Selector sync (sync.lua): one CET call per state change, a pause between change and check.
# Gives and removes ammo, fits selectors on two fresh Lexingtons, equips one and opens its mod
# screen: only when the user isn't playing. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets; out=""
for step in $(seq 0 14); do
  out+="$($C -t 20 "STEP=$step; $(cat $S/slice/common.lua $S/calibers/sync.lua)" 2>&1)"$'\n'
  # Fits and the menu take longer than a give.
  case $step in 5|6|8|11) sleep 4 ;; 12) sleep 6 ;; *) sleep 2 ;; esac
done
echo "$out"
p=$(grep -c '^PASS' <<<"$out"); n=$(grep -c '^FAIL\|error' <<<"$out")
echo "== sync: $p pass, $n fail"
(( n == 0 && p > 0 ))
