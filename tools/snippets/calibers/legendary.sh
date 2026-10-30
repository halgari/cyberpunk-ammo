#!/usr/bin/env bash
# Legendary rounds on live hits (spec docs/superpowers/specs/2026-10-29-legendary-rounds-design.md,
# "Testing"), one check per mechanism. Parts: heartseeker cookoff lockout kebab gatecrasher stacks
# (default all):
#   tools/linux/game-lock.sh tools/snippets/calibers/legendary.sh [part ...]
# Draws guns and spawns NPCs: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
source tools/linux/common.sh
parts=("$@"); (( ${#parts[@]} )) || parts=(stacks gatecrasher heartseeker lockout cookoff kebab)
SYS="Game.GetScriptableSystemsContainer():Get('AmmoOverhaul.AmmoFeedSystem')"
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; out+="FAIL $*|"; }
is() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1: got '$2', want '$3'"; }
kit() { $C "for _, i in ipairs({$1}) do Game.AddToInventory(i[1], i[2]) end return 1" >/dev/null; sleep 1; }

# --- stacks: Legendary stack sizes and the container roll ---------------------------------------
stacks() {
  is "a Legendary stack in place of 90 is 23" "$(lua "return $SYS:DebugLegendaryStack(90)")" 23
  is "a Legendary stack in place of 1 is 1" "$(lua "return $SYS:DebugLegendaryStack(1)")" 1
  local n; n=$(lua "return $SYS:DebugLegendaryRolls('Ammo.AO_9mm_Match', 100000)")
  awk -v n="$n" 'BEGIN { exit !(n >= 140 && n <= 260) }' && pass "container roll ~0.2% ($n of 100000)" || fail "container roll ~0.2%: $n of 100000"
  is "no Legendary roll for a caliber without one (4ga)" "$(lua "return $SYS:DebugLegendaryRolls('Ammo.AO_4ga_Slug', 20000)")" 0
}

# --- gatecrasher: an NPC rolled to it carries its stats on the gun ------------------------------
gatecrasher() {
  AO_TIER=0 spawn 0.0 "" Character.AO_Test_Plain_Ajax >/dev/null 2>&1 || true
  local r; r=$(lua "local npc = RIG.npc(); local w = npc and ScriptedPuppet.GetActiveWeapon(npc)
if not w then return 'no npc gun' end
local s = Game.GetStatsSystem(); local id = w:GetItemData():GetStatsObjectID()
local m = TweakDB:GetRecord('Items.AO_Feed_762_Gatecrasher'):StatModifiers()
for _, x in ipairs(m) do s:AddModifier(id, RPGManager.StatRecordToModifier(x)) end
return string.format('%.2f %.0f %.0f', s:GetStatValue(id, gamedataStatType.CanWeaponIgnoreArmor), s:GetStatValue(id, gamedataStatType.DamageFalloffDisabled), s:GetStatValue(id, gamedataStatType.TechPierceEnabled))")
  is "Gatecrasher's selector stats on an NPC's Ajax, as NpcAmmo adds them (armor ignore, no falloff, pierce)" "$r" "1.00 1 1"
}

# --- heartseeker: smart attack, smart record while fitted, lock, swap back, damage --------------
TAC=Items.Preset_Tactician_Default
heartseeker() {
  kit "{'$TAC', 1}, {'Items.AO_Feed_12ga_Heartseeker', 1}, {'Ammo.AO_12ga_Heartseeker', 200}, {'Items.AO_Feed_12ga_Buckshot', 1}, {'Ammo.ShotgunAmmo', 200}"
  local cross0; cross0=$(lua "return TDBID.ToStringDEBUG(TweakDB:GetFlat('$TAC.crosshair'))")
  draw $TAC; draw $TAC; feed Items.AO_Feed_12ga_Buckshot; feed Items.AO_Feed_12ga_Heartseeker; sleep 4
  spawn 0.0 "" Character.AO_Test_Plain_Lexington
  setup $TAC
  is "Tactician record is Smart while Heartseeker is fitted" "$(lua "return TDBID.ToStringDEBUG(TweakDB:GetFlat('$TAC.evolution'))")" WeaponEvolution.Smart
  is "Tactician crosshair is its own (the smart one crashes a redraw)" "$(lua "return TDBID.ToStringDEBUG(TweakDB:GetFlat('$TAC.crosshair'))")" "$cross0"
  local lock=""
  for _ in 1 2 3 4 5; do
    lock=$(lua "aim(Game.GetPlayer(), RIG.npc()); return $SYS:DebugSmartTargets()")
    [[ $lock == *targets=1* ]] && break; sleep 1
  done
  [[ $lock == *targets=1*lock=0.3* ]] && pass "Heartseeker locks the NPC in 0.3 s ($lock)" || fail "Heartseeker lock: $lock"
  is "V's shot is the smart attack" "$(lua "return $SYS:DebugCurrentAttack(Game.GetPlayer():GetActiveWeapon())")" Attacks.SmartBulletHigh
  shoot $TAC 3
  lua "local n = RIG.npc(); local s = 0; local c = 0
for _, h in ipairs(RIG.hits) do if h.byV and h.onNpc and not h.dot then s = s + h.post; c = c + 1 end end
return string.format('NOTE Heartseeker: %d hits on the rig NPC, %.1f damage each (after the roll)', c, c > 0 and s / c or 0)"
  [[ $(lua "return #RIG.ratios('V')") -ge 3 ]] && pass "Heartseeker slugs hit the rig NPC" || fail "Heartseeker slugs hit the rig NPC"
  feed Items.AO_Feed_12ga_Buckshot; sleep 4
  is "Tactician record back to Power after the swap" "$(lua "return TDBID.ToStringDEBUG(TweakDB:GetFlat('$TAC.evolution'))")" WeaponEvolution.Power
  [[ $(lua "return $SYS:DebugCurrentAttack(Game.GetPlayer():GetActiveWeapon())") != Attacks.SmartBulletHigh ]] && pass "Buckshot shot is not the smart attack" || fail "Buckshot still fires the smart attack"
}

# --- helpers for the parts with two NPCs or kills -----------------------------------------------
N2="Game.GetDynamicEntitySystem():GetTagged(CName.new('AO_Test2'))[1]"
RARITIES="{'Trash','Weak','Normal','Rare','Officer','Elite','Boss','MaxTac'}"
# Every hit's attack record, target and damage after the roll, from here on (CK.hits).
HOOK="if not CK then CK = { hits = {} }
  ObserveAfter('DamageSystem', 'CalculateDamageVariants', function(_, e)
    local ok, id = pcall(function() return TDBID.ToStringDEBUG(e.attackData:GetAttackDefinition():GetRecord():GetID()) end)
    table.insert(CK.hits, { id = ok and id or '?', on = e.target and e.target:GetEntityID().hash or 0,
      post = e.attackComputed:GetTotalAttackValue(gamedataStatPoolType.Health) })
  end)
end"
# Lua: how many CK hits with attack $1 landed on object expression $2.
hits_on() { lua "$HOOK local o = $2; if not o then return -1 end local c = 0
for _, h in ipairs(CK.hits) do if h.id == '$1' and h.on == o:GetEntityID().hash then c = c + 1 end end return c"; }
# Spawns $1 tagged AO_Test2, $2 m past the rig NPC on V's line and $3 m to its side, and freezes it.
second() {
  lua "local p, n = Game.GetPlayer(), RIG.npc(); local a, b = p:GetWorldPosition(), n:GetWorldPosition()
local dx, dy = b.x - a.x, b.y - a.y; local l = math.sqrt(dx * dx + dy * dy); dx, dy = dx / l, dy / l
local spec = DynamicEntitySpec.new(); spec.recordID = TweakDBID.new('$1')
spec.position = Vector4.new(b.x + dx * $2 + dy * $3, b.y + dy * $2 - dx * $3, b.z, 1)
spec.orientation = EulerAngles.ToQuat(EulerAngles.new(0, 0, math.deg(math.atan2(dx, -dy))))
spec.alwaysSpawned = true; spec.tags = { CName.new('AO_Test2') }
Game.GetDynamicEntitySystem():CreateEntity(spec); return 1" >/dev/null
  # Frozen as soon as it's there, before it walks off its spot.
  for _ in $(seq 60); do
    [[ $(lua "local n = $N2; if not n then return false end
n:SetIndividualTimeDilation(CName.new('aorig2'), 0.0001, 9999.0, CName.new(''), CName.new('')); return true") == true ]] && break
    sleep 0.3
  done
  sleep 1
  # It can still land a few metres off its spot, and NPCs' teleports don't stick.
  lua "return string.format('  second NPC %.1f m from the rig NPC', Vector4.Distance($N2:GetWorldPosition(), RIG.npc():GetWorldPosition()))" >&2
}
# Moves V onto the line from the second NPC through the rig NPC, 5 m past the rig NPC, facing it.
inline() {
  lua "local p, n, f = Game.GetPlayer(), RIG.npc(), $N2; local b, c = n:GetWorldPosition(), f:GetWorldPosition()
local dx, dy = b.x - c.x, b.y - c.y; local l = math.sqrt(dx * dx + dy * dy); dx, dy = dx / l, dy / l
Game.GetTeleportationFacility():Teleport(p, Vector4.new(b.x + dx * 5, b.y + dy * 5, p:GetWorldPosition().z, 1), EulerAngles.new(0, 0, math.deg(math.atan2(dx, -dy))))
return 1" >/dev/null
  sleep 2
}
gone2() { lua "local n = $N2; if n then Game.GetDynamicEntitySystem():DeleteEntity(n:GetEntityID()) end return 1" >/dev/null; }
# Lua: object expression $1 mortal at $2% health.
frail() { lua "local o = $1; Game.GetGodModeSystem():ClearGodMode(o:GetEntityID(), CName.new('aorig'))
Game.GetStatPoolsSystem():RequestSettingStatPoolValue(o:GetEntityID(), gamedataStatPoolType.Health, $2, nil, true); return 1" >/dev/null
  sleep 1; lua "return string.format('%.1f', Game.GetStatPoolsSystem():GetStatPoolValue(($1):GetEntityID(), gamedataStatPoolType.Health, true))"; }
# The NPC roll gives every rank its caliber's Legendary ($1 = 1.0), or puts the chances back (core.yaml).
legendary_roll() {
  if [[ $1 == on ]]; then lua "for _, r in ipairs($RARITIES) do TweakDB:SetFlat('AmmoOverhaul.npcLegendaryChance.' .. r, 1.0) end return 1" >/dev/null
  else lua "local v = { Elite = 0.03, Boss = 0.10, MaxTac = 0.10 }
for _, r in ipairs($RARITIES) do TweakDB:SetFlat('AmmoOverhaul.npcLegendaryChance.' .. r, v[r] or 0.0) end return 1" >/dev/null; fi
}
trail_count() { lua "local n = 0 for _ in string.gmatch($SYS:Trail(), '$1') do n = n + 1 end return n"; }
POOL="Game.GetStatPoolsSystem():GetStatPoolValue(Game.GetPlayer():GetEntityID(), gamedataStatPoolType.GrenadesCharges, false)"

# --- cookoff: a kill sets off one blast that hurts a neighbour; a hit on V cooks V's grenade -----
UNI=Items.Preset_Unity_Default
cookoff() {
  kit "{'$UNI', 1}, {'Items.AO_Feed_45_CookOff', 1}, {'Ammo.AO_45_CookOff', 300}, {'Items.GrenadeFragRegular', 3}"
  draw $UNI; draw $UNI; feed Items.AO_Feed_45_CookOff
  lua "$HOOK return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Unity
  setup $UNI
  # Inside the blast's 6 m: the spawn lands a few metres off its spot, so it's tried again.
  local try
  for try in 1 2 3 4; do
    second Character.AO_Test_Plain_Unity 0 1.5
    [[ $(lua "return Vector4.Distance($N2:GetWorldPosition(), RIG.npc():GetWorldPosition()) < 4.5") == true ]] && break
    [[ $try == 4 ]] || { gone2; sleep 2; }
  done
  # The neighbour at 30%: the blast (35% of max health) kills it only if it does its damage.
  local h1 h2; h1=$(frail "RIG.npc()" 30.0); h2=$(frail "$N2" 30.0)
  echo "  health set to $h1% and $h2%"
  local blasts0; blasts0=$(trail_count "cook%-off: blast")
  lua "CK.hits = {}; return 1" >/dev/null
  for _ in $(seq 40); do
    [[ $(lua "return RIG.npc():IsDead()") == true ]] && break
    [[ $(lua "return RIG.fireV()") == holstered ]] && draw $UNI
    sleep 0.4
  done
  sleep 3
  is "the rig NPC died to Cook-off" "$(lua "return RIG.npc():IsDead()")" true
  # V is invulnerable in the test save, so V's share is read off the hit: 35% of V's max health.
  local vs; vs=$(lua "$HOOK local p = Game.GetPlayer(); local d = 0
for _, h in ipairs(CK.hits) do if h.id == 'AmmoOverhaul.CookOffBlast' and h.on == p:GetEntityID().hash then d = h.post end end
return string.format('%.2f', d / Game.GetStatsSystem():GetStatValue(p:GetEntityID(), gamedataStatType.Health))")
  awk -v v="$vs" 'BEGIN { exit !(v > 0.2 && v < 0.4) }' && pass "the blast's hit on V standing ~5 m off is $vs of V's max health" || fail "the blast's hit on V: $vs of V's max health"
  lua "$HOOK local a, b = RIG.npc():GetWorldPosition(), $N2:GetWorldPosition()
local who = {} for _, h in ipairs(CK.hits) do if h.id == 'AmmoOverhaul.CookOffBlast' then
  local w = h.on == Game.GetPlayer():GetEntityID().hash and 'V' or h.on == RIG.npc():GetEntityID().hash and 'body' or h.on == $N2:GetEntityID().hash and 'neighbour' or tostring(h.on)
  table.insert(who, w .. string.format(':%.0f', h.post)) end end
return string.format('NOTE neighbour %.1f m from the body; blast hits: %s', Vector4.Distance(a, b), table.concat(who, ' '))"
  local n2; n2=$(hits_on AmmoOverhaul.CookOffBlast "$N2")
  [[ $n2 -ge 1 ]] && pass "the blast hit the NPC next to it ($n2 hit)" || fail "the blast hit the NPC next to it: $n2"
  is "the neighbour died to the blast" "$(lua "return $N2:IsDead()")" true
  is "one blast for two deaths (no chain)" "$(( $(trail_count "cook%-off: blast") - blasts0 ))" 1
  gone2; lua "GetMod('AOTestKit').despawnAll(); return 1" >/dev/null

  # An NPC's Cook-off hit on V.
  lua "local p = Game.GetPlayer(); local r = EquipRequest.new(); r.owner = p
r.itemID = ItemID.FromTDBID(TweakDBID.new('Items.GrenadeFragRegular'))
Game.GetScriptableSystemsContainer():Get('EquipmentSystem'):QueueRequest(r); return 1" >/dev/null; sleep 2
  is "V has the frag selected" "$(lua "return TDBID.ToStringDEBUG(Game.GetScriptableSystemsContainer():Get('EquipmentSystem'):GetPlayerData(Game.GetPlayer()):GetActiveGadget().id)")" Items.GrenadeFragRegular
  legendary_roll on
  spawn 0.0 Ammo.AO_45_CookOff Character.AO_Test_Plain_Unity
  legendary_roll off
  setup $UNI
  local full; full=$(lua "local s = Game.GetStatsSystem(); local id = Game.GetPlayer():GetEntityID()
Game.GetStatPoolsSystem():RequestSettingStatPoolValue(id, gamedataStatPoolType.GrenadesCharges, s:GetStatValue(id, gamedataStatType.GrenadesCharges), nil, false)
return string.format('%.0f', $POOL)")
  local cooked0; cooked0=$(trail_count "went off")
  npcshoot 1 4
  local after; after=$(lua "return string.format('%.0f', $POOL)")
  local cooked; cooked=$(( $(trail_count "went off") - cooked0 ))
  [[ $cooked -ge 1 ]] && pass "an NPC's Cook-off hit set off V's frag ($cooked)" || fail "an NPC's Cook-off hit set off V's frag: $cooked"
  awk -v a="$after" -v f="$full" 'BEGIN { exit !(a < f) }' && pass "a charge was taken ($full -> $after)" || fail "a charge was taken: $full -> $after"
  [[ $(hits_on AmmoOverhaul.CookOffBlast "Game.GetPlayer()") -ge 1 ]] && pass "the cooked frag hurt V" || fail "the cooked frag hurt V"
  lua "Game.GetStatPoolsSystem():RequestSettingStatPoolValue(Game.GetPlayer():GetEntityID(), gamedataStatPoolType.GrenadesCharges, 0.0, nil, false); return 1" >/dev/null
  cooked0=$(trail_count "went off")
  npcshoot 1 4
  is "with no charge left, a hit sets off nothing (pool $(lua "return string.format('%.0f', $POOL)"))" "$(( $(trail_count "went off") - cooked0 ))" 0
}

# --- lockout: V's hit jams the NPC's gun, an NPC's hit jams V's -------------------------------
YUK=Items.Preset_Yukimura_Default
JAM=AmmoOverhaul.LockoutJam
# V's Invulnerable (test kit) blocks debuffs: lifted for the NPC's shots (hitdata.sh does the same).
vulnerable() { lua 'local k, gm, p = GetMod("AOTestKit"), Game.GetGodModeSystem(), Game.GetPlayer():GetEntityID()
if AO_KITGOD == nil then AO_KITGOD = k.state.godMode end
k.state.godMode = false
for _, s in ipairs({"AO_TestKit", "AO_Test"}) do gm:RemoveGodMode(p, gameGodModeType.Invulnerable, CName.new(s)) end return 1' >/dev/null; }
kitgod() { lua 'local k = GetMod("AOTestKit")
if AO_KITGOD ~= nil then k.state.godMode = AO_KITGOD; AO_KITGOD = nil end
if k.state.godMode then Game.GetGodModeSystem():AddGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_TestKit")) end return 1' >/dev/null; }
lockout() {
  kit "{'$YUK', 1}, {'Items.AO_Feed_10mm_Lockout', 1}, {'Ammo.AO_S10_Lockout', 300}"
  draw $YUK; draw $YUK; feed Items.AO_Feed_10mm_Lockout
  # Immortal, not Invulnerable: vanilla gives an Invulnerable target no debuffs.
  lua "RIG.npcMode = gameGodModeType.Immortal; return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Yukimura
  setup $YUK
  shoot $YUK 3
  local n; n=$(lua "return RIG.effects('NPC', '$JAM')")
  [[ $n -ge 1 ]] && pass "V's Lockout hits jammed the NPC's gun ($n of $(lua "return #RIG.ratios('V')") hits)" || fail "V's Lockout hits jammed the NPC's gun: $n"
  lua "RIG.npcMode = nil; GetMod('AOTestKit').despawnAll(); return 1" >/dev/null
  legendary_roll on
  spawn 0.0 Ammo.AO_S10_Lockout Character.AO_Test_Plain_Yukimura
  legendary_roll off
  vulnerable
  setup $YUK
  npcshoot 2 6
  n=$(lua "return RIG.effects('V', '$JAM')")
  [[ $n -ge 1 ]] && pass "an NPC's Lockout hits jammed V's gun ($n of $(lua "return #RIG.ratios('NPC')") hits)" || fail "an NPC's Lockout hits jammed V's gun: $n"
  kitgod
}

# --- kebab: a charged shot through two NPCs in line, each one's loss recorded --------------------
OMA=Items.Preset_Omaha_Default
kebab() {
  kit "{'$OMA', 1}, {'Items.AO_Feed_5mm_Kebab', 1}, {'Ammo.AO_TLight_Kebab', 300}"
  draw $OMA; draw $OMA; feed Items.AO_Feed_5mm_Kebab
  lua "$HOOK return 1" >/dev/null
  spawn 0.0 "" Character.AO_Test_Plain_Omaha
  setup $OMA
  second Character.AO_Test_Plain_Omaha 2.0 0
  lua "Game.GetGodModeSystem():AddGodMode($N2:GetEntityID(), gameGodModeType.Invulnerable, CName.new('aorig')); CK.hits = {}; RIG.clear(); return 1" >/dev/null
  inline
  # AIWeapon.Fire reads the charge off the gun's AI blackboard: stamped fully charged before each shot.
  for _ in $(seq 60); do
    [[ $(lua "return #RIG.ratios('V')") -ge 4 ]] && break
    local f; f=$(lua "local w = Game.GetPlayer():GetActiveWeapon(); if not w then return 'holstered' end
local bb, d, t = w:GetAIBlackboard(), GetAllBlackboardDefs().AIShooting, EngineTime.ToFloat(Game.GetSimTime())
bb:SetFloat(d.chargeStartTimeStamp, t - 2.0); bb:SetFloat(d.maxChargedTimeStamp, t - 1.0)
return RIG.fireV()")
    [[ $f == holstered ]] && draw $OMA
    sleep 0.5
  done
  local r; r=$(lua "local near, far = RIG.npc():GetEntityID().hash, $N2:GetEntityID().hash
local a, b = {}, {}
for _, h in ipairs(CK.hits) do if h.on == near then table.insert(a, h.post) elseif h.on == far then table.insert(b, h.post) end end
local function avg(t) local s = 0 for _, v in ipairs(t) do s = s + v end return #t > 0 and s / #t or 0 end
return string.format('%d %d %.1f %.1f', #a, #b, avg(a), avg(b))")
  read -r na nb da db <<<"$r"
  echo "NOTE Kebab: near NPC $na hits at $da each, far NPC (behind it) $nb hits at $db each"
  [[ $nb -ge 1 ]] && pass "Kebab's charged shots went through the near NPC into the far one" || fail "Kebab's charged shots reached the far NPC: $nb hits"
  gone2
}

for p in "${parts[@]}"; do echo "== $p"; $p; done
lua "RIG.teardown(); return 1" >/dev/null
[[ -z "$out" ]] || { echo "${out//|/$'\n'}"; exit 1; }
