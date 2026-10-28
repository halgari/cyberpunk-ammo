#!/usr/bin/env bash
# Rig self-test with the game's own roll: 30 V shots at the frozen test NPC roll in 0.90..1.10,
# and NPC shots on V are seen. LO/HI override the expected V range (Task 5 runs it with the mod's).
# Draws a gun and spawns an NPC: not while the user plays. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets
LO=${LO:-0.90}; HI=${HI:-1.10}; NPC_ROLLS=${NPC_ROLLS:-false}
lua() { $C -t 30 "$(cat $S/calibers/rig.lua); $1" 2>&1 | sed -n 's/^=> //p' | tail -1; }
$C "GUN='Items.Preset_Lexington_Default'; $(cat $S/feed-kit.lua)" >/dev/null; sleep 2
$C "GUN='Items.Preset_Lexington_Default'; $(cat $S/feed-kit.lua)" >/dev/null; sleep 3
for _ in $(seq 10); do r=$(lua "return RIG.setup('Items.Preset_Lexington_Default')"); [[ $r == ready ]] && break; sleep 3; done
echo "setup: $r"
lua "RIG.clear(); return 'ok'" >/dev/null
for _ in $(seq 30); do lua "RIG.fireV(); return 1" >/dev/null; sleep 0.3; done
for _ in $(seq 10); do lua "RIG.fireNpc(); return 1" >/dev/null; sleep 0.3; done
sleep 1
out=$(lua "local v, n = RIG.ratios('V'), RIG.ratios('NPC')
local ok = #v >= 25 and v[1] >= $LO - 0.002 and v[#v] <= $HI + 0.002
local npcDiffer = false
for _, r in ipairs(n) do if math.abs(r - 1) > 0.001 then npcDiffer = true end end
return string.format('%s %d V hits %.3f..%.3f|%s %d NPC hits on V, rolled=%s', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0,
  (#n > 0 and npcDiffer == $NPC_ROLLS) and 'PASS' or 'FAIL', #n, tostring(npcDiffer))")
lua "RIG.teardown(); return 1" >/dev/null
tr '|' '\n' <<<"$out"
p=$(grep -c '^PASS' <<<"$(tr '|' '\n' <<<"$out")"); n=$(grep -c '^FAIL' <<<"$(tr '|' '\n' <<<"$out")")
echo "== rig: $p pass, $n fail"
(( n == 0 && p > 0 ))
