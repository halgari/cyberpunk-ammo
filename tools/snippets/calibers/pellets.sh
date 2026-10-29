#!/usr/bin/env bash
# Pellet damage on a 12ga Crusher at close range (3 m), Common vs Birdshot, NPC -> V (a Plain_Crusher
# NPC with the roll off / forced to Birdshot) and V -> NPC (V's Crusher with the Buckshot / Birdshot
# feed). Prints per shot: pellets landed, pre-roll and post-roll damage per pellet, damage per shot.
# A diagnostic for parity.sh's Birdshot check (prints numbers, no PASS/FAIL). Draws guns, spawns NPCs.
source "$(dirname "$0")/npc-lib.sh"
CRUSHER=Items.Preset_Crusher_Default
summ() { # who label
  lua "local g, last = {}, nil
for _, h in ipairs(RIG.hits) do
  if ('$1' == 'V' and h.byV and not h.onV) or ('$1' == 'NPC' and not h.byV and h.onV) then
    if last and h.t - last < 0.1 then local s = g[#g]; s.n = s.n + 1; s.pre = s.pre + h.pre; s.post = s.post + h.post
    else table.insert(g, { n = 1, pre = h.pre, post = h.post }) end
    last = h.t
  end
end
local n, pre, post = 0, 0, 0
local sizes = {}
for _, s in ipairs(g) do n = n + s.n; pre = pre + s.pre; post = post + s.post; table.insert(sizes, s.n) end
table.sort(sizes)
return string.format('$2: %d shots, %d pellets (sizes %s), per pellet pre %.2f post %.2f, per shot post %.1f', #g, n,
  table.concat(sizes, ','), n > 0 and pre / n or 0, n > 0 and post / n or 0, #g > 0 and post / #g or 0)"
}
echo "NPC -> V at 3 m"
crusher_run 0.0 "" 3 && summ NPC "NPC Common"
crusher_run 10.0 Ammo.AO_12ga_Birdshot 6 && summ NPC "NPC Birdshot"
crusher_run 10.0 Ammo.AO_12ga_Slug 1 && summ NPC "NPC Slug"
echo "V -> NPC at 3 m"
$C "for _, i in ipairs({'$CRUSHER', 'Items.AO_Feed_12ga_Birdshot', 'Items.AO_Feed_12ga_Buckshot'}) do Game.AddToInventory(i, 1) end
Game.AddToInventory('Ammo.ShotgunAmmo', 100); Game.AddToInventory('Ammo.AO_12ga_Birdshot', 100)" >/dev/null
sleep 1; draw $CRUSHER; draw $CRUSHER
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
for feedItem in Items.AO_Feed_12ga_Buckshot Items.AO_Feed_12ga_Birdshot; do
  feed $feedItem
  for _ in $(seq 8); do r=$(lua "return RIG.setup('$CRUSHER', 3)"); [[ $r == ready ]] && break; [[ $r == draw* ]] && draw $CRUSHER; sleep 3; done
  shoot $CRUSHER 24
  summ V "V ${feedItem##*_}"
done
feed Items.AO_Feed_12ga_Buckshot
lua "RIG.teardown(); return 1" >/dev/null
