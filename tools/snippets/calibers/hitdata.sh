#!/usr/bin/env bash
# Per-round hit data on live hits (hit rig, rig.lua), with Ammo.AO_Test_HitData (test.yaml: burns
# every hit, half of Physical as Thermal, x2 against machines, non-lethal), fed by its selector,
# which is added to the 9mm lists for the run:
#   - V's hits on a ganger: half Thermal, the ganger burns, the roll is untouched (0.90..1.01);
#   - a ganger firing it at V: half Thermal, V burns;
#   - V's hits on an android: x2 (1.80..2.02);
#   - V's killing shot on a ganger knocks it out instead.
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
LEX=Items.Preset_Lexington_Default
L='local K = "AmmoOverhaul.Power_9mm."
local function add(f, v) local a = TweakDB:GetFlat(K .. f); table.insert(a, v); TweakDB:SetFlat(K .. f, a) end'
$C "$L"'
AO_HD_SAVED = AO_HD_SAVED or { s = TweakDB:GetFlat(K .. "selectors"), a = TweakDB:GetFlat(K .. "selectorAmmo"), t = TweakDB:GetFlat(K .. "selectorTiers") }
add("selectors", "Items.AO_Feed_Test_HitData"); add("selectorAmmo", "Ammo.AO_Test_HitData"); add("selectorTiers", 9)' >/dev/null
unlists() { $C 'local K = "AmmoOverhaul.Power_9mm."
if AO_HD_SAVED then TweakDB:SetFlat(K .. "selectors", AO_HD_SAVED.s); TweakDB:SetFlat(K .. "selectorAmmo", AO_HD_SAVED.a); TweakDB:SetFlat(K .. "selectorTiers", AO_HD_SAVED.t); AO_HD_SAVED = nil end' >/dev/null; }
trap 'unlists; kitgod; $C "TweakDB:SetFlat(\"Ammo.AO_Test_HitData.aoEffectChances\", {1.0}) return 1" >/dev/null; restore' EXIT
burned() { # target ("V" or "NPC") name shooter [effect]: hits landed and the target was set on fire
  lua "local n, b = #RIG.ratios('$3'), RIG.effects('$1', '${4:-BaseStatusEffect.Burning}')
return string.format('%s $2 hits (%d) set the target on fire (%d times)', (n >= 5 and b > 0) and 'PASS' or 'FAIL', n, b)"
}
# V's Invulnerable (test kit, npc.sh) blocks debuffs: lifted for the NPC phase (the rig keeps V
# Immortal). The kit turns it back on with every spawn, so its setting is off for the phase.
vulnerable() { $C 'local k, gm, p = GetMod("AOTestKit"), Game.GetGodModeSystem(), Game.GetPlayer():GetEntityID()
if AO_KITGOD == nil then AO_KITGOD = k.state.godMode end
k.state.godMode = false
for _, s in ipairs({"AO_TestKit", "AO_Test"}) do gm:RemoveGodMode(p, gameGodModeType.Invulnerable, CName.new(s)) end return 1' >/dev/null; }
kitgod() { $C 'local k = GetMod("AOTestKit")
if AO_KITGOD ~= nil then k.state.godMode = AO_KITGOD; AO_KITGOD = nil end
if k.state.godMode then Game.GetGodModeSystem():AddGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_TestKit")) end return 1' >/dev/null; }
shares() { # who name
  lua "local v = RIG.thermal('$1')
local ok = #v >= 5 and v[1] >= 0.48 and v[#v] <= 0.52
return string.format('%s %d $2 hits deal half as Thermal (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0)"
}

# V on a ganger.
$C "Game.AddToInventory('$LEX', 1); Game.AddToInventory('Items.AO_Feed_Test_HitData', 1); Game.AddToInventory('Ammo.AO_Test_HitData', 300)" >/dev/null
sleep 1; draw $LEX; draw $LEX; feed Items.AO_Feed_Test_HitData
spawn 0.0 "" Character.AO_Test_Plain_Lexington
# Immortal, not Invulnerable: vanilla gives an Invulnerable target no debuffs.
lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
setup $LEX
shoot $LEX 10
out+="$(shares V 'V test round')|"
out+="$(lua "local v = RIG.ratios('V')
local ok = #v >= 5 and v[1] >= 0.898 and v[#v] <= 1.012
return string.format('%s %d V test round hits on a human roll plainly (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0)")|"
out+="$(burned NPC "V test round" V)|"

# Non-lethal: the ganger, no longer immortal and nearly dead, takes one more hit. The round stops
# burning and the ganger's burn is put out first, so the shot and not a burn tick is what drops it.
lua "TweakDB:SetFlat('Ammo.AO_Test_HitData.aoEffectChances', {0.0})
Game.GetStatusEffectSystem():RemoveStatusEffect(RIG.npc():GetEntityID(), TweakDBID.new('BaseStatusEffect.Burning')); return 1" >/dev/null
sleep 6
lua "local n = RIG.npc(); RIG.npcMode = nil; Game.GetGodModeSystem():RemoveGodMode(n:GetEntityID(), gameGodModeType.Immortal, CName.new('aorig')); return 1" >/dev/null
killshot() { # V shoots the rig's NPC, at 1 health, until it goes down
  for _ in $(seq 10); do
    lua "local n = RIG.npc(); Game.GetStatusEffectSystem():RemoveStatusEffect(n:GetEntityID(), TweakDBID.new('BaseStatusEffect.Burning'))
Game.GetStatPoolsSystem():RequestSettingStatPoolValue(n:GetEntityID(), gamedataStatPoolType.Health, 1.0, nil); RIG.fireV(); return 1" >/dev/null; sleep 0.5
    [[ $(lua "local n = RIG.npc(); return (n:IsDead() or ScriptedPuppet.IsDefeated(n) or ScriptedPuppet.IsUnconscious(n)) and 'down' or 'up'") == down ]] && break
  done
  sleep 3
}
killshot
lua "TweakDB:SetFlat('Ammo.AO_Test_HitData.aoEffectChances', {1.0}); return 1" >/dev/null
# A lethal hit on an NPC with the defeat mechanic leaves it Defeated too: only Unconscious is a knock-out.
st=$(lua "local n = RIG.npc(); return string.format('dead=%s unconscious=%s', tostring(n:IsDead()), tostring(ScriptedPuppet.IsUnconscious(n)))")
out+="$([[ $st == "dead=false unconscious=true" ]] && echo PASS || echo FAIL) the test round's kill knocks out ($st)|"
# Control: Ball's killing shot on the same ganger is no knock-out.
feed Items.AO_Feed_9mm_Ball
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
if spawn 0.0 "" Character.AO_Test_Plain_Lexington && setup $LEX; then
  lua "local n = RIG.npc(); Game.GetGodModeSystem():RemoveGodMode(n:GetEntityID(), gameGodModeType.Invulnerable, CName.new('aorig')); return 1" >/dev/null
  killshot
  st=$(lua "local n = RIG.npc(); return string.format('dead=%s unconscious=%s', tostring(n:IsDead()), tostring(ScriptedPuppet.IsUnconscious(n)))")
  out+="$([[ $st == *"unconscious=false"* ]] && echo PASS || echo FAIL) Ball's kill is no knock-out ($st)|"
fi
feed Items.AO_Feed_Test_HitData

# A ganger firing the test round at V.
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
vulnerable
# The rig respawns its own Unity when it loses sight of the NPC: only the test ganger's hits count.
ganger() { [[ $(lua "local n = RIG.npc(); return n and TDBID.ToStringDEBUG(n:GetRecordID()) or ''") == Character.AO_Test_Ganger_9mm_HitData ]]; }
for _ in 1 2 3; do
  if spawn 0.0 Ammo.AO_Test_HitData Character.AO_Test_Ganger_9mm_HitData && setup && ganger; then
    vulnerable
    npcshoot 8
    sleep 2
    ganger && break
  fi
done
if ganger; then
  out+="$(shares NPC 'NPC test round')|"
  # V gets the Player version of the burn, as vanilla's own burns.
  out+="$(burned V "NPC test round" NPC BaseStatusEffect.PlayerBurning)|"
fi

kitgod
# V on an android (a Lexington security android: CharacterType Android, so a machine).
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
ANDROID=Character.security_android_android2_lexington_ma
if spawn 0.0 "" "$ANDROID"; then
  # Drawing the gun again drops the fitted selector: fit the test round again and check it's loaded.
  draw $LEX; feed Items.AO_Feed_Test_HitData; setup $LEX
  loaded=$($C 'return Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):DebugLoadedAmmo(Game.GetPlayer())' | sed -n 's/^=> //p')
  [[ $loaded == Ammo.AO_Test_HitData ]] || out+="FAIL V loads $loaded, not the test round, for the android|"
  shoot $LEX 8
  out+="$(lua "local v = RIG.ratios('V')
local ok = #v >= 5 and v[1] >= 1.796 and v[#v] <= 2.024
return string.format('%s %d V test round hits on an android x2 (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0)")|"
fi
$C "FEED='Items.AO_Feed_9mm_Ball'; $(cat $S/set-feed.lua)" >/dev/null
lua "RIG.teardown(); return 1" >/dev/null
res=$(tr '|' '\n' <<<"$out" | sed '/^$/d'); echo "$res"
p=$(grep -c '^PASS' <<<"$res"); n=$(grep -c '^FAIL' <<<"$res")
EXPECT=8
(( p + n >= EXPECT )) || { echo "FAIL only $((p + n)) of $EXPECT checks reported"; n=$((n + 1)); }
echo "== hitdata: $p pass, $n fail"
(( n == 0 && p > 0 ))
