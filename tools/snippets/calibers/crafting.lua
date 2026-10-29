-- Crafting and disassembly records (spec docs/superpowers/specs/2026-10-29-ammo-crafting-design.md):
-- batch sizes, costs by family and tier, recipe records and items, disassembly flats, settings.
-- Static: no restart, no NPC.
--   tools/snippets/calibers/check.sh calibers/crafting.lua
local BATCH = { Power_9mm = 90, Power_45 = 90, Power_12mm = 60, Power_556 = 90, Power_762 = 90,
  Power_127 = 20, Power_12ga = 40, Power_4ga = 20, Tech_Light = 90, Tech_Heavy = 40,
  Smart_10 = 90, Smart_20 = 20, Smart_25 = 10 }
local COST = { Tech = 1, Power = 2, Smart = 4 }
local MATERIAL = { [0] = "Items.CommonMaterial1", "Items.UncommonMaterial1", "Items.RareMaterial1", "Items.EpicMaterial1" }
local DIV = { [0] = 1, 2, 3, 4 }
local function tierBatch(b, t) return math.max(1, math.floor(b / DIV[t] + 0.5)) end
local function has(list, want) for _, v in ipairs(list or {}) do if (v.value or str(v)) == want then return true end end return false end

for t = 0, 3 do check("material " .. MATERIAL[t] .. " exists", rec(MATERIAL[t]) ~= nil) end

local cost = {} -- cost[tier][family] = amount (first round seen)
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local K = "AmmoOverhaul." .. c
  local family, b = flat(K, "family"), flat(K, "craftBatch")
  check(c .. " craftBatch is " .. BATCH[c], b == BATCH[c], tostring(b))
  b = BATCH[c]
  local ammo, tiers = flat(K, "selectorAmmo") or {}, flat(K, "selectorTiers") or {}
  for i, a in ipairs(ammo) do
    local name, t = str(a), tiers[i]
    -- Cost: one element, the tier's material, the family's count.
    -- (CET can't read these foreign-key flats; the record accessors can.)
    local cd = rec(a) and rec(a):CraftingData()
    local els = cd and cd:CraftingRecipe() or {}
    local e = els[1]
    local ing, n = e and str(e:Ingredient():GetID()), e and e:Amount()
    check(name .. " costs " .. COST[family] .. " x " .. MATERIAL[t], #els == 1 and ing == MATERIAL[t] and n == COST[family],
      #els .. " elements, " .. tostring(ing) .. " x " .. tostring(n))
    cost[t] = cost[t] or {}
    if #els == 1 and cost[t][family] == nil then cost[t][family] = n end
    -- Recipe record: makes this round, the tier's batch.
    local r = flat(a, "aoRecipe")
    local res = r and r ~= "" and flat(r, "craftingResult")
    local item, amount = res and str(flat(res, "item")), res and flat(res, "amount")
    check(name .. " recipe makes " .. tierBatch(b, t), item == name and amount == tierBatch(b, t),
      tostring(r) .. ": " .. tostring(item) .. " x " .. tostring(amount))
    if t >= 1 then
      local tags = r and r ~= "" and flat(r, "tags") or {}
      check(name .. " recipe item is a Recipe hidden in the backpack", has(tags, "Recipe") and has(tags, "HideInBackpackUI"))
      local ln = r and r ~= "" and locName(r) or ""
      check(name .. " recipe item reads '...: load sheet'", ln:sub(-12) == ": load sheet" and #ln > 12, ln)
      -- Price: 10 crafted batches of the round. Prices are shown rounded up, so the round's real
      -- price is in (shown - 1, shown]; allow 2% more for the recipe's own rounding.
      local function price(id) return RPGManager.CalculateBuyPrice(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new(id)), 1.0) end
      local got, one, n = r and r ~= "" and price(r) or 0, price(name), 10 * tierBatch(b, t)
      check(name .. " recipe item costs about 10 batches", one > 0 and got >= 0.98 * n * (one - 1) and got <= 1.02 * n * one,
        got .. " vs " .. n .. " x " .. one)
    end
    -- Disassembly: Power (b, 1), Smart (b, 2), Tech (2b, 1).
    local want = ({ Power = { b, 1 }, Smart = { b, 2 }, Tech = { 2 * b, 1 } })[family]
    local sr, sg = flat(a, "aoScrapRounds"), flat(a, "aoScrapGive")
    check(name .. " breaks down " .. want[2] .. " per " .. want[1], sr == want[1] and sg == want[2], tostring(sr) .. "/" .. tostring(sg))
  end
end

for t = 0, 3 do
  local c = cost[t] or {}
  check("tier " .. t .. ": Tech < Power < Smart", c.Tech and c.Power and c.Smart and c.Tech < c.Power and c.Power < c.Smart,
    tostring(c.Tech) .. " " .. tostring(c.Power) .. " " .. tostring(c.Smart))
end

check("recipeDropFactor 0.05", math.abs((flat("AmmoOverhaul", "recipeDropFactor") or -1) - 0.05) < 1e-6)
check("recipeVendorChance 0.10", math.abs((flat("AmmoOverhaul", "recipeVendorChance") or -1) - 0.10) < 1e-6)
check("recipePriceBatches 10", flat("AmmoOverhaul", "recipePriceBatches") == 10)
-- Recipe drops: 2000 rolls on a Rare round land near recipeDropFactor (0.05); Common none. A gun
-- shop's restock lists only Uncommon and Rare recipes, about recipeVendorChance of them.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local rare = sys:DebugRecipeRolls("Ammo.AO_9mm_SteelCore", 2000) / 2000
check("a Rare round's recipe drops at about 0.05", rare >= 0.03 and rare <= 0.07, tostring(rare))
check("a Common round's recipe never drops", sys:DebugRecipeRolls("Ammo.AO_45_Ball", 500) == 0)
local listed, bad, total = 0, 0, 0
for _ = 1, 20 do
  for r in string.gmatch(sys:DebugVendorRecipes(2), "([^,]+)") do
    listed = listed + 1
    local q = str(flat(r, "quality"))
    if q ~= "Quality.Uncommon" and q ~= "Quality.Rare" then bad = bad + 1 end
  end
end
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  for _, t in ipairs(flat("AmmoOverhaul." .. c, "selectorTiers") or {}) do if t == 1 or t == 2 then total = total + 1 end end
end
local rate = listed / (20 * total)
check("gun shops list only Uncommon and Rare recipes", listed > 0 and bad == 0, bad .. " of " .. listed)
check("gun shops list about 0.10 of them", rate >= 0.07 and rate <= 0.13, tostring(rate))

report()
