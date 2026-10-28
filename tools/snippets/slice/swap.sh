#!/usr/bin/env bash
# Fits 5mm Sleevers to a freshly drawn Omaha and checks the gun takes them without a
# "couldn't give" line (a second apply for the same draw used to fail once the first had already
# written the field). Run right after a restart: the field offset isn't located yet then.
# Draws a weapon: only when the user isn't playing.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets
$C "GUN='Items.Preset_Omaha_Default'; $(cat $S/feed-kit.lua)" | grep -q "gave the slice kit" && sleep 1 &&
  $C "GUN='Items.Preset_Omaha_Default'; $(cat $S/feed-kit.lua)" >/dev/null
sleep 6
$C "FEED='Items.AO_Feed_5mm_RailSlugs'; $(cat $S/set-feed.lua)" >/dev/null; sleep 5
$C "FEED='Items.AO_Feed_5mm_Sleevers'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
$C -t 20 "$(cat $S/slice/common.lua)"'
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local w = Game.GetPlayer():GetActiveWeapon()
check("Omaha in hand", w ~= nil, "no gun")
if w then check("Omaha loads Sleevers", str(Game["AO_ReadAmmoField"](w, 740)) == "Ammo.AO_TLight_Sabot", str(Game["AO_ReadAmmoField"](w, 740))) end
local bad = {}
for line in sys:Trail():gmatch("[^\n]+") do if line:find("couldn.t give") then table.insert(bad, line) end end
check("no couldn'"'"'t-give line", #bad == 0, table.concat(bad, " | "))
report()'
