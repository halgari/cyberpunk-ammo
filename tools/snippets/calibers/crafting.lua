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
    local cd = flat(a, "craftingData")
    local els = cd and flat(cd, "craftingRecipe") or {}
    local e = els[1]
    local ing, n = e and str(flat(e, "ingredient")), e and flat(e, "amount")
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
report()
