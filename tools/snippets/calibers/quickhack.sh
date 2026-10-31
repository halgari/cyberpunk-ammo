#!/usr/bin/env bash
# Quickhack rounds on live hits (spec docs/superpowers/specs/2026-10-31-quickhack-rounds-design.md,
# "Testing"), one check per mechanism. Parts: effects overheat ranks guarded cloud grenade (default all):
#   tools/linux/game-lock.sh tools/snippets/calibers/quickhack.sh [part ...]
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
source tools/linux/common.sh
parts=("$@"); (( ${#parts[@]} )) || parts=(effects overheat ranks guarded cloud grenade)
SYS="Game.GetScriptableSystemsContainer():Get('AmmoOverhaul.AmmoFeedSystem')"
YUK=Items.Preset_Yukimura_Default; PLAIN=Character.AO_Test_Plain_Unity
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; out+="FAIL $*|"; }
is() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1: got '$2', want '$3'"; }
kit() { $C "for _, i in ipairs({$1}) do Game.AddToInventory(i[1], i[2]) end return 1" >/dev/null; sleep 1; }
frail() { lua "local o = $1; Game.GetGodModeSystem():ClearGodMode(o:GetEntityID(), CName.new('aorig'))
Game.GetStatPoolsSystem():RequestSettingStatPoolValue(o:GetEntityID(), gamedataStatPoolType.Health, $2, nil, true); return 1" >/dev/null; }
despawn() { lua "RIG.npcMode = nil; GetMod('AOTestKit').despawnAll(); return 1" >/dev/null; sleep 1; }
rankchance() { lua "TweakDB:SetFlat('$1.aoRankChance', $2); return 1" >/dev/null; }
health() { lua "return string.format('%.1f', Game.GetStatPoolsSystem():GetStatPoolValue($1:GetEntityID(), gamedataStatPoolType.Health))"; }
has() { lua "return tostring(StatusEffectSystem.ObjectHasStatusEffect($1, TweakDBID.new('BaseStatusEffect.$2')))"; }
# Far more health, so a burst leaves the target alive and the hack's own damage shows, as a share.
tanky() { lua "local o = $1; Game.GetGodModeSystem():ClearGodMode(o:GetEntityID(), CName.new('aorig'))
Game.GetStatsSystem():AddModifier(o:GetEntityID(), RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Additive, 20000.0)); return 1" >/dev/null; sleep 0.5; frail "$1" 100.0; sleep 0.5; }
below() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'; }
# The Yukimura on a hack round of the 10mm, its chance at 1.0, facing a plain NPC.
vs() { # round
  rankchance Ammo.AO_S10_$1 1.0
  kit "{'$YUK', 1}, {'Items.AO_Feed_10mm_$1', 1}, {'Ammo.AO_S10_$1', 200}"
  draw $YUK; draw $YUK; feed Items.AO_Feed_10mm_$1
  spawn 0.0 "" $PLAIN
  setup $YUK
}
NB="Game.GetDynamicEntitySystem():GetTagged('AO_Test')[2]"
# A second NPC, frozen, and the attack's range stretched to reach it: the rig can't stand it closer.
neighbour() { # attack
  lua "TweakDB:SetFlat('$1.range', 20.0); GetMod('AOTestKit').spawn('$PLAIN', 1); return 1" >/dev/null
  sleep 4
  lua "local o = $NB; Game.GetGodModeSystem():ClearGodMode(o:GetEntityID(), CName.new('aorig'))
o:SetIndividualTimeDilation(CName.new('aorig'), 0.0001, 9999.0, CName.new(''), CName.new('')); return 1" >/dev/null
  sleep 0.5
}

# --- effects: one tier of each hack lands on a Normal --------------------------------------------
effects() {
  local r
  for r in "HackOptics1 QuickHackBlindLvl1" "HackSonic2 CommsNoiseLevel2" "HackCyberware4 CyberwareMalfunctionLvl4" \
    "HackCripple1 LocomotionMalfunction" "HackOverheat2 OverheatLevel2" "HackGlitch3 WeaponMalfunctionLvl3" \
    "HackBurnout2 BrainMeltLevel2" "HackPsycho3 Madness" "HackShort1 OverloadLevel1" "HackContagion1 ContagionPoison"; do
    set -- $r
    vs $1
    frail "RIG.npc()" 100.0
    shoot "" 1
    local n; n=$(lua "return RIG.effects('NPC', 'BaseStatusEffect.$2')")
    [[ $n -ge 1 ]] && pass "$1 applies $2" || fail "$1: $2 not applied"
    despawn
    rankchance Ammo.AO_S10_$1 0.1
  done
}

# --- overheat: a live hit takes health ------------------------------------------------------------
overheat() {
  vs HackOverheat4
  tanky "RIG.npc()"
  shoot "" 1
  local a; a=$(health "RIG.npc()")
  sleep 5
  local b; b=$(health "RIG.npc()")
  echo "  health $a to $b, burning $(has "RIG.npc()" OverheatLevel4)"
  below "$b" "$a" && pass "Overheat burns" || fail "Overheat took no health: $a to $b"
  despawn
  rankchance Ammo.AO_S10_HackOverheat4 0.25
}

# --- ranks: who's immune to what ------------------------------------------------------------------
ranks() {
  rk() { lua "return $SYS:DebugRankResult('$1', '$2', $3, $4)"; }
  is "Boss takes Reboot Optics" "$(rk Ammo.AO_S10_HackOptics1 Boss false false)" BaseStatusEffect.QuickHackBlindLvl1
  is "MaxTac takes Reboot Optics" "$(rk Ammo.AO_S10_HackOptics1 MaxTac false false)" BaseStatusEffect.QuickHackBlindLvl1
  is "Boss shrugs off Cyberpsychosis" "$(rk Ammo.AO_S10_HackPsycho3 Boss false false)" "<TDBID:00000000:00>"
  is "a machine gets nothing" "$(rk Ammo.AO_S10_HackShort4 Normal true false)" "<TDBID:00000000:00>"
  is "V gets nothing" "$(rk Ammo.AO_S10_HackOptics1 '' false false)" "<TDBID:00000000:00>"
}

# --- guarded: an Immortal NPC isn't overloaded ----------------------------------------------------
guarded() {
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  vs HackShort4
  shoot "" 2
  sleep 1
  is "no overload on an Immortal NPC" "$(lua "return RIG.effects('NPC', 'BaseStatusEffect.OverloadLevel4')")" 0
  despawn
  rankchance Ammo.AO_S10_HackShort4 0.1
}

# --- cloud: Contagion reaches a neighbour, not V, not a quest NPC, and doesn't chain ---------------
cloud() {
  local poison=ContagionPoisonLvl2
  vs HackContagion2
  frail "RIG.npc()" 100.0
  neighbour AmmoOverhaul.HackCloud2
  local got=false
  for _ in 1 2 3 4 5 6 7 8; do
    lua "RIG.clear(); return RIG.fireV()" >/dev/null; sleep 0.4
    [[ $(has "$NB" $poison) == true ]] && { got=true; break; }
  done
  is "Contagion reaches the neighbour" $got true
  is "the cloud spares V" "$(has "Game.GetPlayer()" $poison)" false
  despawn
  vs HackContagion2
  frail "RIG.npc()" 100.0
  neighbour AmmoOverhaul.HackCloud2
  lua "Game.GetGodModeSystem():AddGodMode($NB:GetEntityID(), gameGodModeType.Immortal, CName.new('AO_Test')); return 1" >/dev/null
  for _ in 1 2 3 4; do lua "return RIG.fireV()" >/dev/null; sleep 0.4; done
  is "the cloud spares a quest NPC" "$(has "$NB" $poison)" false
  local blasts; blasts=$(lua "local n = 0 for _ in string.gmatch($SYS:Trail(), 'hack blast') do n = n + 1 end return n")
  (( blasts >= 1 && blasts <= 4 )) && pass "4 shots make at most 4 clouds ($blasts)" || fail "clouds: $blasts from 4 shots"
  despawn
  lua "TweakDB:SetFlat('AmmoOverhaul.HackCloud2.range', 3.0); return 1" >/dev/null
  rankchance Ammo.AO_S10_HackContagion2 0.06
}

# --- grenade: the blast hurts the target and whoever's by it ---------------------------------------
grenade() {
  vs HackGrenade3
  tanky "RIG.npc()"
  neighbour AmmoOverhaul.HackBlast
  tanky "$NB"
  local a b c; a=$(health "$NB")
  shoot "" 1
  sleep 1.5
  b=$(health "$NB"); c=$(health "RIG.npc()")
  echo "  target to $c, neighbour $a to $b; blasts $(lua "local n = 0 for _ in string.gmatch($SYS:Trail(), 'hack blast') do n = n + 1 end return n"), hits $(lua "return #RIG.ratios('V')")"
  below "$c" 90 && pass "Detonate Grenade's blast hurts the target ($c)" || fail "no blast on the target: $c"
  below "$b" "$a" && pass "it reaches the neighbour" || fail "no blast damage on the neighbour: $a to $b"
  despawn
  lua "TweakDB:SetFlat('AmmoOverhaul.HackBlast.range', 3.0); return 1" >/dev/null
  rankchance Ammo.AO_S10_HackGrenade3 0.2
}

for p in "${parts[@]}"; do echo "== $p"; $p; done
lua "RIG.teardown(); return 1" >/dev/null
[[ -z "$out" ]] || { echo "${out//|/$'\n'}"; exit 1; }
