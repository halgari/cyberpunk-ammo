#!/usr/bin/env bash
# Crafting and disassembly in game (spec docs/superpowers/specs/2026-10-29-ammo-crafting-design.md):
#   - the Common .45 recipe is known (once) at 90; a batch costs 2 Common components;
#   - picking up the Epic 9mm Match recipe item twice teaches it once, at 23; a batch costs 2 Epic;
#   - disassembly per full batch, in the round's tier: Power Rare 200 rounds -> 2, Smart 10mm Common
#     100 -> 2, light rail Common 360 -> 2; leftover rounds stay (50 9mm Ball -> 0, 50 kept;
#     170 .45 Ball -> 1, 80 kept); the hover preview shows one batch's yield;
#   - a weapon still breaks down as vanilla; a feed selector can't be broken down;
#   - at the ammo cap crafting is blocked.
# Requests run on the next frames, so each step queues and the next call reads. Gives V items and
# components: not while the user plays. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; out=""
H='local p, ts = Game.GetPlayer(), Game.GetTransactionSystem()
local cs = Game.GetScriptableSystemsContainer():Get("CraftingSystem")
local cb = cs:GetPlayerCraftBook()
local function id(s) return ItemID.FromTDBID(TweakDBID.new(s)) end
local function q(s) return ts:GetItemQuantity(p, id(s)) end
local function zero(s) local n = q(s); if n > 0 then ts:RemoveItem(p, id(s), n) end end
local function known(a) local n = 0; for _, r in ipairs(cb:GetCraftableItems() or {}) do if TDBID.ToStringDEBUG(r:GetID()) == a then n = n + 1 end end return n end
local function craft(a) local r = CraftItemRequest.new(); r.target = p; r.itemRecord = TweakDB:GetRecord(a); r.amount = 1
  r.bulletAmount = cb:GetRecipeData(TweakDBID.new(a)).amount; cs:QueueRequest(r) end
local function scrap(a, n) local r = DisassembleItemRequest.new(); r.target = p; r.itemID = id(a); r.amount = n; cs:QueueRequest(r) end
local MAT = { "Items.CommonMaterial1", "Items.UncommonMaterial1", "Items.RareMaterial1", "Items.EpicMaterial1" }
local function mats() local t = {}; for i, m in ipairs(MAT) do t[i] = q(m) end return t end
local function pf(ok) return ok and "PASS " or "FAIL " end'
lua() { $C -t 30 "$H
$1" 2>&1 | sed -n 's/^=> //p' | tail -1; }
step() { lua "$1" >/dev/null; sleep 2; }

# The Common .45 recipe, known once at 90; craft a batch.
step 'zero("Ammo.AO_45_Ball"); zero(MAT[1]); ts:GiveItem(p, id(MAT[1]), 2); craft("Ammo.AO_45_Ball"); return 1'
out+="$(lua 'local r = cb:GetRecipeData(TweakDBID.new("Ammo.AO_45_Ball"))
return pf(known("Ammo.AO_45_Ball") == 1 and r.amount == 90) .. "Common .45 recipe known once at 90 (" .. known("Ammo.AO_45_Ball") .. ", " .. tostring(r.amount) .. ")"')|"
out+="$(lua 'return pf(q("Ammo.AO_45_Ball") == 90 and q(MAT[1]) == 0) .. "a .45 batch makes 90 for 2 Common (" .. q("Ammo.AO_45_Ball") .. " rounds, " .. q(MAT[1]) .. " left)"')|"

# The Epic 9mm Match recipe item, picked up twice; craft a batch.
step 'Game.AddToInventory("Items.AO_Recipe_AO_9mm_Match", 1); return 1'
step 'Game.AddToInventory("Items.AO_Recipe_AO_9mm_Match", 1); zero("Ammo.AO_9mm_Match"); zero(MAT[4]); ts:GiveItem(p, id(MAT[4]), 2); return 1'
step 'craft("Ammo.AO_9mm_Match"); return 1'
out+="$(lua 'local r = cb:GetRecipeData(TweakDBID.new("Ammo.AO_9mm_Match"))
return pf(known("Ammo.AO_9mm_Match") == 1 and r.amount == 23) .. "two Match recipe items teach it once at 23 (" .. known("Ammo.AO_9mm_Match") .. ", " .. tostring(r.amount) .. ")"')|"
out+="$(lua 'return pf(q("Ammo.AO_9mm_Match") == 23 and q(MAT[4]) == 0) .. "a Match batch makes 23 for 2 Epic (" .. q("Ammo.AO_9mm_Match") .. " rounds, " .. q(MAT[4]) .. " left)"')|"

# Disassembly per full batch. Each: zero the round and materials, give, break down, read.
scrapcase() { # ammo rounds broken material-index expected label [rounds left, default rounds - broken]
  local left=${7:-$(( $2 - $3 ))}
  step "zero('$1'); for _, m in ipairs(MAT) do zero(m) end; ts:GiveItem(p, id('$1'), $2); return 1"
  step "scrap('$1', $3); return 1"
  out+="$(lua "local m = mats(); local others = 0; for i = 1, 4 do if i ~= $4 then others = others + m[i] end end
return pf(m[$4] == $5 and others == 0 and q('$1') == $left) .. '$6: $3 rounds give $5, $left left (' .. m[$4] .. ', others ' .. others .. ', ' .. q('$1') .. ' rounds left)'")|"
}
LIGHT=$(lua 'return tostring(TweakDB:GetFlat("AmmoOverhaul.Tech_Light.defaultAmmo"))')
SMART=$(lua 'return tostring(TweakDB:GetFlat("AmmoOverhaul.Smart_10.defaultAmmo"))')
scrapcase Ammo.AO_9mm_SteelCore 200 200 3 2 "Power Rare 9mm" 20
scrapcase "$SMART" 100 100 1 2 "Smart 10mm Common" 10
scrapcase "$LIGHT" 360 360 1 2 "light rail Common"
# Only full batches are broken down: leftover rounds stay in the stack.
scrapcase Ammo.HandgunAmmo 50 50 1 0 "9mm Ball under a batch" 50
scrapcase Ammo.AO_45_Ball 170 170 1 1 ".45 Ball, a batch and 80 over" 80
# The backpack's hover preview asks for 1 item: it shows what one batch gives.
out+="$(lua 'zero("Ammo.HandgunAmmo"); ts:GiveItem(p, id("Ammo.HandgunAmmo"), 10)
local res = cs:GetDisassemblyResultItems(p, id("Ammo.HandgunAmmo"), 1, {}, true)
local r = res[1]
return pf(#res == 1 and TDBID.ToStringDEBUG(r.id:GetID()) == MAT[1] and r.quantity == 1) .. "the hover preview shows a batch: 1 Common (" .. #res .. " results)"')|"

# A weapon breaks down as vanilla; a selector can't be broken down.
step 'Game.AddToInventory("Items.Preset_Lexington_Default", 1); return 1'
out+="$(lua 'local _, items = ts:GetItemListByTag(p, "Weapon")
local wid; for _, it in ipairs(items) do if TDBID.ToStringDEBUG(it:GetID().id) == "Items.Preset_Lexington_Default" then wid = it:GetID() end end
local res = wid and cs:GetDisassemblyResultItems(p, wid, 1, {}) or {}
local names = {}; for _, r in ipairs(res) do table.insert(names, TDBID.ToStringDEBUG(r.id:GetID()) .. "x" .. r.quantity) end
return pf(#res > 0) .. "a Lexington still breaks down (" .. table.concat(names, ",") .. ")"')|"
# Selectors only stay held when the sync hands them out: rounds with a selector make it do so.
step 'Game.AddToInventory("Ammo.AO_9mm_HollowPoint", 10); return 1'; sleep 2
out+="$(lua 'local _, items = ts:GetItemListByTag(p, "AO_AmmoSelector"); local yes = 0
for _, it in ipairs(items) do if cs:CanItemBeDisassembled(p, it:GetID()) then yes = yes + 1 end end
return pf(#items > 0 and yes == 0) .. "no held feed selector can be broken down (" .. yes .. " of " .. #items .. " can)"')|"

# Below the cap a batch can be crafted; at the cap it can't.
out+="$(lua 'zero("Ammo.AO_45_Ball"); zero(MAT[1]); ts:GiveItem(p, id(MAT[1]), 4)
ts:GiveItem(p, id("Ammo.AO_45_Ball"), 1); local d = ts:GetItemData(p, id("Ammo.AO_45_Ball"))
local below = cs:CanItemBeCrafted(d)
local cap = math.floor(d:GetStatValueByType(gamedataStatType.Quantity)); ts:GiveItem(p, id("Ammo.AO_45_Ball"), math.max(0, cap - 1))
local at = cs:CanItemBeCrafted(d)
zero("Ammo.AO_45_Ball"); zero(MAT[1])
return pf(below and not at) .. "a .45 batch can be crafted below the cap (" .. tostring(below) .. ") and not at it, " .. cap .. " (" .. tostring(at) .. ")"')|"

res=$(tr '|' '\n' <<<"$out" | sed '/^$/d'); echo "$res"
p=$(grep -c '^PASS' <<<"$res"); n=$(grep -c '^FAIL' <<<"$res")
EXPECT=13
(( p + n >= EXPECT )) || { echo "FAIL only $((p + n)) of $EXPECT checks reported"; n=$((n + 1)); }
echo "== crafting: $p pass, $n fail"
(( n == 0 && p > 0 ))
