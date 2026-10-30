#!/usr/bin/env bash
# Faction rounds on live hits (spec docs/superpowers/specs/2026-10-30-faction-rounds-design.md,
# "Testing"), one check per mechanism. Parts: affiliation rolls lists redliners oneGun reloads parts kansatsu
# (default all):
#   tools/linux/game-lock.sh tools/snippets/calibers/faction.sh [part ...]
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
source tools/linux/common.sh
parts=("$@"); (( ${#parts[@]} )) || parts=(affiliation rolls lists redliners oneGun reloads parts kansatsu)
SYS="Game.GetScriptableSystemsContainer():Get('AmmoOverhaul.AmmoFeedSystem')"
UNI=Items.Preset_Unity_Default
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; out+="FAIL $*|"; }
is() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1: got '$2', want '$3'"; }
kit() { $C "for _, i in ipairs({$1}) do Game.AddToInventory(i[1], i[2]) end return 1" >/dev/null; sleep 1; }
# The share of $2 in a DebugFactionPick result $1, in percent.
share() { awk -v s="$1" -v k="$2" 'BEGIN { n = split(s, a, ";"); for (i = 1; i <= n; i++) { split(a[i], p, "=");
  t += p[2]; if (index(p[1], k)) c += p[2] } printf "%.1f", 100 * c / t }'; }
within() { awk -v v="$2" -v lo="$3" -v hi="$4" 'BEGIN { exit !(v >= lo && v <= hi) }' && pass "$1 ($2)" || fail "$1: $2 not in $3..$4"; }

# --- affiliation: the spelling at runtime, on the records the spec maps -------------------------
affiliation() {
  local rec
  for rec in "Character.sq031_maelstrom_strong_shotgunner_elite Maelstrom" "Character.high_scavenger_grunt1_melee1_pipewrench_ma Scavengers"; do
    set -- $rec
    is "$1 reads as $2" "$(lua "return NameToString(TweakDB:GetRecord('$1'):Affiliation():EnumName())")" "$2"
  done
  is "an unmapped affiliation has no faction flat" "$(lua "return tostring(TweakDB:GetFlat('AmmoOverhaul.factionOf.KangTao'))")" nil
}

# --- rolls: own faction only, the rank chances, Legendary first, a miss falls through -----------
rolls() {
  local r
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Normal', 'Maelstrom', 20000)")
  within "a Normal Maelstrom's .45 rolls Redliners about 10%" "$(share "$r" Redliners)" 8.5 11.5
  is "a Normal rolls no faction Epic" "$(share "$r" MeatGrinders)" 0.0
  is "no other faction's round" "$(share "$r" Dirties)" 0.0
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Elite', 'Scavengers', 20000)")
  within "an Elite Scav's .45 rolls a Rare or Common faction round about 22%" "$(awk "BEGIN { print $(share "$r" Reloads) + $(share "$r" Dirties) + $(share "$r" PartsPullers) }")" 19 27
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Boss', 'Arasaka', 20000)")
  within "a Boss Arasaka's .45 rolls Kata about 15%" "$(share "$r" Kata)" 12 18
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Elite', '', 20000)")
  is "no faction, no faction round" "$(awk "BEGIN { print $(share "$r" Redliners) + $(share "$r" Dirties) + $(share "$r" Kata) }")" 0
  within "no faction: an Elite still rolls Legendary about 3%" "$(share "$r" CookOff)" 2 4
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'MaxTac', 'Arasaka', 20000)")
  is "MaxTac gets no faction round" "$(share "$r" Kata)" 0.0
  r=$(lua "return $SYS:DebugFactionPick('Power_127', 'Boss', 'Maelstrom', 5000)")
  is "a caliber with no round for the faction: nothing" "$(share "$r" Redliners)" 0.0
}

# --- lists: tiers 5 to 7 reach no general list ----------------------------------------------------
lists() {
  local v r
  for v in Ammo.HandgunAmmo Ammo.RifleAmmo Ammo.ShotgunAmmo Ammo.SniperRifleAmmo; do
    r=$(lua "return tostring($SYS:DebugSpread('$v', 100000, 4))")
    [[ $r != *Redliners* && $r != *Reloads* && $r != *Kata* && $r != *Kansatsu* ]] && pass "$v spread holds no faction round" || fail "$v spread: $r"
  done
}

# --- redliners: fire rate, the shooter's jam on V and on an NPC, and that it clears ----------------
redliners() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Redliners', 1}, {'Ammo.AO_45_Redliners', 500}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Ball; sleep 1
  local gun="Game.GetTransactionSystem():GetItemInSlot(Game.GetPlayer(), TweakDBID.new('AttachmentSlots.WeaponRight'))"
  local read="return Game.GetStatsSystem():GetStatValue($gun:GetEntityID(), gamedataStatType.CycleTime)"
  local before after; before=$(lua "$read"); feed Items.AO_Feed_45_Redliners; after=$(lua "$read")
  within "CycleTime x0.8 on V's gun" "$(awk "BEGIN { printf \"%.3f\", $after / $before }")" 0.79 0.81

  lua "TweakDB:SetFlat('Ammo.AO_45_Redliners.aoSelfJam', 1.0); return 1" >/dev/null
  local has="return Game.GetStatusEffectSystem():HasStatusEffect(Game.GetPlayer():GetEntityID(), TweakDBID.new('AmmoOverhaul.RedlinerJam'))"
  spawn 0.0 "" Character.AO_Test_Plain_Unity; setup $UNI
  lua "RIG.fireV(); return 1" >/dev/null; sleep 0.5
  is "a shot jams V's gun" "$(lua "$has")" true
  sleep 3.5
  is "V's jam clears after 3 s" "$(lua "$has")" false

  fail "NPC jam: needs a forced Redliners roll (set npcFactionChance.Normal to 1 on a Maelstrom NPC); write when the game is free"
  lua "TweakDB:SetFlat('Ammo.AO_45_Redliners.aoSelfJam', 0.02); return 1" >/dev/null
}

# --- oneGun: a round's stats stay on the one gun (the lesson from Heartseeker) ----------------------
oneGun() {
  local rec="Items.Preset_Unity_Default"
  local before; before=$(lua "return tostring(TweakDB:GetFlat('$rec.evolution')) .. tostring(TweakDB:GetFlat('$rec.rangedAttacks'))")
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Redliners', 1}, {'Ammo.AO_45_Redliners', 100}"
  draw $UNI; feed Items.AO_Feed_45_Redliners
  is "fitting a faction round leaves the gun's record alone" "$(lua "return tostring(TweakDB:GetFlat('$rec.evolution')) .. tostring(TweakDB:GetFlat('$rec.rangedAttacks'))")" "$before"
}

# --- reloads: the Scavengers roll layer -----------------------------------------------------------
reloads() {
  is "Reloads take the Scav roll" "$(lua "return $SYS:DebugRollFor('Ammo.AO_45_Reloads', '', false)")" "$(lua "return $SYS:DebugRollFor('Ammo.AO_45_Dirties', '', false)")"
  local r; r=$(lua "return $SYS:DebugRollFor('Ammo.AO_45_Reloads', '', false)")
  [[ $r == 0.7* ]] && pass "Scav roll floor 0.70 ($r)" || fail "Scav roll: $r"
}

# --- parts: V's kill leaves the components; a knockout or another hit doesn't ---------------------
parts() {
  fail "parts: write with the live kill rig (legendary.sh cookoff) when the game is free"
}

# --- kansatsu: lock stats on the one gun, the tag; the instant lock probe is separate ---------------
kansatsu() {
  fail "kansatsu: probe instant lock on a tagged target first (spec, no evolution switch)"
}

for p in "${parts[@]}"; do echo "== $p"; $p; done
lua "RIG.teardown(); return 1" >/dev/null
[[ -z "$out" ]] || { echo "${out//|/$'\n'}"; exit 1; }
