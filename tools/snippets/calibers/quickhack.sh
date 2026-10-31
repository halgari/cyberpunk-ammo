#!/usr/bin/env bash
# Quickhack rounds on live hits (spec docs/superpowers/specs/2026-10-31-quickhack-rounds-design.md,
# "Testing"), one check per mechanism. Parts: effects overheat ranks guarded cloud grenade rolls drop nosheet onv shops known craft scrap (default all):
#   tools/linux/game-lock.sh tools/snippets/calibers/quickhack.sh [part ...]
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
source tools/linux/common.sh
parts=("$@"); (( ${#parts[@]} )) || parts=(effects overheat ranks guarded cloud grenade rolls drop nosheet onv shops known craft scrap)
SYS="Game.GetScriptableSystemsContainer():Get('AmmoOverhaul.AmmoFeedSystem')"
YUK=Items.Preset_Yukimura_Default; PLAIN=Character.AO_Test_Plain_Unity
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; out+="FAIL $*|"; }
is() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1: got '$2', want '$3'"; }
kit() { $C "for _, i in ipairs({$1}) do Game.AddToInventory(i[1], i[2]) end return 1" >/dev/null; sleep 1; }
frail() { lua "local o = $1; Game.GetGodModeSystem():ClearGodMode(o:GetEntityID(), CName.new('aorig'))
Game.GetStatPoolsSystem():RequestSettingStatPoolValue(o:GetEntityID(), gamedataStatPoolType.Health, $2, nil, true); return 1" >/dev/null; }
kill_npc() { for _ in $(seq 60); do [[ $(lua "return RIG.npc():IsDead()") == true ]] && return; lua "return RIG.fireV()" >/dev/null; sleep 0.4; done; }
despawn() { lua "RIG.npcMode = nil; GetMod('AOTestKit').despawnAll(); return 1" >/dev/null; sleep 1; }
rankchance() { lua "TweakDB:SetFlat('$1.aoRankChance', $2); return 1" >/dev/null; }
health() { lua "return string.format('%.1f', Game.GetStatPoolsSystem():GetStatPoolValue($1:GetEntityID(), gamedataStatPoolType.Health))"; }
has() { lua "return tostring(StatusEffectSystem.ObjectHasStatusEffect($1, TweakDBID.new('BaseStatusEffect.$2')))"; }
# The share of names matching $2 in a DebugFactionPick result $1, in percent.
share() { awk -v s="$1" -v k="$2" 'BEGIN { n = split(s, a, ";"); for (i = 1; i <= n; i++) { split(a[i], p, "=");
  t += p[2]; if (p[1] ~ k) c += p[2] } printf "%.2f", 100 * c / t }'; }
within() { awk -v v="$2" -v lo="$3" -v hi="$4" 'BEGIN { exit !(v >= lo && v <= hi) }' && pass "$1 ($2)" || fail "$1: $2 not in $3..$4"; }
hackchance() { lua "for _, r in ipairs({'Normal','Rare','Officer','Elite','Boss','MaxTac'}) do TweakDB:SetFlat('AmmoOverhaul.npcHackChance.' .. r, $1) end return 1" >/dev/null; }
hackreset() { lua "local a = {Normal=0.03, Rare=0.03, Officer=0.05, Elite=0.08, Boss=0.12, MaxTac=0.12}
for r, v in pairs(a) do TweakDB:SetFlat('AmmoOverhaul.npcHackChance.' .. r, v) end return 1" >/dev/null; }
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
  clouds() { lua "local n = 0 for _ in string.gmatch($SYS:Trail(), 'hack blast') do n = n + 1 end return n"; }
  local was blasts; was=$(clouds)
  for _ in 1 2 3 4; do lua "return RIG.fireV()" >/dev/null; sleep 0.4; done
  is "the cloud spares a quest NPC" "$(has "$NB" $poison)" false
  blasts=$(( $(clouds) - was ))
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
  blasts() { lua "local n = 0 for _ in string.gmatch($SYS:Trail(), 'hack blast') do n = n + 1 end return n"; }
  local a b c was; a=$(health "$NB"); was=$(blasts)
  # A shot can land without hurting anything and make no blast, so it's fired until one goes off.
  for _ in 1 2 3 4; do
    shoot "" 1
    sleep 1
    (( $(blasts) > was )) && break
  done
  for _ in $(seq 16); do
    b=$(health "$NB"); c=$(health "RIG.npc()")
    below "$b" 90 && below "$c" 90 && break
    sleep 0.5
  done
  echo "  target to $c, neighbour $a to $b; blasts $(( $(blasts) - was )), hits $(lua "return #RIG.ratios('V')")"
  below "$c" 90 && pass "Detonate Grenade's blast hurts the target ($c)" || fail "no blast on the target: $c"
  below "$b" "$a" && pass "it reaches the neighbour" || fail "no blast damage on the neighbour: $a to $b"
  despawn
  lua "TweakDB:SetFlat('AmmoOverhaul.HackBlast.range', 3.0); return 1" >/dev/null
  rankchance Ammo.AO_S10_HackGrenade3 0.2
}

# --- rolls: who gets what ---------------------------------------------------------------------------
rolls() {
  local r
  pick() { lua "return $SYS:DebugFactionPick('$1', '$2', '', 8000)"; }
  r=$(pick Smart_10 Normal)
  within "a Normal's 10mm rolls hack rounds about 3%" "$(share "$r" _Hack)" 2.0 4.0
  is "a Normal rolls no Epic or Legendary hack" "$(share "$r" '_Hack[A-Za-z]*[34]$')" 0.00
  r=$(pick Smart_20 Boss)
  within "a Boss's 20mm about 12% (after Legendary)" "$(share "$r" _Hack)" 8.0 14.0
  r=$(pick Smart_25 Elite)
  within "an Elite's Legendary hack is about 1 in 10 of 8%" "$(share "$r" '_Hack[A-Za-z]*4$')" 0.3 1.6
  is "a 9mm gun rolls none" "$(share "$(pick Power_9mm Boss)" _Hack)" 0.00
}

# --- drop: a netrunner's body holds hack rounds, whatever its gun -------------------------------------
drop() {
  dropped() { lua "local n = 0; local ok, items = Game.GetTransactionSystem():GetItemList(RIG.npc())
for _, it in ipairs(items) do if TDBID.ToStringDEBUG(it:GetID().id):find('_Hack') then n = n + it:GetQuantity() end end return n"; }
  hackchance 1.0
  kit "{'$YUK', 1}, {'Ammo.AO_S10_Standard', 200}"
  draw $YUK; draw $YUK
  # V's shots sometimes do nothing to a fresh spawn, so one that never dies is spawned again.
  local n dead
  for _ in 1 2 3; do
    spawn 0.0 "" Character.dtn_security_netrunner_netrunner2_lexington_ma_rare
    setup $YUK
    frail "RIG.npc()" 1.0
    kill_npc; sleep 3.5
    dead=$(lua "return tostring(RIG.npc():IsDead())")
    [[ $dead == true ]] && break
    despawn
  done
  [[ $dead == true ]] || fail "the netrunner never died"
  n=$(dropped)
  (( n >= 10 )) && pass "a netrunner drops hack rounds ($n)" || fail "netrunner drop: $n"
  despawn
  spawn 0.0 "" $PLAIN
  setup $YUK
  frail "RIG.npc()" 1.0
  kill_npc; sleep 3.5
  is "a plain NPC doesn't" "$(dropped)" 0
  despawn
  hackreset
}

# --- nosheet: a hack round never teaches a recipe from a body -----------------------------------------
nosheet() {
  is "no sheet for a hack round" "$(lua "return $SYS:DebugRecipeRolls('Ammo.AO_S10_HackOptics1', 2000)")" 0
  (( $(lua "return $SYS:DebugRecipeRolls('Ammo.AO_S10_Dumbfire', 2000)") > 0 )) && pass "a plain round's does" || fail "no sheets at all"
}

# --- onv: an NPC firing a hack round does nothing to V past the hit ------------------------------------
onv() {
  lua "for _, l in ipairs({'HackOptics1','HackOptics2','HackSonic1','HackSonic2','HackContagion1','HackContagion2','HackCyberware1','HackCyberware2','HackShort1','HackShort2','HackCripple1','HackCripple2','HackOverheat1','HackOverheat2','HackGlitch1','HackGlitch2','HackBurnout2'}) do TweakDB:SetFlat('Ammo.AO_S10_' .. l .. '.aoRankChance', 1.0) end return 1" >/dev/null
  hackchance 1.0
  kit "{'$YUK', 1}, {'Ammo.AO_S10_Standard', 200}"
  draw $YUK; draw $YUK
  spawn 0.0 "" Character.AO_Test_Plain_Yukimura
  setup $YUK
  hackreset
  npcshoot 2 6
  sleep 2
  local h; h=$(lua "return #RIG.ratios('NPC')")
  (( h >= 1 )) && pass "the NPC's hack round hit V ($h)" || fail "no hits on V"
  [[ "$($SYS_TRAIL)" -ge 1 ]] && pass "it carried a hack round" || fail "no hack round rolled"
  is "no status from it" "$(lua "local n = 0 for _ in pairs(RIG.applied.V) do n = n + 1 end return n")" 0
  despawn
}
# --- shops: gun shops to Rare, netrunner vendors to Epic, nobody Legendary ------------------------------
shops() {
  lua "TweakDB:SetFlat('AmmoOverhaul.hackShopChance', 1.0); return 1" >/dev/null
  stock() { lua "return $SYS:DebugHackStock('$1', 200)"; }
  local g n r
  g=$(stock Vendors.wat_nid_gunsmith_01); n=$(stock Vendors.wat_kab_netrunner_01); r=$(stock Vendors.wat_kab_ripperdoc_01)
  [[ $g == *_Hack*1=* || $g == *_Hack*2=* ]] && pass "a gun shop lists hack rounds" || fail "gun shop: ${g:0:80}"
  [[ ! $g =~ _Hack[A-Za-z]*[34]= ]] && pass "up to Rare" || fail "gun shop over Rare"
  [[ $n =~ _Hack[A-Za-z]*3= ]] && pass "a netrunner vendor lists Epic" || fail "netrunner vendor: ${n:0:80}"
  [[ ! $n =~ _Hack[A-Za-z]*4= ]] && pass "no Legendary" || fail "netrunner vendor sells Legendary"
  is "a ripperdoc lists none" "$r" ""
  [[ $g$n != *'!'* ]] && pass "every stack can be bought" || fail "unavailable stacks: ${n:0:80}"
  lua "TweakDB:SetFlat('AmmoOverhaul.hackShopChance', 0.5); return 1" >/dev/null
}
# --- crafting: the quickhack is an ingredient, and only one goes per batch --------------------------------
CH='local p, ts = Game.GetPlayer(), Game.GetTransactionSystem()
local cs = Game.GetScriptableSystemsContainer():Get("CraftingSystem")
local cb = cs:GetPlayerCraftBook()
local A, PR = "Ammo.AO_S10_HackOptics1", "Items.BlindLvl1Program"
local function id(s) return ItemID.FromTDBID(TweakDBID.new(s)) end
local function q(s) return ts:GetItemQuantityWithDuplicates(p, ItemID.CreateQuery(TweakDBID.new(s))) end
local function zero(s) local n = q(s); if n > 0 then ts:RemoveItemByTDBID(p, TweakDBID.new(s), n, true) end end
local function craft(n) local r = CraftItemRequest.new(); r.target = p; r.itemRecord = TweakDB:GetRecord(A); r.amount = n
  r.bulletAmount = cb:GetRecipeData(TweakDBID.new(A)).amount; cs:QueueRequest(r) end
local function hacks() local t = {}; for _, h in ipairs(RPGManager.GetPlayerQuickHackList(p)) do t[#t + 1] = TDBID.ToStringDEBUG(h) end table.sort(t); return table.concat(t, ",") end'
cl() { $C -t 30 "$CH
$1" 2>&1 | sed -n 's/^=> //p' | tail -1; }
# Holds $1 of the program and enough components, crafts a batch of $2: "<program left> <rounds>".
crafted() {
  cl "zero(PR); zero(A); zero('Items.UncommonMaterial1'); ts:GiveItem(p, id('Items.UncommonMaterial1'), 40)
for _ = 1, $1 do ts:GiveItem(p, id(PR), 1) end craft($2); return 1" >/dev/null; sleep 2
  cl "return q(PR) .. ' ' .. q(A)"
}
known() {
  is "a fresh load knows the Uncommon recipe" "$(cl 'return tostring(cb:KnowsRecipe(TweakDBID.new(A)))')" true
  is "and the Legendary one" "$(cl 'return tostring(cb:KnowsRecipe(TweakDBID.new("Ammo.AO_S10_HackOptics4")))')" true
}
craft() {
  local batch; batch=$(cl 'return CraftingSystem.GetAmmoBulletAmount(TweakDBID.new(A))')
  is "1 held, 1 craft" "$(crafted 1 1)" "0 $batch"
  is "5 held, 1 craft" "$(crafted 5 1)" "4 $batch"
  is "5 held, batch of 3" "$(crafted 5 3)" "2 $((batch * 3))"
  # The screen refuses a craft when this reads 0. A round in hand gives the call its item data.
  cl "zero(PR); zero(A); ts:GiveItem(p, id(A), 1); ts:GiveItem(p, id('Items.UncommonMaterial1'), 40); ts:GiveItem(p, id(PR), 1); return 1" >/dev/null; sleep 1
  is "1 held, the screen allows 1" "$(cl 'return cs:GetMaxCraftingAmount(ts:GetItemData(p, id(A)))')" 1
  cl "ts:GiveItem(p, id(PR), 1); return 1" >/dev/null; sleep 1
  is "2 held, the screen stops at 2" "$(cl 'return cs:GetMaxCraftingAmount(ts:GetItemData(p, id(A)))')" 2
  cl "zero(PR); return 1" >/dev/null; sleep 1
  is "none held, the screen allows none" "$(cl 'return cs:GetMaxCraftingAmount(ts:GetItemData(p, id(A)))')" 0
  local before; before=$(cl 'return hacks()'); echo "installed: ${before:0:120}"
  [[ -n $before ]] && pass "V has hacks installed" || fail "no hacks installed to check"
  crafted 1 1 >/dev/null; is "installed hacks stay, after a craft" "$(cl 'return hacks()')" "$before"
  cl "zero(PR); craft(1); return 1" >/dev/null; sleep 2
  is "installed hacks stay, with none held" "$(cl 'return hacks()')" "$before"
}
scrap() {
  cl "zero(PR); zero(A); zero('Items.UncommonMaterial1'); Game.AddToInventory(A, 300); return 1" >/dev/null; sleep 1
  cl "local r = DisassembleItemRequest.new(); r.target = p; r.itemID = id(A); r.amount = 300; cs:QueueRequest(r); return 1" >/dev/null; sleep 2
  is "breaking a box down gives no program" "$(cl 'return q(PR)')" 0
  [[ $(cl "return q('Items.UncommonMaterial1')") -gt 0 ]] && pass "and gives components" || fail "no components"
}
SYS_TRAIL="eval lua \"local n = 0 for _ in string.gmatch(\$SYS:Trail(), 'got Items.AO_Feed_10mm_Hack') do n = n + 1 end return n\""

for p in "${parts[@]}"; do echo "== $p"; $p; done
lua "RIG.teardown(); return 1" >/dev/null
[[ -z "$out" ]] || { echo "${out//|/$'\n'}"; exit 1; }
