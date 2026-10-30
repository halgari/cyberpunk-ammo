#!/usr/bin/env bash
# Ping and the cover-piercing Penetrator on live hits (hit rig, rig.lua):
#   - V's 7.62 Ping hits on a frozen ganger tag it (AmmoOverhaul.PingTag), and the tag wears off
#     about 5 s (game time) after the last hit;
#   - a ganger firing 7.62 Ping at V tags V, and V's tag wears off the same way (nothing stuck);
#   - no new error in the redscript or CET log during the run;
#   - an NPC rolled to the 7.62 Penetrator (the NPC tier path, as npc.sh) has TechPierceEnabled 1
#     on its gun.
# Not checked here: shots through a car. NPCs only fire at what they can see, so the rig can't
# make one shoot through cover; the user's probe (Ajax, 2026-10-29) and the stat check cover it.
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
source tools/linux/common.sh
AJAX=Items.Preset_Ajax_Default
TAG=AmmoOverhaul.PingTag
RLOG="$GAME_DIR/r6/logs/redscript_rCURRENT.log"; CLOG="$GAME_DIR/bin/x64/plugins/cyber_engine_tweaks/scripting.log"
lines() { [[ -f "$1" ]] && wc -l <"$1" || echo 0; }
r0=$(lines "$RLOG"); c0=$(lines "$CLOG")
# As hitdata.sh: V's Invulnerable (test kit) blocks debuffs, so it's lifted for the NPC phase.
vulnerable() { $C 'local k, gm, p = GetMod("AOTestKit"), Game.GetGodModeSystem(), Game.GetPlayer():GetEntityID()
if AO_KITGOD == nil then AO_KITGOD = k.state.godMode end
k.state.godMode = false
for _, s in ipairs({"AO_TestKit", "AO_Test"}) do gm:RemoveGodMode(p, gameGodModeType.Invulnerable, CName.new(s)) end return 1' >/dev/null; }
kitgod() { $C 'local k = GetMod("AOTestKit")
if AO_KITGOD ~= nil then k.state.godMode = AO_KITGOD; AO_KITGOD = nil end
if k.state.godMode then Game.GetGodModeSystem():AddGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_TestKit")) end return 1' >/dev/null; }
trap 'kitgod; restore' EXIT
# Whether $1 ("V" or "NPC", the rig's NPC) has the tag now. The tag isn't readable in the frame
# it's applied, so callers read it at least a frame after the hit.
tagged() {
  lua "local o = '$1' == 'V' and Game.GetPlayer() or RIG.npc()
return o and StatusEffectSystem.ObjectHasStatusEffect(o, TweakDBID.new('$TAG')) and 'yes' or 'no'"
}
# Game seconds from the last hit on $1 ("V" or "NPC") until its tag is gone, polled (a CET round
# trip is about a second, so the reading runs up to a second late); "stuck" after 25 s.
wearoff() {
  for _ in $(seq 60); do
    r=$(lua "local last = 0
for _, h in ipairs(RIG.hits) do
  if not h.dot and (('$1' == 'NPC' and h.byV and h.onNpc) or ('$1' == 'V' and not h.byV and h.onV)) then last = math.max(last, h.t) end
end
local o = '$1' == 'V' and Game.GetPlayer() or RIG.npc()
local on = o and StatusEffectSystem.ObjectHasStatusEffect(o, TweakDBID.new('$TAG'))
return string.format('%.1f %s', EngineTime.ToFloat(Game.GetSimTime()) - last, on and 'on' or 'off')")
    [[ $r == *off ]] && { echo "${r% off}"; return; }
    [[ ${r%%.*} =~ ^[0-9]+$ ]] && (( ${r%%.*} >= 25 )) && { echo stuck; return; }
    sleep 0.3
  done
  echo stuck
}
# The tag wears off 5 s after the last hit (read up to a second late).
fivesec() { [[ $1 != stuck ]] && awk -v t="$1" 'BEGIN { exit !(t >= 4.5 && t <= 6.5) }'; }

# V on a ganger, with 7.62 Ping in an Ajax.
$C "Game.AddToInventory('$AJAX', 1); Game.AddToInventory('Items.AO_Feed_762_Ping', 1); Game.AddToInventory('Ammo.AO_762_Ping', 300)" >/dev/null
sleep 1; draw $AJAX; draw $AJAX; feed Items.AO_Feed_762_Ping
spawn 0.0 "" Character.AO_Test_Plain_Lexington
# Immortal, not Invulnerable: vanilla gives an Invulnerable target no debuffs.
lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
setup $AJAX
loaded=$($C 'return Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):DebugLoadedAmmo(Game.GetPlayer())' | sed -n 's/^=> //p')
[[ $loaded == Ammo.AO_762_Ping ]] || out+="FAIL V loads $loaded, not 7.62 Ping|"
shoot $AJAX 3
sleep 0.5
hits=$(lua "return #RIG.ratios('V')")
out+="$([[ $(tagged NPC) == yes && $hits -ge 1 ]] && echo PASS || echo FAIL) V's 7.62 Ping hits ($hits) tag the ganger|"
out+="$(lua "return RIG.effects('NPC', '$TAG') > 0 and 'PASS the tag was applied to the ganger' or 'FAIL the tag was never applied to the ganger'")|"
# The frozen NPC's time is dilated (it would slow its effects' timers too): let it loose for the wait.
lua "RIG.letNpcShoot(); return 1" >/dev/null
t=$(wearoff NPC)
lua "if RIG.npc() then RIG.freeze() end; return 1" >/dev/null
out+="$(fivesec "$t" && echo PASS || echo FAIL) the ganger's tag wears off about 5 s after the last hit ($t s)|"

# A ganger firing 7.62 Ping at V: an NPC rolled to Rare until it carries Ping (NPC tier path).
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
lua "RIG.npcMode = nil; return 1" >/dev/null
vulnerable
pinger() { [[ $(lua "local n = RIG.npc(); return n and TDBID.ToStringDEBUG(n:GetRecordID()) or ''") == Character.AO_Test_Plain_Ajax ]] \
  && [[ $($C -t 10 'local n = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
return n and Game.GetTransactionSystem():GetItemQuantity(n, ItemID.CreateQuery(TweakDBID.new("Ammo.AO_762_Ping"))) > 0' 2>/dev/null) == "=> true" ]]; }
got=0
for _ in 1 2 3; do
  if AO_TIER=2 AO_TRIES=30 spawn 100.0 Ammo.AO_762_Ping Character.AO_Test_Plain_Ajax && setup && pinger; then
    vulnerable
    npcshoot 3
    pinger && { got=1; break; }
  fi
done
if (( got )); then
  n=$(lua "return #RIG.ratios('NPC')")
  out+="$(lua "return RIG.effects('V', '$TAG') > 0 and 'PASS NPC 7.62 Ping hits ($n) tag V' or 'FAIL NPC 7.62 Ping hits ($n) never tagged V'")|"
  t=$(wearoff V)
  out+="$(fivesec "$t" && echo PASS || echo FAIL) V's tag wears off about 5 s after the last NPC hit ($t s)|"
else
  out+="FAIL no Ajax ganger with 7.62 Ping shot V|"
fi
kitgod

# An NPC rolled to Epic until it carries the 7.62 Penetrator: its gun has the pierce stats.
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
if AO_TIER=3 AO_TRIES=30 spawn 100.0 Ammo.AO_762_Penetrator Character.AO_Test_Plain_Ajax; then
  pierce=""
  for _ in $(seq 10); do
    pierce=$($C -t 10 'local n = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
local w = n and ScriptedPuppet.GetActiveWeapon(n)
if not w then return "no gun" end
local s = Game.GetStatsSystem(); local o = w:GetItemData():GetStatsObjectID()
return string.format("%g/%g/%g", s:GetStatValue(o, gamedataStatType.TechPierceEnabled),
  s:GetStatValue(o, gamedataStatType.TechPierceChargeLevel), s:GetStatValue(o, gamedataStatType.TechPierceDamageFactor))' | sed -n 's/^=> //p')
    [[ $pierce == 1/* ]] && break; sleep 1
  done
  out+="$([[ $pierce == 1/0/* ]] && echo PASS || echo FAIL) the NPC's 7.62 Penetrator gun pierces (enabled/charge/factor $pierce)|"
fi

$C "FEED='Items.AO_Feed_762_Ball'; $(cat $S/set-feed.lua)" >/dev/null
lua "RIG.teardown(); return 1" >/dev/null
# No new script error during the run (redscript's log and CET's).
errs=$( { tail -n +$((r0 + 1)) "$RLOG" 2>/dev/null; tail -n +$((c0 + 1)) "$CLOG" 2>/dev/null; } | grep -i -E '\berror\b|exception|stack traceback' | head -5)
out+="$([[ -z $errs ]] && echo PASS || echo FAIL) no new script errors in the logs${errs:+: $(tr '\n' ' ' <<<"$errs")}|"
res=$(tr '|' '\n' <<<"$out" | sed '/^$/d'); echo "$res"
p=$(grep -c '^PASS' <<<"$res"); n=$(grep -c '^FAIL' <<<"$res")
EXPECT=7
(( p + n >= EXPECT )) || { echo "FAIL only $((p + n)) of $EXPECT checks reported"; n=$((n + 1)); }
echo "== ping: $p pass, $n fail"
(( n == 0 && p > 0 ))
