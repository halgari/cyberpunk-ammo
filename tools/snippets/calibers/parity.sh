#!/usr/bin/env bash
# NPC damage parity on live hits (hit rig, rig.lua): a 9mm Lexington ganger forced to Mushrooms
# (npcUncommonFactor flats 10, respawned until it carries Ammo.AO_9mm_HollowPoint, as slice/npcdrop.sh)
# hits V for 1.2x the roll; with the factor 0 it carries 9mm Ball and hits for the plain roll; and V's
# own Mushrooms hits on the NPC are not multiplied again. Also runs parity-ganger.lua with the ganger out, and measures the other stats
# the Uncommon, Rare and Epic selectors modify on NPC guns (parity-stats.lua; shotgun pellets via the rig's volleys).
# Draws guns and spawns an NPC: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"

# The Mushrooms ganger: its round's factor and its gun's DamagePerHit.
spawn 10.0 Ammo.AO_9mm_HollowPoint Character.AO_Test_Ganger_9mm_Mushrooms
ganger="$(tools/snippets/calibers/check.sh calibers/parity-ganger.lua 2>&1)"
out+="$(grep -E '^(PASS|FAIL)' <<<"$ganger" | tr '\n' '|')"

# Stats of an Uncommon's selector on an NPC gun (parity-stats.lua): name, character, round, selector, stats that change, stats the NPC gun has no value for.
statcase() {
  local pre="PS_NAME='$1'; PS_SEL='$4'; PS_STATS='$5'; PS_ZERO='${6:-}';"
  want=$(tr ',' '\n' <<<"$5,${6:-}" | sed '/^$/d' | wc -l)
  # A failed spawn adds its own FAIL line; a stale base from an earlier case must not be compared.
  if ! spawn 0.0 "" "$2"; then return; fi
  if [[ "$($C "AO_PS_BASE = nil; $pre PS_MODE='base'; $(cat $S/slice/common.lua $S/calibers/parity-stats.lua)" 2>&1)" != *"=> stored"* ]]; then
    out+="FAIL $1: could not read the base stats of $2|"; return
  fi
  if ! spawn ${AO_FACTOR:-10.0} "$3" "$2"; then return; fi
  res=$(PRE="$pre PS_MODE='held';" tools/snippets/calibers/check.sh calibers/parity-stats.lua 2>&1)
  lines="$(grep -E '^(PASS|FAIL)' <<<"$res")"
  out+="$(tr '\n' '|' <<<"$lines")"
  got=$(grep -c . <<<"$lines")
  (( got == want )) || out+="FAIL $1: $got stat check lines, expected $want|"
}
statcase "Dumbfires" Character.AO_Test_Plain_Yukimura Ammo.AO_S10_Dumbfire Items.AO_Feed_10mm_Dumbfires SmartGunHitProbability
statcase "Short Fuse" Character.AO_Test_Plain_Yukimura Ammo.AO_S10_ShortFuse Items.AO_Feed_10mm_ShortFuse "" MaximumRange
statcase "+P" Character.AO_Test_Plain_Lexington Ammo.AO_9mm_PlusP Items.AO_Feed_9mm_PlusP "" EffectiveRange
statcase "12ga Slugs" Character.AO_Test_Plain_Crusher Ammo.AO_12ga_Slug Items.AO_Feed_12ga_Slugs ProjectilesPerShot SpreadDefaultX,SpreadDefaultY,SpreadMaxX,SpreadMaxY,SpreadAdsDefaultX,SpreadAdsDefaultY,SpreadAdsMaxX,SpreadAdsMaxY,EffectiveRange
statcase "12ga Birdshot" Character.AO_Test_Plain_Crusher Ammo.AO_12ga_Birdshot Items.AO_Feed_12ga_Birdshot ProjectilesPerShot,HitReactionFactor SpreadDefaultX,SpreadMaxX
statcase "4ga Birdshot" Character.AO_Test_Plain_Carnage Ammo.AO_4ga_Birdshot Items.AO_Feed_4ga_Birdshot ProjectilesPerShot,HitReactionFactor
# Rare (2) and Epic (3) rounds: the roll forced to that tier (factor 100: Epic shares are as low
# as 0.005), which holds several rounds, so more spawns. Zero lists: DamagePerHit (the roll hook
# applies it), range and spread (known gap), noise and sway (NPCs have neither), pierce (NPC rail
# guns don't), lock times (NPC aim is the AI's). Not read: Hunter's hit chance (an NPC smart gun is
# at the cap, 1) and SmartGunPlayerProjectileVelocity (V's rounds only).
tiercase() { AO_TIER=$1 AO_TRIES=30 AO_FACTOR=100.0 statcase "${@:2}"; }
SPREAD=SpreadDefaultX,SpreadDefaultY,SpreadMaxX,SpreadMaxY,SpreadAdsDefaultX,SpreadAdsDefaultY,SpreadAdsMaxX,SpreadAdsMaxY
tiercase 2 "9mm Subsonic" Character.AO_Test_Plain_Lexington Ammo.AO_9mm_Subsonic Items.AO_Feed_9mm_Subsonic CanSilentKill DamagePerHit,EffectiveRange,WeaponNoise
tiercase 2 "9mm Bouncers" Character.AO_Test_Plain_Lexington Ammo.AO_9mm_Bouncers Items.AO_Feed_9mm_Bouncers RicochetChance,RicochetCount DamagePerHit
tiercase 3 "9mm Match" Character.AO_Test_Plain_Lexington Ammo.AO_9mm_Match Items.AO_Feed_9mm_Match "" SwayTraversalTime,SwaySideMaximumAngleDistance,$SPREAD
tiercase 3 "9mm Shredders" Character.AO_Test_Plain_Lexington Ammo.AO_9mm_Shredders Items.AO_Feed_9mm_Shredders HitDismembermentFactor
tiercase 2 "5mm Split Slug" Character.AO_Test_Plain_Omaha Ammo.AO_TLight_SplitSlug Items.AO_Feed_5mm_SplitSlug "" TechPierceEnabled,$SPREAD
# An NPC Omaha fires 1 but its ProjectilesPerShotBase is 3, so "the gun's own, then n" leaves Split
# Slugs at 1 and Toxic Scatter at 3 for NPCs (DESIGN.md Known gaps).
tiercase 3 "5mm Toxic Scatter" Character.AO_Test_Plain_Omaha Ammo.AO_TLight_ToxicScatter Items.AO_Feed_5mm_ToxicScatter ProjectilesPerShot $SPREAD
tiercase 2 "5mm Feedback" Character.AO_Test_Plain_Omaha Ammo.AO_TLight_Feedback Items.AO_Feed_5mm_Feedback BulletMagnetismDefaultAngle DamagePerHit
tiercase 3 "5mm DU Pen" Character.AO_Test_Plain_Omaha Ammo.AO_TLight_DUPen Items.AO_Feed_5mm_DUPen CanWeaponIgnoreArmor,TechPierceChargeLevel,TechPierceDamageFactor
tiercase 3 "5mm Superconductor" Character.AO_Test_Plain_Omaha Ammo.AO_TLight_Superconductor Items.AO_Feed_5mm_Superconductor FullAutoOnFullCharge
tiercase 3 "10mm Hunter" Character.AO_Test_Plain_Yukimura Ammo.AO_S10_Hunter Items.AO_Feed_10mm_Hunter SmartGunHipMaxLockedTargets,SmartGunAdsMaxLockedTargets SmartGunHipTimeToLock,SmartGunAdsTimeToLock
# Phases 1 and 2: an NPC Lexington shoots V (retried when the rig could not get 10 hits).
nphase() { # name lo hi flats ammo
  for _ in 1 2 3; do
    spawn $4 $5 Character.AO_Test_Plain_Lexington && setup && npcshoot 20
    [[ $(lua "return #RIG.ratios('NPC')") -ge 10 ]] && break
  done
  out+="$(verdict "$1" $2 $3)|"
}
nphase 'Mushrooms' 1.0776 1.2144 10.0 Ammo.AO_9mm_HollowPoint
nphase 'Ball (roll factor off)' 0.898 1.012 0.0 Ammo.HandgunAmmo

# Pellets: a 12ga Crusher with Birdshot lands more pellets in a shot on V than Common's 3, and
# Birdshot and Slugs deal Common's damage per shot (shots are the rig's hits within 0.1 s, at 3 m).
# Bounds 0.6..1.5: a Common NPC's pellet alternates between two damage levels 1.28 apart (5.06 and
# 6.48 before the roll, by spawn), so the ratio spreads over about 0.75..1.3 for equal shots; the
# broken ratios were 0.44 (Birdshot) and 3.7 (Slug).
# A shot's damage is the mean damage of a landed pellet times the gun's pellet count, so pellets
# that miss don't count against it.
volley() { # variable round-name pellets
  lua "local v = RIG.volleys('NPC'); local n, t, max = 0, 0, 0
for _, s in ipairs(v) do n = n + s.n; t = t + s.total; max = math.max(max, s.n) end
$1 = { shots = #v, max = max, perPellet = n > 0 and t / n or 0, shot = n > 0 and t / n * $3 or 0 }
return string.format('%d shots, up to %d pellets, %.2f per pellet, %.1f per shot', #v, max, $1.perPellet, $1.shot)"
}
if crusher_run 0.0 "" 3; then echo "  Common: $(volley AO_COMMON Common 3)" >&2; fi
if crusher_run 10.0 Ammo.AO_12ga_Birdshot 6; then echo "  Birdshot: $(volley AO_BIRD Birdshot 6)" >&2; fi
if crusher_run 10.0 Ammo.AO_12ga_Slug 1; then echo "  Slug: $(volley AO_SLUG Slug 1)" >&2; fi
out+="$(lua "local c, b = AO_COMMON, AO_BIRD
local ok = c and b and c.shots >= 3 and b.shots >= 3 and c.max <= 3 and b.max > 3
return string.format('%s Birdshot NPC shots land up to %d pellets, Common up to %d (the gun has 3)', ok and 'PASS' or 'FAIL', b and b.max or 0, c and c.max or 0)")|"
for r in "BIRD Birdshot" "SLUG Slug"; do
  set -- $r
  out+="$(lua "local c, b = AO_COMMON, AO_$1
local ratio = (c and b and c.shot > 0) and b.shot / c.shot or 0
return string.format('%s NPC $2 damage per shot %.1f is %.2f of Common %.1f (0.6..1.5)', (b and b.shots >= 3 and ratio >= 0.6 and ratio <= 1.5) and 'PASS' or 'FAIL', b and b.shot or 0, ratio, c and c.shot or 0)")|"
done

# Phase 3: V's own Mushrooms hits on a Unity target are rolled once, not multiplied by 1.2 again.
LEX=Items.Preset_Lexington_Default
$C "Game.AddToInventory('$LEX', 1); Game.AddToInventory('Items.AO_Feed_9mm_Mushrooms', 1); Game.AddToInventory('Ammo.AO_9mm_HollowPoint', 300)" >/dev/null
sleep 1; draw $LEX; draw $LEX; feed Items.AO_Feed_9mm_Mushrooms
flats 0.0
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
# Hits pile up across the attempts (V's hit counts are low now and then).
keep=""
for _ in 1 2 3 4; do
  setup $LEX
  shoot $LEX 25 $keep
  keep=keep
  [[ $(lua "return #RIG.ratios('V')") -ge 10 ]] && break
done
out+="$(lua "local v = RIG.ratios('V')
local ok = #v >= 10 and v[1] >= 0.898 and v[#v] <= 1.012
return string.format('%s %d V Mushrooms hits on the NPC in 0.898..1.012, not x1.2 again (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0)")|"
$C "FEED='Items.AO_Feed_9mm_Ball'; $(cat $S/set-feed.lua)" >/dev/null
lua "RIG.teardown(); return 1" >/dev/null
res=$(tr '|' '\n' <<<"$out" | sed '/^$/d'); echo "$res"
p=$(grep -c '^PASS' <<<"$res"); n=$(grep -c '^FAIL' <<<"$res")
# ganger 3, stat cases 19 + Rare/Epic 46, NPC hit phases 2, pellets 3, V phase 1: a chunk that printed nothing can't vanish.
EXPECT=74
(( p + n >= EXPECT )) || { echo "FAIL only $((p + n)) of $EXPECT checks reported"; n=$((n + 1)); }
echo "== parity: $p pass, $n fail"
(( n == 0 && p > 0 ))
