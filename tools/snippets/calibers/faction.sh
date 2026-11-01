#!/usr/bin/env bash
# Faction rounds on live hits (spec docs/superpowers/specs/2026-10-30-faction-rounds-design.md,
# "Testing"), one check per mechanism. Parts: affiliation rolls lists turf stats oneGun reloads redliners
# swap chrome roll parts kansatsu affiliation2 headfx headonv stops legs pumped crits affiliation3 rolls3
# turf3 ranks3 sand juju cutoff lastcall collect shock clap wastenot speedloaders tax chimera deniable stats3 (default all):
#   tools/linux/game-lock.sh tools/snippets/calibers/faction.sh [part ...]
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL. The rig's shots don't
# go through V's shooting state, so V's self-jam is driven by DebugSelfJam, not a trigger pull.
source "$(dirname "$0")/npc-lib.sh"
source tools/linux/common.sh
parts=("$@"); (( ${#parts[@]} )) || parts=(affiliation rolls lists turf stats oneGun reloads redliners swap chrome roll parts kansatsu affiliation2 headfx headonv stops legs pumped crits affiliation3 rolls3 turf3 ranks3 sand juju cutoff lastcall collect shock clap wastenot speedloaders tax chimera deniable stats3)
SYS="Game.GetScriptableSystemsContainer():Get('AmmoOverhaul.AmmoFeedSystem')"
UNI=Items.Preset_Unity_Default; LEX=Items.Preset_Lexington_Default; OMA=Items.Preset_Omaha_Default; YUK=Items.Preset_Yukimura_Default
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; out+="FAIL $*|"; }
is() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1: got '$2', want '$3'"; }
kit() { $C "for _, i in ipairs({$1}) do Game.AddToInventory(i[1], i[2]) end return 1" >/dev/null; sleep 1; }
# The share of $2 in a DebugFactionPick result $1, in percent.
share() { awk -v s="$1" -v k="$2" 'BEGIN { n = split(s, a, ";"); for (i = 1; i <= n; i++) { split(a[i], p, "=");
  t += p[2]; if (index(p[1], k)) c += p[2] } printf "%.1f", 100 * c / t }'; }
within() { awk -v v="$2" -v lo="$3" -v hi="$4" 'BEGIN { exit !(v >= lo && v <= hi) }' && pass "$1 ($2)" || fail "$1: $2 not in $3..$4"; }
RARITIES="{'Trash','Weak','Normal','Rare','Officer','Elite','Boss','MaxTac'}"
# Every rank's Rare and Epic faction chance, or back to core.yaml with no argument.
chances() {
  if [[ $# == 2 ]]; then lua "for _, r in ipairs($RARITIES) do TweakDB:SetFlat('AmmoOverhaul.npcFactionChance.' .. r, $1); TweakDB:SetFlat('AmmoOverhaul.npcFactionEpicChance.' .. r, $2); TweakDB:SetFlat('AmmoOverhaul.npcFactionEpicChance.Arasaka.' .. r, $2) end return 1" >/dev/null
  else lua "local a = { Weak = 0.05, Normal = 0.10, Rare = 0.15, Officer = 0.20, Elite = 0.25, Boss = 0.30 }
local e = { Rare = 0.03, Officer = 0.05, Elite = 0.10, Boss = 0.15 }
local z = { Normal = 0.05, Rare = 0.10, Officer = 0.15, Elite = 0.20, Boss = 0.25 }
for _, r in ipairs($RARITIES) do TweakDB:SetFlat('AmmoOverhaul.npcFactionChance.' .. r, a[r] or 0.0); TweakDB:SetFlat('AmmoOverhaul.npcFactionEpicChance.' .. r, e[r] or 0.0)
  TweakDB:SetFlat('AmmoOverhaul.npcFactionEpicChance.Arasaka.' .. r, z[r] or 0.0) end return 1" >/dev/null; fi
}
selfjam() { lua "TweakDB:SetFlat('Ammo.AO_45_Redliners.aoSelfJam', $1); return 1" >/dev/null; }
trap 'chances; selfjam 0.02; restore' EXIT
vjam() { lua "return StatusEffectSystem.ObjectHasStatusEffectOfType(Game.GetPlayer(), gamedataStatusEffectType.Jam)"; }
gunstat() { lua "return string.format('%.4f', Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetActiveWeapon():GetEntityID(), gamedataStatType.$1))"; }
ratio() { awk "BEGIN { printf \"%.3f\", $2 / $1 }"; }
qty() { lua "return Game.GetTransactionSystem():GetItemQuantity(RIG.npc(), ItemID.CreateQuery(TweakDBID.new('$1')))"; }
frail() { lua "local o = $1; Game.GetGodModeSystem():ClearGodMode(o:GetEntityID(), CName.new('aorig'))
Game.GetStatPoolsSystem():RequestSettingStatPoolValue(o:GetEntityID(), gamedataStatPoolType.Health, $2, nil, true); return 1" >/dev/null; sleep 1; }
vulnerable() { lua 'local k, gm, p = GetMod("AOTestKit"), Game.GetGodModeSystem(), Game.GetPlayer():GetEntityID()
if AO_KITGOD == nil then AO_KITGOD = k.state.godMode end
k.state.godMode = false
for _, s in ipairs({"AO_TestKit", "AO_Test"}) do gm:RemoveGodMode(p, gameGodModeType.Invulnerable, CName.new(s)) end return 1' >/dev/null; }
kitgod() { lua 'local k = GetMod("AOTestKit")
if AO_KITGOD ~= nil then k.state.godMode = AO_KITGOD; AO_KITGOD = nil end
if k.state.godMode then Game.GetGodModeSystem():AddGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_TestKit")) end return 1' >/dev/null; }
despawn() { lua "RIG.npcMode = nil; GetMod('AOTestKit').despawnAll(); return 1" >/dev/null; sleep 1; }

# --- affiliation: the spelling at runtime, and on a spawned NPC -----------------------------------
affiliation() {
  local rec f
  for rec in "Character.AO_Test_Mael_Unity Maelstrom" "Character.AO_Test_Scav_Unity Scavengers" "Character.AO_Test_Ara_Unity Arasaka"; do
    set -- $rec
    spawn 0.0 "" "$1"
    is "a spawned $1 rolls as $2" "$(lua "return $SYS:DebugFactionOf(RIG.npc())")" "$2"
  done
  despawn
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  is "a Tyger-free street goon has no faction" "$(lua "return $SYS:DebugFactionOf(RIG.npc())")" ""
  despawn
  for rec in sq031_maelstrom_strong_shotgunner_elite high_scavenger_grunt1_melee1_pipewrench_ma; do
    echo "  $rec: $(lua "return NameToString(TweakDB:GetRecord('Character.$rec'):Affiliation():EnumName())")"
  done
}

# --- rolls: own faction only, the rank chances, Legendary first, a miss falls through ------------
rolls() {
  local r
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Normal', 'Maelstrom', 8000)")
  within "a Normal Maelstrom's .45 rolls Redliners about 10%" "$(share "$r" Redliners)" 8.5 11.5
  is "a Normal rolls no faction Epic" "$(share "$r" MeatGrinders)" 0.0
  is "no other faction's round" "$(share "$r" GutterLead)" 0.0
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Elite', 'Scavengers', 8000)")
  within "an Elite Scav's .45 rolls a Rare or Common faction round, 25% of what's past Legendary" "$(awk "BEGIN { print $(share "$r" Reloads) + $(share "$r" GutterLead) + $(share "$r" PartsPullers) }")" 21 27
  within "Reloads, Gutter Lead and Parts-pullers come up alike" "$(share "$r" Reloads)" 6.5 9.5
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Boss', 'Arasaka', 8000)")
  within "a Boss Arasaka's .45 rolls an Epic of theirs about 25% (after Legendary)" "$(awk "BEGIN { print $(share "$r" Kata) + $(share "$r" Shinobi) }")" 20 25
  within "Kata and Shinobi come up alike" "$(share "$r" Shinobi)" 9.5 13
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Normal', 'Arasaka', 8000)")
  within "a Normal Arasaka's .45 rolls one about 5%, from Arasaka's own table" "$(awk "BEGIN { print $(share "$r" Kata) + $(share "$r" Shinobi) }")" 4 6
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Weak', 'Arasaka', 8000)")
  is "a Weak Arasaka rolls none" "$(awk "BEGIN { print $(share "$r" Kata) + $(share "$r" Shinobi) }")" 0
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Boss', 'Maelstrom', 8000)")
  within "a Boss Maelstrom's .45 keeps the shared 15% Epic (after Legendary)" "$(share "$r" MeatGrinders)" 12 15.5
  r=$(lua "return $SYS:DebugFactionPick('Tech_Light', 'Boss', 'Maelstrom', 8000)")
  within "a Boss Maelstrom's light rail rolls Chrome-cookers, the shared Epic" "$(share "$r" ChromeCookers)" 11.5 16
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Elite', '', 8000)")
  is "no faction, no faction round" "$(awk "BEGIN { print $(share "$r" Redliners) + $(share "$r" GutterLead) + $(share "$r" Kata) }")" 0
  within "no faction: an Elite still rolls Legendary about 3%" "$(share "$r" CookOff)" 2 4
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'MaxTac', 'Arasaka', 8000)")
  is "MaxTac gets no faction round" "$(share "$r" Kata)" 0.0
  r=$(lua "return $SYS:DebugFactionPick('Power_127', 'Boss', 'Maelstrom', 5000)")
  is "a caliber with no round for the faction: nothing of theirs" "$(share "$r" Redliners)" 0.0
  # On real NPCs: the forced chance gives each its own round.
  chances 1.0 0.0
  spawn 0.0 Ammo.AO_45_Redliners Character.AO_Test_Mael_Unity && pass "a Maelstrom NPC carries Redliners"
  despawn
  AO_TRIES=20 spawn 0.0 Ammo.AO_45_GutterLead Character.AO_Test_Scav_Unity && pass "a Scav NPC carries Gutter Lead"
  despawn
  chances 1.0 1.0
  AO_TRIES=20 spawn 0.0 Ammo.AO_45_Shinobi Character.AO_Test_Ara_Unity && pass "an Arasaka NPC carries Shinobi"
  despawn
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  is "an unaffiliated NPC gets none with the chance at 1" "$(qty Ammo.AO_45_Redliners)$(qty Ammo.AO_45_Shinobi)$(qty Ammo.AO_45_GutterLead)" 000
  despawn; chances
}

# --- lists: tiers 5 to 7 reach no general list ---------------------------------------------------
lists() {
  local v r
  for v in Ammo.HandgunAmmo Ammo.RifleAmmo Ammo.ShotgunAmmo Ammo.SniperRifleAmmo; do
    r=$(lua "return tostring($SYS:DebugSpread('$v', 100000, 4))")
    [[ -n $r && $r != *Redliners* && $r != *Reloads* && $r != *Kata* && $r != *Kansatsu* && $r != *GutterLead* ]] && pass "$v spread holds no faction round" || fail "$v spread: $r"
  done
}

# --- turf: the four shops' stock builds, on a vendor object of their own ---------------------------
turf() {
  local r shop always
  # builds with a stack beyond `always`, stacks of the faction, out of the builds.
  count() { tr '|' '\n' <<<"$1" | tail -n +2 | awk -F';' -v a="$2" -v re="$3" '
    { n = NF - 1; c = 0; for (i = 1; i < NF; i++) if ($i ~ re) c++; if (c != a) bad++; if (n - a > 0) more++; if (n - a > m) m = n - a; b++ }
    END { printf "%d %d %d %d", b, more, m, bad }'; }
  for shop in "wat_nid_gunsmith_01 Redliners MeatGrinders|ChromeCookers 0 x" "cct_dtn_guns_01 Shinobi Kata|Kansatsu 0 x" \
      "wat_kab_gunsmith_02 GutterLead|PartsPullers Nothing 3 Reloads" "std_arr_gunsmith_01 GutterLead|PartsPullers Nothing 3 Reloads"; do
    read -r id own never always re <<<"$shop"
    r=$(lua "return $SYS:DebugTurf('Vendors.$id', 200)")
    is "$id is a gun shop" "${r%%|*}" Gunsmith
    read -r b more m bad <<<"$(count "$r" "$always" "$re")"
    is "$id: 200 builds" "$b" 200
    is "$id: its $always stacks every build" "$bad" 0
    within "$id: extra stacks in about 25% of builds" "$(awk "BEGIN { print 100 * $more / $b }")" 16 34
    [[ $m -ge 1 && $m -le 2 ]] && pass "$id: one or two stacks ($m at most)" || fail "$id: $m extra stacks"
    grep -qE "$own" <<<"$r" && pass "$id sells its faction's rounds" || fail "$id: none of $own"
    grep -qE "$never" <<<"$r" && fail "$id sells $never" || pass "$id sells none of $never"
    [[ $(tr '|;' '\n' <<<"${r#*|}" | grep -v '^$' | grep -cvE "$own|$re") == 0 ]] && pass "$id: no other faction's round" || fail "$id: $r"
  done
  # Shinobi at Arasaka's shop is the one Epic any shop sells, in stacks of 10.
  r=$(lua "return $SYS:DebugTurf('Vendors.cct_dtn_guns_01', 200)")
  [[ $(tr '|;' '\n' <<<"${r#*|}" | grep -v '^$' | grep -cvE '^Ammo\.AO_(9mm|45)_Shinobi=10$') == 0 ]] && pass "cct_dtn_guns_01: Shinobi only, stacks of 10" || fail "cct_dtn_guns_01: $r"
  r=$(lua "return $SYS:DebugTurf('Vendors.wat_lch_gunsmith_01', 40)")
  [[ ${r%%|*} == Gunsmith && $(tr -d '|' <<<"${r#*|}") == "" ]] && pass "a gun shop off turf sells no faction round" || fail "off turf: $r"
}

# --- stats: the kinds that are only stats, on V's gun --------------------------------------------
stats() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Kata', 1}, {'Ammo.AO_45_Kata', 100}, {'Items.AO_Feed_45_Shinobi', 1}, {'Ammo.AO_45_Shinobi', 100}, {'Items.AO_Feed_45_MeatGrinders', 1}, {'Ammo.AO_45_MeatGrinders', 100}, {'Items.AO_Feed_45_Redliners', 1}, {'Ammo.AO_45_Redliners', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Ball
  local cy aim rec dis hs
  cy=$(gunstat CycleTime); aim=$(gunstat AimInTime); rec=$(gunstat RecoilKickMax); dis=$(gunstat HitDismembermentFactor); hs=$(gunstat HeadshotDamageMultiplier)
  echo "  Ball: cycle $cy aim $aim recoil $rec dismember $dis headshot $hs"
  feed Items.AO_Feed_45_Redliners
  within "Redliners: CycleTime x0.8" "$(ratio $cy $(gunstat CycleTime))" 0.79 0.81
  within "Redliners: recoil x1.4" "$(ratio $rec $(gunstat RecoilKickMax))" 1.39 1.41
  feed Items.AO_Feed_45_Kata
  within "Kata: AimInTime x0.7" "$(ratio $aim $(gunstat AimInTime))" 0.69 0.71
  within "Kata: recoil x0.7" "$(ratio $rec $(gunstat RecoilKickMax))" 0.69 0.71
  feed Items.AO_Feed_45_Shinobi
  is "Shinobi: silent kills" "$(gunstat CanSilentKill)" 1.0000
  within "Shinobi: headshot +0.5" "$(awk "BEGIN { printf \"%.3f\", $(gunstat HeadshotDamageMultiplier) - $hs }")" 0.49 0.51
  feed Items.AO_Feed_45_MeatGrinders
  within "Meat-grinders: dismemberment x3" "$(ratio $dis $(gunstat HitDismembermentFactor))" 2.9 3.1
}

# --- oneGun: a round's stats stay on the one gun (the lesson from Heartseeker) ---------------------
oneGun() {
  local read="return TDBID.ToStringDEBUG(TweakDB:GetFlat('$UNI.evolution')) .. ' ' .. TDBID.ToStringDEBUG(TweakDB:GetFlat('$UNI.crosshair'))"
  local before cy; before=$(lua "$read")
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Redliners', 1}, {'Ammo.AO_45_Redliners', 100}, {'Items.AO_Feed_45_Subsonic', 1}, {'Ammo.AO_45_Subsonic', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Subsonic; cy=$(gunstat CycleTime)
  chances 1.0 0.0
  spawn 0.0 Ammo.AO_45_Redliners Character.AO_Test_Mael_Unity
  chances
  local npc; npc=$(lua "return string.format('%.4f', Game.GetStatsSystem():GetStatValue(ScriptedPuppet.GetActiveWeapon(RIG.npc()):GetEntityID(), gamedataStatType.CycleTime))")
  feed Items.AO_Feed_45_Redliners
  is "fitting a faction round leaves the gun's record alone" "$(lua "$read")" "$before"
  is "an NPC's rolled Redliners leave V's own Unity as it was, until V fits them" "$(awk "BEGIN { print ($(gunstat CycleTime) < $cy) }")" 1
  feed Items.AO_Feed_45_Subsonic
  is "another round takes the Redliners' stats off V's Unity" "$(gunstat CycleTime)" "$cy"
  echo "  NPC Redliners Unity CycleTime $npc, V's Unity on another round $cy"
  despawn
}

# --- reloads: the Scavengers roll layer ------------------------------------------------------------
reloads() {
  local r; r=$(lua "return $SYS:DebugRollFor('Ammo.AO_45_Reloads', '', false)")
  echo "  Reloads roll: $r"
  is "Gutter Lead take the same Scav roll" "$(lua "return $SYS:DebugRollFor('Ammo.AO_45_GutterLead', '', false)")" "$r"
  [[ $r == 0.7* ]] && pass "Scav roll starts at 0.70" || fail "Scav roll: $r"
  r=$(lua "return $SYS:DebugRollFor('Ammo.AO_45_Kata', '', false)")
  [[ $r == 0.99* ]] && pass "Kata's own narrow roll ($r)" || fail "Kata roll: $r"
}

# --- redliners: the jam on V and on an NPC, and that it clears --------------------------------------
redliners() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Redliners', 1}, {'Ammo.AO_45_Redliners', 500}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Redliners
  selfjam 1.0
  lua "$SYS:DebugSelfJam('Ammo.AO_45_Redliners'); return 1" >/dev/null; sleep 0.4
  is "the flat at 1: a shot jams V" "$(vjam)" true
  sleep 3.5
  is "V's jam clears after 3 s" "$(vjam)" false
  selfjam 0.02
  local n
  n=$(lua "local n = 0 for i = 1, 5000 do if RandF() < TweakDB:GetFlat('Ammo.AO_45_Redliners.aoSelfJam') then n = n + 1 end end return n")
  within "the shipped 2% flat, 5000 draws" "$n" 60 145

  # An NPC holding the round fires less with the flat at 1, and takes the jam itself.
  chances 1.0 0.0
  spawn 0.0 Ammo.AO_45_Redliners Character.AO_Test_Mael_Unity
  setup $UNI
  chances
  selfjam 0.0; npcshoot 99 2; local free; free=$(lua "return #RIG.volleys('NPC')")
  selfjam 1.0; npcshoot 99 2; local jammed; jammed=$(lua "return #RIG.volleys('NPC')")
  local fx; fx=$(lua "return RIG.effects('NPC', 'AmmoOverhaul.RedlinerJam')")
  selfjam 0.02
  echo "  NPC shots at V in 16 s: $free with no jam, $jammed with every shot jamming; jam applied $fx times"
  [[ $fx -ge 1 ]] && pass "an NPC's Redliners jam the NPC ($fx)" || fail "an NPC's Redliners jam the NPC: $fx"
  (( jammed < free || free == 0 )) && pass "the jam stops the NPC firing ($free -> $jammed shots)" || fail "the jam stops the NPC firing: $free -> $jammed"
  [[ $(lua "return RIG.effects('V', 'AmmoOverhaul.RedlinerJam')") == 0 ]] && pass "the NPC's jam stays on the NPC" || fail "the NPC's jam reached V"
  despawn
}

# --- swap: V jammed, then a swap to another gun with an ordinary round -----------------------------
swap() {
  kit "{'$UNI', 1}, {'$LEX', 1}, {'Items.AO_Feed_45_Redliners', 1}, {'Ammo.AO_45_Redliners', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Redliners
  # draw takes 3 s: the same effect at 14 s (WeaponMalfunction, its $base), so the swap lands inside it.
  lua "StatusEffectHelper.ApplyStatusEffect(Game.GetPlayer(), TweakDBID.new('BaseStatusEffect.WeaponMalfunction')); return 1" >/dev/null
  sleep 0.5
  is "V is jammed on the Unity" "$(vjam)" true
  draw $LEX; sleep 1
  echo "  drawn now: $(lua "return TDBID.ToStringDEBUG(ItemID.GetTDBID(Game.GetPlayer():GetActiveWeapon():GetItemID()))"), jam on V: $(vjam)"
  [[ $(vjam) == true ]] && echo "RESULT swap: the jam is on V, it stayed through the swap to a gun with another round" || echo "RESULT swap: the swap cleared the jam"
  lua "StatusEffectHelper.RemoveStatusEffect(Game.GetPlayer(), TweakDBID.new('BaseStatusEffect.WeaponMalfunction')); return 1" >/dev/null
}

# --- chrome: Chrome-cookers from an NPC on V ---------------------------------------------------------
chrome() {
  kit "{'$OMA', 1}"
  draw $OMA; draw $OMA
  lua "TweakDB:SetFlat('Ammo.AO_TLight_ChromeCookers.aoEffectChances', {1.0}); return 1" >/dev/null
  carrier Ammo.AO_TLight_ChromeCookers Character.AO_Test_Mael_Omaha $OMA
  npcshoot 2 6
  local n; n=$(lua "return RIG.effects('V', 'BaseStatusEffect.CyberwareMalfunction')")
  echo "  hits on V $(lua "return #RIG.ratios('NPC')")"
  echo "  it holds $(qty Ammo.AO_TLight_ChromeCookers), gun $(lua "return NameToString(ScriptedPuppet.GetActiveWeapon(RIG.npc()):GetWeaponRecord():FriendlyName())")"
  [[ $n -ge 1 ]] && pass "an NPC's Chrome-cookers gave V a cyberware malfunction ($n)" || fail "Chrome-cookers on V: $n"
  lua "TweakDB:SetFlat('Ammo.AO_TLight_ChromeCookers.aoEffectChances', {0.15}); return 1" >/dev/null
  kitgod; despawn
}

# Fires until the rig NPC is dead.
kill_npc() { for _ in $(seq 60); do [[ $(lua "return RIG.npc():IsDead()") == true ]] && return; [[ $(lua "return RIG.fireV()") == holstered ]] && draw $UNI; sleep 0.4; done; }

# --- roll: a faction round drops as loot -------------------------------------------------------------
roll() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Subsonic', 1}, {'Ammo.AO_45_Subsonic', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Subsonic
  chances 1.0 0.0
  # The rig respawns a plain goon when it loses sight of its NPC: only a Redliners carrier counts.
  local have=0 try
  for try in 1 2 3 4; do
    spawn 0.0 Ammo.AO_45_Redliners Character.AO_Test_Mael_Unity
    setup $UNI
    have=$(qty Ammo.AO_45_Redliners); (( have > 0 )) && break
  done
  chances
  echo "  it carries $have Redliners"
  frail "RIG.npc()" 5.0
  kill_npc; sleep 3.5
  is "the NPC died" "$(lua "return RIG.npc():IsDead()")" true
  local n; n=$(qty Ammo.AO_45_Redliners)
  [[ $n -ge 1 ]] && pass "its Redliners are on the body ($n)" || fail "Redliners on the body: $n"
  despawn
}

# --- parts: V's kill leaves the components; another round's kill doesn't ---------------------------
parts() {
  local mat=Items.RareMaterial1 n
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_PartsPullers', 1}, {'Ammo.AO_45_PartsPullers', 200}, {'Items.AO_Feed_45_Subsonic', 1}, {'Ammo.AO_45_Subsonic', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_PartsPullers
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI; frail "RIG.npc()" 5.0
  kill_npc; sleep 3.5
  is "the NPC died" "$(lua "return RIG.npc():IsDead()")" true
  is "the kill left 2 Rare components" "$(qty $mat)" 2
  despawn
  feed Items.AO_Feed_45_Subsonic
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI; frail "RIG.npc()" 5.0
  kill_npc; sleep 3.5
  is "another round's kill leaves none" "$(qty $mat)" 0
  despawn
  # A body with nothing noted: its ammo gone, it still gets the components.
  feed Items.AO_Feed_45_PartsPullers
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI; frail "RIG.npc()" 5.0
  lua "local n = RIG.npc(); local ts = Game.GetTransactionSystem()
local a = ItemID.CreateQuery(TweakDBID.new('Ammo.AO_45_Ball')); ts:RemoveItem(n, a, ts:GetItemQuantity(n, a)); return 1" >/dev/null
  kill_npc; sleep 3.5
  is "a dry NPC's kill leaves them too" "$(qty $mat)" 2
  despawn
}

# --- kansatsu: the tag, the fallback's lock, and the probe: does a tag shorten the lock? -------------
kansatsu() {
  kit "{'$YUK', 1}, {'Items.AO_Feed_10mm_Kansatsu', 1}, {'Ammo.AO_S10_Kansatsu', 300}, {'Items.AO_Feed_10mm_Seekers', 1}"
  draw $YUK; draw $YUK; feed Items.AO_Feed_10mm_Seekers
  local hip ads; hip=$(gunstat SmartGunHipTimeToLock); ads=$(gunstat SmartGunAdsTimeToLock)
  # The test save's V has no Smart Link, and no lock happens without one.
  lua "AO_LINK = RPGManager.CreateStatModifier(gamedataStatType.HasSmartLink, gameStatModifierType.Additive, 1.0)
Game.GetStatsSystem():AddModifier(Game.GetPlayer():GetEntityID(), AO_LINK); return 1" >/dev/null
  # Long enough to measure at the harness's speed.
  lua "Game.GetStatsSystem():AddModifier(Game.GetPlayer():GetActiveWeapon():GetEntityID(), RPGManager.CreateStatModifier(gamedataStatType.SmartGunHipTimeToLock, gameStatModifierType.Additive, 3.0)); return 1" >/dev/null
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Yukimura
  setup $YUK
  # The time from a look back to a full lock (state 16 as EnumInt prints gamesmartGunTargetState.Locked); $1 runs first.
  locktime() {
    lua "local p = Game.GetPlayer(); local a = p:GetWorldPosition(); Game.GetTeleportationFacility():Teleport(p, a, EulerAngles.new(0, 0, p:GetWorldYaw() + 120)); return 1" >/dev/null; sleep 6
    lua "$1; AO_T0 = EngineTime.ToFloat(Game.GetSimTime()); aim(Game.GetPlayer(), RIG.npc()); return 1" >/dev/null
    local r=""
    for _ in $(seq 40); do
      r=$(lua "aim(Game.GetPlayer(), RIG.npc()); return $SYS:DebugSmartTargets()")
      [[ $r == *state=16* ]] && break; sleep 0.1
    done
    lua "return string.format('%.2f s, tag %s: %s', EngineTime.ToFloat(Game.GetSimTime()) - AO_T0, tostring(StatusEffectSystem.ObjectHasStatusEffect(RIG.npc(), TweakDBID.new('AmmoOverhaul.PingTag'))), '$r')"
  }
  local tag="StatusEffectHelper.ApplyStatusEffect(RIG.npc(), TweakDBID.new('AmmoOverhaul.PingTag'))"
  echo "  stock lock hip $hip ads $ads"
  echo "  untagged: $(locktime "local x = 1")"
  echo "  tagged:   $(locktime "$tag")"
  echo "  untagged: $(locktime "StatusEffectHelper.RemoveStatusEffect(RIG.npc(), TweakDBID.new('AmmoOverhaul.PingTag'))")"
  echo "  tagged:   $(locktime "$tag")"
  feed Items.AO_Feed_10mm_Kansatsu
  within "Kansatsu fallback: hip lock x0.5 plus the probe's +3 (on the gun)" "$(gunstat SmartGunHipTimeToLock)" 0 9
  lua "Game.GetStatsSystem():RemoveModifier(Game.GetPlayer():GetEntityID(), AO_LINK); return 1" >/dev/null
  despawn
}

# An NPC $2 holding $1, V vulnerable, with gun $3 drawn. The rig respawns a plain goon when it loses
# sight of its NPC: only a carrier counts.
carrier() {
  local try
  for try in 1 2 3 4; do
    chances ${AO_CH:-0.0 1.0}
    spawn 0.0 "$1" "$2"
    chances
    vulnerable
    setup "$3"
    (( $(qty "$1") > 0 )) && return
  done
  fail "no NPC kept $1"
}

# --- affiliation2: the second five factions ---------------------------------------------------------
affiliation2() {
  local rec
  for rec in "Tyger TygerClaws" "Val Valentinos" "Six SixthStreet" "Mil Militech" "Animal Animals"; do
    set -- $rec
    spawn 0.0 "" "Character.AO_Test_$1_Unity"
    is "a spawned $1 rolls as $2" "$(lua "return $SYS:DebugFactionOf(RIG.npc())")" "$2"
  done
  despawn
}

# --- headfx: Santa Muerte burns on a headshot, not on the chest --------------------------------------
headfx() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_SantaMuerte', 1}, {'Ammo.AO_45_SantaMuerte', 300}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_SantaMuerte
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI
  shoot "" 12
  is "12 chest shots burn nothing" "$(lua "return RIG.effects('NPC', 'BaseStatusEffect.Burning')")" 0
  lua "RIG.slot = 'Head'; RIG.clear(); return 1" >/dev/null
  shoot "" 12 keep
  local f n; f=$(lua "return RIG.flagged('V', 'head')"); n=$(lua "return RIG.effects('NPC', 'BaseStatusEffect.Burning')")
  lua "RIG.slot = nil; return 1" >/dev/null
  echo "  head flags $f, burns $n"
  [[ ${f%/*} -ge 3 && $n -ge 1 ]] && pass "headshots burn ($f flagged, $n burns)" || fail "headshots: $f flagged, $n burns"
  despawn
}

# --- headonv: the game flags no headshots on V, so Santa Muerte burns V by aoHeadFallback -------------
headonv() {
  lua "TweakDB:SetFlat('Ammo.AO_45_SantaMuerte.aoHeadFallback', 1.0); return 1" >/dev/null
  carrier Ammo.AO_45_SantaMuerte Character.AO_Test_Val_Unity $UNI
  npcshoot 2 6
  local n; n=$(lua "return RIG.effects('V', 'BaseStatusEffect.PlayerBurning')")
  echo "  NPC hits on V flagged as headshots: $(lua "return RIG.flagged('NPC', 'head')")"
  [[ $n -ge 1 ]] && pass "an NPC's Santa Muerte burns V ($n)" || fail "burn on V: $n"
  kitgod; despawn
  lua "TweakDB:SetFlat('Ammo.AO_45_SantaMuerte.aoHeadFallback', 0.1); return 1" >/dev/null
}

# --- stops: Cease and Desist staggers by rank, once per shot, and on V ------------------------------
stops() {
  local AJA=Items.Preset_Ajax_Default CRU=Items.Preset_Crusher_Default
  is "a Normal staggers" "$(lua "return $SYS:DebugStops('Normal')")" true
  is "an Elite staggers" "$(lua "return $SYS:DebugStops('Elite')")" true
  is "a Boss doesn't" "$(lua "return $SYS:DebugStops('Boss')")" false
  is "MaxTac doesn't" "$(lua "return $SYS:DebugStops('MaxTac')")" false
  lua "TweakDB:SetFlat('Ammo.AO_762_CeaseAndDesist.aoStopChance', 1.0); TweakDB:SetFlat('Ammo.AO_12ga_CeaseAndDesist.aoStopChance', 1.0); return 1" >/dev/null
  kit "{'$AJA', 1}, {'$CRU', 1}, {'Items.AO_Feed_762_CeaseAndDesist', 1}, {'Ammo.AO_762_CeaseAndDesist', 100}, {'Items.AO_Feed_12ga_CeaseAndDesist', 1}, {'Ammo.AO_12ga_CeaseAndDesist', 50}"
  draw $AJA; draw $AJA; feed Items.AO_Feed_762_CeaseAndDesist
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $AJA
  shoot "" 3
  local n; n=$(lua "return RIG.effects('NPC', 'BaseStatusEffect.ForceStagger')")
  [[ $n -ge 1 ]] && pass "a hit staggers a Normal ($n)" || fail "Normal stagger: $n"
  despawn
  draw $CRU; draw $CRU; feed Items.AO_Feed_12ga_CeaseAndDesist
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $CRU
  lua "RIG.clear(); return 1" >/dev/null
  for _ in $(seq 30); do [[ $(lua "return RIG.fireV()") == fired ]] && break; sleep 0.3; done
  sleep 2
  echo "  pellets landed $(lua "return #RIG.ratios('V')")"
  is "one blast staggers once" "$(lua "return RIG.effects('NPC', 'BaseStatusEffect.ForceStagger')")" 1
  despawn
  stopv
  lua "TweakDB:SetFlat('Ammo.AO_762_CeaseAndDesist.aoStopChance', 0.3); TweakDB:SetFlat('Ammo.AO_12ga_CeaseAndDesist.aoStopChance', 0.3); return 1" >/dev/null
}

stopv() {
  local AJA=Items.Preset_Ajax_Default
  kit "{'$AJA', 1}"
  draw $AJA; draw $AJA
  lua "TweakDB:SetFlat('Ammo.AO_762_CeaseAndDesist.aoStopChance', 1.0); return 1" >/dev/null
  carrier Ammo.AO_762_CeaseAndDesist Character.AO_Test_Mil_Ajax $AJA
  npcshoot 2 6
  local n; n=$(lua "return RIG.effects('V', 'BaseStatusEffect.BlockBroken')")
  echo "  hits on V $(lua "return #RIG.ratios('NPC')")"
  [[ $n -ge 1 ]] && pass "an NPC's Cease and Desist staggers V ($n)" || fail "stagger on V: $n"
  is "V never gets the NPC stagger" "$(lua "return RIG.effects('V', 'BaseStatusEffect.ForceStagger')")" 0
  kitgod; despawn
}

# --- legs: Leg Day cripples a Normal, staggers an Elite, floors V ------------------------------------
legs() {
  local NOV=Items.Preset_Nova_Default
  is "a Normal is crippled" "$(lua "return $SYS:DebugLegEffect('Normal', false)")" AmmoOverhaul.CrippledLegs
  is "a Normal android staggers" "$(lua "return $SYS:DebugLegEffect('Normal', true)")" BaseStatusEffect.ForceStagger
  is "an Elite staggers" "$(lua "return $SYS:DebugLegEffect('Elite', false)")" BaseStatusEffect.ForceStagger
  is "a Boss staggers" "$(lua "return $SYS:DebugLegEffect('Boss', false)")" BaseStatusEffect.ForceStagger
  is "V goes down" "$(lua "return $SYS:DebugLegEffect('', false)")" BaseStatusEffect.Knockdown
  lua "TweakDB:SetFlat('Ammo.AO_12mm_LegDay.aoLegChance', 1.0); return 1" >/dev/null
  kit "{'$NOV', 1}, {'Items.AO_Feed_12mm_LegDay', 1}, {'Ammo.AO_12mm_LegDay', 100}"
  draw $NOV; draw $NOV; feed Items.AO_Feed_12mm_LegDay
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $NOV
  shoot "" 2
  local n; n=$(lua "return RIG.effects('NPC', 'AmmoOverhaul.CrippledLegs')")
  [[ $n -ge 1 ]] && pass "a live hit cripples a Normal ($n)" || fail "cripple: $n"
  is "its legs are out" "$(lua "return Game.GetStatsSystem():GetStatValue(RIG.npc():GetEntityID(), gamedataStatType.CanUseLegs)")" 0
  within "the cripple wears off" "$(lua "local r = -1; for _, e in ipairs(Game.GetStatusEffectSystem():GetAppliedEffects(RIG.npc():GetEntityID())) do if e:GetRecord():GetID().hash == TweakDBID.new('AmmoOverhaul.CrippledLegs').hash then r = e:GetRemainingDuration() end end return string.format('%.0f', r)")" 30 60
  despawn
  carrier Ammo.AO_12mm_LegDay Character.AO_Test_Animal_Nova $NOV
  npcshoot 2 6
  n=$(lua "return RIG.effects('V', 'BaseStatusEffect.Knockdown')")
  echo "  hits on V $(lua "return #RIG.ratios('NPC')")"
  [[ $n -ge 1 ]] && pass "an NPC's Leg Day floors V ($n)" || fail "V knockdown: $n"
  is "V is never crippled" "$(lua "return RIG.effects('V', 'AmmoOverhaul.CrippledLegs')")" 0
  kitgod; despawn
  lua "TweakDB:SetFlat('Ammo.AO_12mm_LegDay.aoLegChance', 0.2); return 1" >/dev/null
}

# --- third batch ---------------------------------------------------------------------------------
affiliation3() {
  local rec
  for rec in "Barghest Barghest" "VDB VoodooBoys" "Wraith Wraiths" "Nomad Aldecaldos" "Mox TheMox" "NCPD NCPD" "Kang KangTao" "NUSA NUSA"; do
    set -- $rec
    spawn 0.0 "" "Character.AO_Test_$1_Unity"
    is "a spawned $1 rolls as $2" "$(lua "return $SYS:DebugFactionOf(RIG.npc())")" "$2"
  done
  despawn
  is "Wraith androids are Wraiths" "$(lua "return TweakDB:GetFlat('AmmoOverhaul.factionOf.WraithsAndroid')")" Wraiths
  is "Myers' NUSA is NUSA" "$(lua "return TweakDB:GetFlat('AmmoOverhaul.factionOf.NUSA_Myers')")" NUSA
}

rolls3() {
  local r
  r=$(lua "return $SYS:DebugFactionPick('Smart_10', 'Elite', 'VoodooBoys', 8000)")
  within "an Elite VDB's 10mm rolls Collect Call about 3%" "$(share "$r" CollectCall)" 2 4
  r=$(lua "return $SYS:DebugFactionPick('Smart_10', 'Boss', 'VoodooBoys', 8000)")
  within "a Boss VDB's 10mm rolls Collect Call about 10%" "$(share "$r" CollectCall)" 8 12
  within "and Bad Juju after it" "$(share "$r" BadJuju)" 10 15.5
  r=$(lua "return $SYS:DebugFactionPick('Smart_10', 'Normal', 'VoodooBoys', 8000)")
  is "a Normal VDB never rolls it" "$(share "$r" CollectCall)" 0.0
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Elite', 'NUSA', 8000)")
  within "an Elite NUSA's .45 rolls Deniable at half the Epic chance" "$(share "$r" Deniable)" 3.5 6
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Normal', 'NUSA', 8000)")
  is "a Normal NUSA rolls none" "$(share "$r" Deniable)" 0.0
  r=$(lua "return $SYS:DebugFactionPick('Power_45', 'Elite', 'Militech', 8000)")
  is "nobody else rolls NUSA rounds" "$(share "$r" Deniable)" 0.0
}

turf3() {
  local r
  r=$(lua "return $SYS:DebugTurf('Vendors.bls_ina_se5_gunsmith_01', 200)")
  is "the Aldecaldos' shop is a gun shop" "${r%%|*}" Gunsmith
  grep -q WasteNot <<<"$r" && pass "it sells Waste Not" || fail "no Waste Not: $r"
  [[ $(tr '|;' '\n' <<<"${r#*|}" | grep -v '^$' | grep -cv WasteNot) == 0 ]] && pass "and nothing else of a faction" || fail "Nomad shop: $r"
  r=$(lua "return $SYS:DebugTurf('Vendors.wat_kab_gunsmith_01', 200)")
  is "the Mox's shop is a gun shop" "${r%%|*}" Gunsmith
  [[ $(tr '|;' '\n' <<<"${r#*|}" | grep -v '^$' | grep -cvE '^Ammo\.AO_(9mm|45|12mm)_(CutOff|LastCall)=10$') == 0 ]] && pass "it sells the Mox's rounds in tens" || fail "Mox shop: $r"
  grep -q . <<<"${r#*|}" && pass "and does sell them" || fail "Mox shop is empty"
}

# What each rank gets from a rank effect, by record.
ranks3() {
  rank() { lua "return $SYS:DebugRankResult('$1', '$2', ${3:-false}, ${4:-false})"; }
  local CC=Ammo.AO_S10_CollectCall CUT=Ammo.AO_45_CutOff SAND=Ammo.AO_45_PocketSand BLACK=BaseStatusEffect.HauntedGunBlackwallUpload MAL=BaseStatusEffect.CyberwareMalfunction STAG=BaseStatusEffect.ForceStagger
  is "Collect Call kills an Elite" "$(rank $CC Elite)" $BLACK
  is "a Boss survives it" "$(rank $CC Boss)" $MAL
  is "MaxTac survives it" "$(rank $CC MaxTac)" $MAL
  is "V survives it" "$(rank $CC '')" $MAL
  is "a quest NPC survives it" "$(rank $CC Normal false true)" $MAL
  is "a machine survives it" "$(rank $CC Normal true)" $MAL
  is "Cut Off drops a Normal" "$(rank $CUT Normal)" BaseStatusEffect.Unconscious
  is "an Elite staggers" "$(rank $CUT Elite)" $STAG
  is "a quest NPC staggers" "$(rank $CUT Normal false true)" $STAG
  is "V goes down" "$(rank $CUT '')" BaseStatusEffect.Knockdown
  is "Pocket Sand blinds an Elite" "$(rank $SAND Elite)" BaseStatusEffect.ShortBlind
  is "a Boss doesn't feel it" "$(rank $SAND Boss)" "<TDBID:00000000:00>"
  is "V gets the glitch" "$(rank $SAND '')" AIQuickHackStatusEffect.HackBlind
  is "Bad Juju turns a Normal" "$(rank Ammo.AO_45_BadJuju Normal)" AmmoOverhaul.JujuMadness
  is "poison reaches V as V's poison" "$(lua "return $SYS:DebugPlayerEffect('BaseStatusEffect.HeavyPoision')")" BaseStatusEffect.PlayerPoisoned
  is "contagion too" "$(lua "return $SYS:DebugPlayerEffect('BaseStatusEffect.BaseContagionPoison')")" BaseStatusEffect.PlayerPoisoned
  is "the shock is V's shock" "$(lua "return $SYS:DebugPlayerEffect('BaseStatusEffect.Electrocuted')")" BaseStatusEffect.PlayerElectrocuted
}

# Chance flat of `ammo` set to 1 or back.
rankchance() { lua "TweakDB:SetFlat('$1.aoRankChance', $2); return 1" >/dev/null; }
# V with `gun` and the round's selector, facing `record`.
vs() { # gun selector ammo record
  kit "{'$1', 1}, {'$2', 1}, {'$3', 200}"
  draw $1; draw $1; feed $2
  spawn 0.0 "" "$4"
  setup $1
}

sand() {
  rankchance Ammo.AO_45_PocketSand 1.0
  vs $UNI Items.AO_Feed_45_PocketSand Ammo.AO_45_PocketSand Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 100.0
  shoot "" 1
  sleep 1
  local n; n=$(lua "return RIG.effects('NPC', 'BaseStatusEffect.ShortBlind')")
  [[ $n -ge 1 ]] && pass "a live hit blinds ($n)" || fail "no blind: $n"
  despawn
  AO_CH="1.0 0.0" carrier Ammo.AO_45_PocketSand Character.AO_Test_Wraith_Unity $UNI
  npcshoot 2 6
  n=$(lua "return RIG.effects('V', 'AIQuickHackStatusEffect.HackBlind')")
  echo "  hits on V $(lua "return #RIG.ratios('NPC')")"
  [[ $n -ge 1 ]] && pass "an NPC's Pocket Sand glitches V's sight ($n)" || fail "on V: $n"
  kitgod; despawn
  rankchance Ammo.AO_45_PocketSand 0.2
}

juju() {
  rankchance Ammo.AO_45_BadJuju 1.0
  vs $UNI Items.AO_Feed_45_BadJuju Ammo.AO_45_BadJuju Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 100.0
  shoot "" 1
  sleep 1
  local n; n=$(lua "return RIG.effects('NPC', 'AmmoOverhaul.JujuMadness')")
  [[ $n -ge 1 ]] && pass "a live hit turns the target ($n)" || fail "no madness: $n"
  within "it wears off inside 20 s" "$(lua "local r = -1; for _, e in ipairs(Game.GetStatusEffectSystem():GetAppliedEffects(RIG.npc():GetEntityID())) do if e:GetRecord():GetID().hash == TweakDBID.new('AmmoOverhaul.JujuMadness').hash then r = e:GetRemainingDuration() end end return r")" 1 20
  despawn
  rankchance Ammo.AO_45_BadJuju 0.15
}

cutoff() {
  rankchance Ammo.AO_45_CutOff 1.0
  vs $UNI Items.AO_Feed_45_CutOff Ammo.AO_45_CutOff Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 100.0
  shoot "" 1
  sleep 2
  is "a hit knocks a mortal Normal out" "$(lua "return RIG.effects('NPC', 'BaseStatusEffect.Unconscious') >= 1")" true
  is "it's defeated" "$(lua "return RIG.npc():IsDefeated()")" true
  despawn
  # Non-lethal without the knockout: a weak target drops, not dies.
  rankchance Ammo.AO_45_CutOff 0.0
  vs $UNI Items.AO_Feed_45_CutOff Ammo.AO_45_CutOff Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 3.0
  shoot "" 1
  sleep 2
  is "the round is non-lethal" "$(lua "return RIG.npc():IsDead()")" false
  despawn
  rankchance Ammo.AO_45_CutOff 1.0
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  vs $UNI Items.AO_Feed_45_CutOff Ammo.AO_45_CutOff Character.AO_Test_Plain_Unity
  shoot "" 2
  is "an Immortal NPC is never knocked out" "$(lua "return RIG.effects('NPC', 'BaseStatusEffect.Unconscious')")" 0
  [[ $(lua "return RIG.effects('NPC', 'BaseStatusEffect.ForceStagger')") -ge 1 ]] && pass "it staggers instead" || fail "no stagger on the Immortal NPC"
  despawn
  rankchance Ammo.AO_45_CutOff 0.15
}

lastcall() {
  local NOV=Items.Preset_Nova_Default
  rankchance Ammo.AO_12mm_LastCall 1.0
  vs $NOV Items.AO_Feed_12mm_LastCall Ammo.AO_12mm_LastCall Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 300.0
  shoot "" 1
  is "nothing at once" "$(lua "return RIG.npc():IsDefeated()")" false
  sleep 6
  is "out 4 seconds later" "$(lua "return RIG.npc():IsDefeated()")" true
  despawn
  vs $NOV Items.AO_Feed_12mm_LastCall Ammo.AO_12mm_LastCall Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 300.0
  shoot "" 1
  lua "Game.GetGodModeSystem():AddGodMode(RIG.npc():GetEntityID(), gameGodModeType.Immortal, CName.new('AO_Test')); return 1" >/dev/null
  sleep 6
  is "a quest takes the target before it lands: not out" "$(lua "return RIG.npc():IsDefeated()")" false
  [[ $(lua "return RIG.effects('NPC', 'BaseStatusEffect.ForceStagger')") -ge 1 ]] && pass "it staggers instead" || fail "no stagger on the guarded NPC"
  despawn
  carrier Ammo.AO_12mm_LastCall Character.AO_Test_Mox_Nova $NOV
  npcshoot 1 6
  sleep 5
  local n; n=$(lua "return RIG.effects('V', 'BaseStatusEffect.Knockdown')")
  echo "  hits on V $(lua "return #RIG.ratios('NPC')")"
  [[ $n -ge 1 ]] && pass "an NPC's Last Call floors V, late ($n)" || fail "V: $n"
  kitgod; despawn
  rankchance Ammo.AO_12mm_LastCall 0.15
}

collect() {
  rankchance Ammo.AO_TLight_CollectCall 1.0
  vs $OMA Items.AO_Feed_5mm_CollectCall Ammo.AO_TLight_CollectCall Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 100.0
  shoot "" 1
  sleep 3
  is "a mortal Normal dies of the call" "$(lua "return RIG.npc():IsDead()")" true
  despawn
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  vs $OMA Items.AO_Feed_5mm_CollectCall Ammo.AO_TLight_CollectCall Character.AO_Test_Plain_Unity
  shoot "" 2
  sleep 2
  is "an Immortal NPC doesn't" "$(lua "return RIG.npc():IsDead()")" false
  is "no upload on it" "$(lua "return RIG.effects('NPC', 'BaseStatusEffect.HauntedGunBlackwallUpload')")" 0
  [[ $(lua "return RIG.effects('NPC', 'BaseStatusEffect.CyberwareMalfunction')") -ge 1 ]] && pass "its cyberware fails instead" || fail "no malfunction"
  despawn
  rankchance Ammo.AO_TLight_CollectCall 0.1
}

# The plain on-hit effects, on live hits.
shock() {
  local LEX=Items.Preset_Lexington_Default
  lua "TweakDB:SetFlat('Ammo.AO_9mm_ResistingArrest.aoEffectChances', {1.0}); return 1" >/dev/null
  vs $LEX Items.AO_Feed_9mm_ResistingArrest Ammo.AO_9mm_ResistingArrest Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 100.0
  shoot "" 1
  sleep 1
  local n; n=$(lua "return RIG.effects('NPC', 'BaseStatusEffect.Electrocuted')")
  [[ $n -ge 1 ]] && pass "Resisting Arrest shocks ($n)" || fail "no shock: $n"
  despawn
  lua "TweakDB:SetFlat('Ammo.AO_9mm_ResistingArrest.aoEffectChances', {0.2}); return 1" >/dev/null
}

clap() {
  lua "TweakDB:SetFlat('Ammo.AO_TLight_TheClap.aoEffectChances', {1.0}); return 1" >/dev/null
  vs $OMA Items.AO_Feed_5mm_TheClap Ammo.AO_TLight_TheClap Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 100.0
  # A neighbour. The rig can't stand it within the cloud's 4 m, so here the cloud reaches it instead.
  lua "TweakDB:SetFlat('AmmoOverhaul.ClapCloud.range', 12.0); return 1" >/dev/null
  lua "GetMod('AOTestKit').spawn('Character.AO_Test_Plain_Unity', 1); return 1" >/dev/null
  sleep 4
  lua "local t = Game.GetDynamicEntitySystem():GetTagged('AO_Test'); Game.GetGodModeSystem():ClearGodMode(t[2]:GetEntityID(), CName.new('aorig')); return #t" | sed 's/^/  NPCs /'
  lua "Game.GetDynamicEntitySystem():GetTagged('AO_Test')[2]:SetIndividualTimeDilation(CName.new('aorig'), 0.0001, 9999.0, CName.new(''), CName.new('')); return 1" >/dev/null
  sleep 0.5
  local r=""
  for _ in 1 2 3 4 5 6 7 8; do
    lua "return RIG.fireV()" >/dev/null; sleep 0.4
    r=$(lua "local r, t = {}, Game.GetDynamicEntitySystem():GetTagged('AO_Test'); local a = t[1]:GetWorldPosition(); for _, o in ipairs(t) do r[#r + 1] = tostring(StatusEffectSystem.ObjectHasStatusEffect(o, TweakDBID.new('BaseStatusEffect.BaseContagionPoison'))) .. '@' .. string.format('%.1f', Vector4.Distance(a, o:GetWorldPosition())) end return table.concat(r, ' ')")
    echo "  $r"
    [[ $r == true*\ true* ]] && break
  done
  [[ $r == true*\ true* ]] && pass "The Clap poisons and spreads" || fail "The Clap: $r"
  despawn
  lua "TweakDB:SetFlat('Ammo.AO_TLight_TheClap.aoEffectChances', {0.2}); TweakDB:SetFlat('AmmoOverhaul.ClapCloud.range', 4.0); return 1" >/dev/null
}

wastenot() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_WasteNot', 1}, {'Ammo.AO_45_WasteNot', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_WasteNot
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI
  shoot "" 3
  gun() { lua "return tostring(Game.GetPlayer():GetActiveWeapon():GetAmmoCount())"; }
  mag() { lua "return tostring(WeaponObject.GetMagazineAmmoCount(Game.GetPlayer():GetActiveWeapon()))"; }
  pocket() { lua "return Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), ItemID.CreateQuery(TweakDBID.new('Ammo.AO_45_WasteNot')))"; }
  local m p; m=$(mag); p=$(pocket)
  lua "$SYS:DebugRefund('Ammo.AO_45_WasteNot'); return 1" >/dev/null; sleep 1
  is "a free shot goes back in the magazine" "$(mag)" $((m + 1))
  is "and in the pocket" "$(pocket)" $((p + 1))
  despawn
  lua "TweakDB:SetFlat('Ammo.AO_45_WasteNot.aoFreeShot', 1.0); return 1" >/dev/null
  AO_CH="1.0 0.0" carrier Ammo.AO_45_WasteNot Character.AO_Test_Nomad_Unity $UNI
  local before; before=$(qty Ammo.AO_45_WasteNot)
  npcshoot 3 4
  echo "  hits on V $(lua "return #RIG.ratios('NPC')")"
  is "an NPC's free shots use no rounds" "$(qty Ammo.AO_45_WasteNot)" "$before"
  kitgod; despawn
  lua "TweakDB:SetFlat('Ammo.AO_45_WasteNot.aoFreeShot', 0.15); return 1" >/dev/null
}

speedloaders() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_Speedloaders', 1}, {'Ammo.AO_45_Speedloaders', 100}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Speedloaders
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI
  is "the refill stat is on" "$(gunstat MagazineAutoRefill)" 1.0000
  shoot "" 3
  mag() { lua "return tostring(WeaponObject.GetMagazineAmmoCount(Game.GetPlayer():GetActiveWeapon()))"; }
  cap() { lua "return tostring(WeaponObject.GetMagazineCapacity(Game.GetPlayer():GetActiveWeapon()))"; }
  pocket() { lua "return Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), ItemID.CreateQuery(TweakDBID.new('Ammo.AO_45_Speedloaders')))"; }
  local m c p; m=$(mag); c=$(cap); p=$(pocket)
  (( m < c )) && pass "the magazine is down ($m of $c)" || fail "magazine full before the swap: $m of $c"
  draw Items.Preset_Lexington_Default; sleep 2; draw $UNI; sleep 3
  is "a redraw fills it" "$(mag)" "$c"
  is "the pocket pays nothing beyond the shots" "$(pocket)" "$p"
  # Down to a few rounds: the refill can't make any.
  lua "local ts = Game.GetTransactionSystem(); local p, a = Game.GetPlayer(), ItemID.CreateQuery(TweakDBID.new('Ammo.AO_45_Speedloaders')); ts:RemoveItem(p, a, ts:GetItemQuantity(p, a) - 4); return 1" >/dev/null
  sleep 1; shoot "" 1; m=$(mag); p=$(pocket); echo "  before the swap: mag $m, pocket $p"
  draw Items.Preset_Lexington_Default; sleep 2; draw $UNI; sleep 3
  echo "  after: mag $(mag), pocket $(pocket)"
  (( $(mag) <= $p )) && pass "the magazine holds no more than V carries" || fail "free rounds: mag $(mag), pocket $p"
  despawn
}

tax() {
  local LEX=Items.Preset_Lexington_Default
  vs $LEX Items.AO_Feed_9mm_DogtownTax Ammo.AO_9mm_DogtownTax Character.AO_Test_Plain_Unity
  frail "RIG.npc()" 5.0
  for _ in $(seq 60); do [[ $(lua "return RIG.npc():IsDead()") == true ]] && break; [[ $(lua "return RIG.fireV()") == holstered ]] && draw $LEX; sleep 0.4; done
  sleep 3.5
  is "the NPC died" "$(lua "return RIG.npc():IsDead()")" true
  within "the kill left the tax" "$(qty Items.money)" 100 100000
  despawn
}

chimera() {
  local AJA=Items.Preset_Ajax_Default
  kit "{'$AJA', 1}, {'Items.AO_Feed_762_ChimeraScrap', 1}, {'Ammo.AO_762_ChimeraScrap', 100}, {'Items.AO_Feed_762_Ball', 1}, {'Ammo.AO_762_Ball', 100}"
  draw $AJA; draw $AJA
  atk() { lua "return $SYS:DebugCurrentAttack(Game.GetPlayer():GetActiveWeapon())"; }
  feed Items.AO_Feed_762_Ball
  local plain now; plain=$(atk)
  feed Items.AO_Feed_762_ChimeraScrap
  now=$(atk)
  echo "  attack $plain then $now"
  [[ $now == *Chimera* ]] && pass "the round changes V's attack" || fail "attack: $now"
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $AJA
  shoot "" 1
  sleep 1
  volleys() { lua "local t = {}; for _, v in ipairs(RIG.volleys('$1')) do t[#t + 1] = v.n .. ':' .. string.format('%.0f', v.total) end return table.concat(t, ' ')"; }
  echo "  V's shots (hits:damage): $(volleys V)"
  lua "local t = {}; for _, h in ipairs(RIG.hits) do if h.byV then t[#t + 1] = string.format('%.1f/%s', h.post, tostring(h.onNpc)) end end return table.concat(t, ' ')" | sed 's/^/  raw hits: /'
  draw $UNI; sleep 1; draw $AJA; sleep 1
  is "a holster keeps it" "$(atk)" "$now"
  despawn
  feed Items.AO_Feed_762_Ball
  is "another round puts the attack back" "$(atk)" "$plain"
  feed Items.AO_Feed_762_ChimeraScrap
  carrier Ammo.AO_762_ChimeraScrap Character.AO_Test_Barghest_Ajax $AJA
  echo "  NPC attack $(lua "return $SYS:DebugCurrentAttack(ScriptedPuppet.GetActiveWeapon(RIG.npc()))")"
  npcshoot 2 6
  local g; g=$(lua "local n, m = 0, 0; for _, h in ipairs(RIG.hits) do if h.onV and not h.byV and not h.dot then n = n + 1; if h.post < 5 then m = m + 1 end end end return n .. ' ' .. m")
  echo "  NPC's shots (hits:damage): $(volleys NPC); hits and small hits: $g"
  [[ ${g#* } -ge 1 ]] && pass "an NPC's shot blasts V too" || fail "no blast from the NPC: $g"
  kitgod; despawn
}

deniable() {
  vs $UNI Items.AO_Feed_45_Deniable Ammo.AO_45_Deniable Character.AO_Test_Plain_Unity
  avg() { lua "local s, n = 0, 0; for _, h in ipairs(RIG.hits) do if h.byV and h.onNpc and not h.dot then s = s + h.post; n = n + 1 end end return string.format('%.1f', s / math.max(n, 1))"; }
  is "the rig's NPC is in combat" "$(lua "return NPCPuppet.IsInCombat(RIG.npc())")" true
  shoot "" 4
  local fight calm; fight=$(avg)
  lua "RIG.clear(); return 1" >/dev/null
  for _ in 1 2 3 4; do
    lua "NPCPuppet.ChangeHighLevelState(RIG.npc(), gamedataNPCHighLevelState.Relaxed); return 1" >/dev/null; sleep 0.5
    echo "  in combat: $(lua "return NPCPuppet.IsInCombat(RIG.npc())")"
    lua "return RIG.fireV()" >/dev/null; sleep 0.6
  done
  calm=$(avg); echo "  fight $fight, calm $calm"
  within "an unaware target takes double" "$(ratio "$fight" "$calm")" 1.7 2.3
  is "kills are silent" "$(gunstat CanSilentKill)" 1.0000
  despawn
}

stats3() {
  local LEX=Items.Preset_Lexington_Default a b
  kit "{'$LEX', 1}, {'Items.AO_Feed_9mm_Ball', 1}, {'Items.AO_Feed_9mm_StandardIssue', 1}, {'Ammo.AO_9mm_StandardIssue', 50}, {'$YUK', 1}, {'Items.AO_Feed_10mm_Seekers', 1}, {'Items.AO_Feed_10mm_WideAngle', 1}, {'Ammo.AO_S10_WideAngle', 50}, {'Items.AO_Feed_10mm_SecondOpinion', 1}, {'Ammo.AO_S10_SecondOpinion', 50}"
  draw $LEX; draw $LEX; feed Items.AO_Feed_9mm_Ball
  a=$(gunstat SpreadMaxX); b=$(gunstat SpreadAdsMaxX)
  feed Items.AO_Feed_9mm_StandardIssue
  is "Standard Issue caps hip spread" "$(ratio "$a" "$(gunstat SpreadMaxX)")" 0.300
  is "and aimed" "$(ratio "$b" "$(gunstat SpreadAdsMaxX)")" 0.300
  draw $YUK; draw $YUK; feed Items.AO_Feed_10mm_Seekers
  b=$(gunstat SmartGunAdsMaxLockedTargets)
  feed Items.AO_Feed_10mm_SecondOpinion
  is "Second Opinion locks 2 more aimed" "$(gunstat SmartGunAdsMaxLockedTargets)" "$(awk "BEGIN { printf \"%.4f\", $b + 2 }")"
  is "and from the hip" "$(gunstat SmartGunHipMaxLockedTargets)" 5.0000
  feed Items.AO_Feed_10mm_Seekers
  # Whether a target 20 degrees off the crosshair locks.
  lua "AO_LINK = RPGManager.CreateStatModifier(gamedataStatType.HasSmartLink, gameStatModifierType.Additive, 1.0)
Game.GetStatsSystem():AddModifier(Game.GetPlayer():GetEntityID(), AO_LINK); RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Yukimura
  setup $YUK
  off() { lua "local p, n = Game.GetPlayer(), RIG.npc(); local a, b = p:GetWorldPosition(), n:GetWorldPosition()
Game.GetTeleportationFacility():Teleport(p, a, EulerAngles.new(0, 0, math.deg(math.atan2(-(b.x - a.x), b.y - a.y)) + 20)); return 1" >/dev/null; sleep 1.6; lua "return $SYS:DebugSmartTargets()"; }
  [[ $(off) == *targets=0* ]] && pass "stock: no lock 20 degrees off" || fail "stock locks 20 degrees off"
  feed Items.AO_Feed_10mm_WideAngle
  [[ $(off) == *targets=1* ]] && pass "Wide Angle locks 20 degrees off" || fail "Wide Angle: no lock 20 degrees off"
  lua "Game.GetStatsSystem():RemoveModifier(Game.GetPlayer():GetEntityID(), AO_LINK); return 1" >/dev/null
  despawn
}

# --- pumped: Protein Loads' kill buff, its stacks, on V and an NPC -----------------------------------
pumped() {
  local NOV=Items.Preset_Nova_Default
  stacks() { lua "local o = $1; local r = 0; for _, e in ipairs(Game.GetStatusEffectSystem():GetAppliedEffects(o:GetEntityID())) do if e:GetRecord():GetID().hash == TweakDBID.new('AmmoOverhaul.Pumped').hash then r = e:GetStackCount() end end return r"; }
  kit "{'$NOV', 1}, {'Items.AO_Feed_12mm_ProteinLoads', 1}, {'Ammo.AO_12mm_ProteinLoads', 100}"
  draw $NOV; draw $NOV; feed Items.AO_Feed_12mm_ProteinLoads
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $NOV; frail "RIG.npc()" 5.0
  local sp rb; sp=$(lua "return Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), gamedataStatType.MaxSpeed)")
  rb=$(lua "return Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetActiveWeapon():GetEntityID(), gamedataStatType.ReloadTimeBonus)")
  kill_npc; sleep 0.5
  is "a kill pumps V once" "$(stacks 'Game.GetPlayer()')" 1
  echo "  speed $sp -> $(lua "return Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), gamedataStatType.MaxSpeed)")"
  echo "  V reload bonus $(lua "return Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), gamedataStatType.ReloadTimeBonus)"), gun $rb -> $(lua "return Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetActiveWeapon():GetEntityID(), gamedataStatType.ReloadTimeBonus)")"
  lua "for _ = 1, 4 do StatusEffectHelper.ApplyStatusEffect(Game.GetPlayer(), TweakDBID.new('AmmoOverhaul.Pumped')) end return 1" >/dev/null; sleep 0.5
  is "stacks stop at 3" "$(stacks 'Game.GetPlayer()')" 3
  echo "  speed at 3 stacks $(lua "return Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), gamedataStatType.MaxSpeed)")"
  despawn
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  lua "StatusEffectHelper.ApplyStatusEffect(RIG.npc(), TweakDBID.new('AmmoOverhaul.Pumped')); return 1" >/dev/null; sleep 0.5
  is "it stacks on an NPC too" "$(stacks 'RIG.npc()')" 1
  echo "  NPC reload bonus $(lua "return Game.GetStatsSystem():GetStatValue(RIG.npc():GetEntityID(), gamedataStatType.ReloadTimeBonus)")"
  despawn
  lua "StatusEffectHelper.RemoveStatusEffect(Game.GetPlayer(), TweakDBID.new('AmmoOverhaul.Pumped')); return 1" >/dev/null
}

# --- crits: a gun's crit stats reach the roll -------------------------------------------------------
crits() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_GoldTips', 1}, {'Ammo.AO_45_GoldTips', 400}, {'Items.AO_Feed_45_Subsonic', 1}, {'Ammo.AO_45_Subsonic', 400}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_Subsonic
  local plain gold
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI
  shoot "" 80; plain=$(lua "return RIG.flagged('V', 'crit')")
  feed Items.AO_Feed_45_GoldTips
  echo "  gun crit stat $(gunstat CritChance), crit damage $(gunstat CritDamage)"
  shoot "" 80; gold=$(lua "return RIG.flagged('V', 'crit')")
  lua "RIG.npcMode = nil; return 1" >/dev/null
  echo "  crits: plain $plain, Gold Tips $gold"
  awk -v a="$plain" -v b="$gold" 'BEGIN { split(a, x, "/"); split(b, y, "/"); exit !(y[1] / y[2] - x[1] / x[2] >= 0.08) }' && pass "Gold Tips crit more" || fail "crit share: $plain against $gold"
  despawn
}

for p in "${parts[@]}"; do echo "== $p"; $p; done
lua "RIG.teardown(); return 1" >/dev/null
[[ -z "$out" ]] || { echo "${out//|/$'\n'}"; exit 1; }
