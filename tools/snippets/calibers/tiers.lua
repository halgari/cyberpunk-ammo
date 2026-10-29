-- Blocks the game for about a minute (the roll counts): CET_T=240 FROZEN_AFTER=240 check.sh calibers/tiers.lua
-- Rare and Epic tiers (spec "Tiers: price, frequency, sources"): four tier shares per family,
-- prices x2 / x4 / x8 of the caliber's Common round, gun shops up to Rare and other vendors
-- Common only, and the NPC roll's caps and factors by rank. Static: no restart, no NPC.
--   tools/snippets/calibers/check.sh calibers/tiers.lua
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local p = Game.GetPlayer()

local SHARES = {
  Power = { 0.80, 0.14, 0.05, 0.01 },
  Tech = { 0.70, 0.22, 0.07, 0.01 },
  Smart = { 0.86, 0.10, 0.035, 0.005 },
}
for family, want in pairs(SHARES) do
  local got = flat("AmmoOverhaul.shares", family) or {}
  local sum, same = 0, #got == 4
  for i, v in ipairs(got) do
    sum = sum + v
    same = same and math.abs(v - (want[i] or -1)) < 0.0001
  end
  check(family .. " has 4 tier shares summing to 1", #got == 4 and math.abs(sum - 1) < 0.001, #got .. " shares, sum " .. sum)
  check(family .. " shares are the spec's", same, table.concat(got, " "))
end

-- Every caliber's rounds by tier, as ammo record names.
local CAL = {}
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local ammo, tiers = flat("AmmoOverhaul." .. c, "selectorAmmo") or {}, flat("AmmoOverhaul." .. c, "selectorTiers") or {}
  local byTier = { [0] = {}, {}, {}, {} }
  for i, a in ipairs(ammo) do
    local t = tiers[i]
    if byTier[t] then table.insert(byTier[t], type(a) == "string" and a or str(a)) end
  end
  CAL[c] = byTier
end

local function price(id) return RPGManager.CalculateBuyPrice(p, ItemID.FromTDBID(TweakDBID.new(id)), 1.0) end
local MULT = { 2, 4, 8 }
local priced = { 0, 0, 0 }
for c, byTier in pairs(CAL) do
  local common = byTier[0][1]
  local base = common and price(common) or 0
  for t = 1, 3 do
    for _, a in ipairs(byTier[t]) do
      local got, want = price(a), base * MULT[t]
      priced[t] = priced[t] + 1
      -- Shown prices are rounded up: the Common's real price is in (base - 1, base], so a cheap
      -- round's multiple can sit well under base * MULT (exact ratios: records.lua).
      local lo = math.min((base - 1) * MULT[t], want * 0.95) - 1
      check(a .. " costs x" .. MULT[t] .. " of " .. tostring(common), base > 0 and got >= lo and got <= math.max(want + 1, want * 1.05), got .. " vs " .. base)
    end
  end
end
check("found Uncommon rounds to price", priced[1] > 0, "none")

-- Vendors: a gun shop's cap (2) never gives an Epic; other vendors' (0) only Common.
local function tierOf(id)
  for _, byTier in pairs(CAL) do
    for t = 0, 3 do
      for _, a in ipairs(byTier[t]) do if a == id then return t end end
    end
  end
end
local function tiersIn(res)
  local seen = {}
  for k, v in tostring(res):gmatch("([%w%._]+)=(%d+)") do
    local t = tierOf(k)
    if t and tonumber(v) > 0 then seen[t] = (seen[t] or 0) + tonumber(v) end
  end
  return seen
end
local anyRare, anyEpic = false, false
for _, byTier in pairs(CAL) do
  anyRare = anyRare or #byTier[2] > 0
  anyEpic = anyEpic or #byTier[3] > 0
end
for _, vanilla in ipairs({ "Ammo.HandgunAmmo", "Ammo.RifleAmmo", "Ammo.SniperRifleAmmo", "Ammo.ShotgunAmmo" }) do
  local shop = tiersIn(sys:DebugSpread(vanilla, 100000, 2))
  check(vanilla .. " gun shop stock has no Epic", not shop[3], tostring(shop[3]))
  if anyRare then
    check(vanilla .. " gun shop stock has Rares", (shop[2] or 0) > 0, "none")
  else
    print("WAIT " .. vanilla .. " gun shop Rares: no Rare rounds yet (Task 3)")
  end
  local other = tiersIn(sys:DebugSpread(vanilla, 100000, 0))
  check(vanilla .. " other vendors only Common", not other[1] and not other[2] and not other[3], "")
  if anyEpic then
    check(vanilla .. " loot can give Epics", (tiersIn(sys:DebugSpread(vanilla, 100000, 3))[3] or 0) > 0, "none")
  end
end

-- NPC roll: no Rare or Epic below Rare rank, no Epic below Elite; Boss about twice Elite's Epics.
local function picks(rarity)
  local t = {}
  for k, v in tostring(sys:DebugTierPick("Power_9mm", rarity, 20000)):gmatch("(%d+)=(%d+)") do t[tonumber(k)] = tonumber(v) end
  return t
end
local N = {}
for _, r in ipairs({ "Trash", "Weak", "Normal", "Rare", "Officer", "Elite", "Boss" }) do N[r] = picks(r) end
for _, r in ipairs({ "Trash", "Weak", "Normal" }) do
  check(r .. " NPCs roll no Rare or Epic", not N[r][2] and not N[r][3], (N[r][2] or 0) .. " " .. (N[r][3] or 0))
  check(r .. " NPCs roll Uncommons", (N[r][1] or 0) > 0, "none")
end
for _, r in ipairs({ "Rare", "Officer" }) do
  check(r .. " NPCs roll no Epic", not N[r][3], tostring(N[r][3]))
end
-- Normal's Uncommon rate is the share (0.14); Trash's half of it.
check("Normal Uncommon rate ~0.14", math.abs((N.Normal[1] or 0) / 20000 - 0.14) < 0.015, tostring(N.Normal[1]))
check("Trash Uncommon rate ~0.07", math.abs((N.Trash[1] or 0) / 20000 - 0.07) < 0.012, tostring(N.Trash[1]))
if #CAL.Power_9mm[2] > 0 then
  check("Officer NPCs roll Rares", (N.Officer[2] or 0) > 0, "none")
  check("Elite NPCs roll Rares", (N.Elite[2] or 0) > 0, "none")
else
  print("WAIT NPC Rares: no 9mm Rare rounds yet (Task 3)")
end
if #CAL.Power_9mm[3] > 0 then
  local e, b = N.Elite[3] or 0, N.Boss[3] or 0
  check("Elite NPCs roll Epics", e > 0, "none")
  check("Boss Epics ~2x Elite's", e > 0 and b / e > 1.4 and b / e < 2.6, b .. " vs " .. e)
else
  print("WAIT NPC Epics: no 9mm Epic rounds yet (Task 4)")
end
report()
