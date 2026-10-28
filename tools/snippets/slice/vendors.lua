-- Task 6: how vendor stock and loot split vanilla handgun ammo across the calibers and tiers.
-- (Numbers are the v1-calibers shares: 9mm 0.40, 5mm 0.15, 10mm 0.15 of handgun ammo.)
-- Part 1 (always): DebugSpread / DebugPick. Part 2 (VENDOR set, e.g. VENDOR='gunsmith'): reads
-- the stock of the vendors MarketSystem has attached near the player.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local function parse(s)
  local t, total = {}, 0
  for k, v in tostring(s):gmatch("([%w%._]+)=(%d+)") do t[k] = tonumber(v); total = total + tonumber(v) end
  return t, total
end
local function near(a, b, tol) return a and math.abs(a - b) <= tol end

local ok, res = pcall(function() return sys:DebugSpread("Ammo.HandgunAmmo", 1000, 1) end)
check("DebugSpread exists", ok, tostring(res))
if ok then
  local t, total = parse(res)
  check("spread totals 1000", total == 1000, res)
  -- Each Uncommon share is split between the caliber's two Uncommon rounds.
  for items, want in pairs({["Ammo.HandgunAmmo"]=340, ["Ammo.AO_9mm_HollowPoint+Ammo.AO_9mm_PlusP"]=60, ["Ammo.AO_TLight_Slug"]=112,
                           ["Ammo.AO_TLight_Sabot+Ammo.AO_TLight_Bricks"]=38, ["Ammo.AO_S10_Standard"]=135,
                           ["Ammo.AO_S10_Dumbfire+Ammo.AO_S10_ShortFuse"]=15}) do
    local n = 0
    for item in items:gmatch("[^+]+") do n = n + (t[item] or 0) end
    check("spread " .. items .. " ~" .. want, near(n, want, 2), tostring(n))
  end
  local t0, total0 = parse(sys:DebugSpread("Ammo.HandgunAmmo", 1000, 0))
  check("maxTier 0 totals 1000", total0 == 1000, tostring(total0))
  check("maxTier 0 has no Uncommon", not t0["Ammo.AO_9mm_HollowPoint"] and not t0["Ammo.AO_TLight_Sabot"] and not t0["Ammo.AO_S10_Dumbfire"], sys:DebugSpread("Ammo.HandgunAmmo", 1000, 0))
  local tr, totalr = parse(sys:DebugSpread("Ammo.RifleAmmo", 100, 1))
  check("rifle ammo splits into 5.56 and 7.62", totalr == 100 and (tr["Ammo.RifleAmmo"] or 0) > 0 and (tr["Ammo.AO_762_Ball"] or 0) > 0, sys:DebugSpread("Ammo.RifleAmmo", 100, 1))
end

local okp, resp = pcall(function() return sys:DebugPick("Ammo.HandgunAmmo", 0, 2000, "Power_9mm") end)
check("DebugPick exists", okp, tostring(resp))
if okp then
  local t, total = parse(resp)
  local ball = (t["Ammo.HandgunAmmo"] or 0) / math.max(total, 1)
  -- Owned bias 0.6, plus 9mm's 0.40 share of the rest: 0.76.
  check("only a 9mm gun owned: 9mm Ball ~76%", math.abs(ball - 0.76) <= 0.04, string.format("%.3f %s", ball, resp))
  check("maxTier 0 picks no Uncommon", not t["Ammo.AO_9mm_HollowPoint"] and not t["Ammo.AO_TLight_Sabot"] and not t["Ammo.AO_S10_Dumbfire"], resp)
end

if VENDOR then
  local okv, resv = pcall(function() return sys:DebugVendors() end)
  check("DebugVendors exists", okv, tostring(resv))
  if okv then
    print(resv)
    local six = {"Ammo.HandgunAmmo", "Ammo.AO_9mm_HollowPoint", "Ammo.AO_TLight_Slug", "Ammo.AO_TLight_Sabot", "Ammo.AO_S10_Standard", "Ammo.AO_S10_Dumbfire"}
    local function handgunTotal(t) local n = 0; for _, k in ipairs(six) do n = n + (t[k] or 0) end; return n end
    for line in resv:gmatch("[^\n]+") do
      local id, vtype, stock = line:match("^(%S+) (%S+) | (.*)$")
      if id then
        -- Stock saved before the mod was installed is split when the vendor's screen opens.
        -- A stock already split but not yet tracked keeps its Ball count.
        local before = parse(stock)
        local opened = parse(sys:DebugOpenVendor(id))
        if handgunTotal(opened) > 0 then
          check(id .. " stock is split once its screen opens", (opened["Ammo.AO_TLight_Slug"] or 0) > 0, sys:DebugOpenVendor(id))
          if (before["Ammo.AO_TLight_Slug"] or 0) > 0 then
            check(id .. " a split stock isn't split again", opened["Ammo.HandgunAmmo"] == before["Ammo.HandgunAmmo"], stock .. " -> " .. sys:DebugOpenVendor(id))
          end
        end
        -- Restock twice: each rebuild splits the fresh pool once, so the handgun total stays put.
        local r1 = sys:DebugRestock(id)
        local after1 = parse(r1:match("-> (.*)$"))
        local r2 = sys:DebugRestock(id)
        local after2 = parse(r2:match("-> (.*)$"))
        local isGun = vtype:find("Gunsmith") ~= nil
        if handgunTotal(after1) > 0 then
          for _, k in ipairs(six) do
            local uncommon = k:find("HollowPoint") or k:find("Sabot") or k:find("Dumbfire")
            if isGun or not uncommon then
              check(id .. " stocks " .. k .. " after restock", (after1[k] or 0) > 0, r1)
            else
              check(id .. " (not a gun shop) has no " .. k, not after1[k], r1)
            end
          end
          check(id .. " second restock doesn't split twice", handgunTotal(after2) == handgunTotal(after1), handgunTotal(after1) .. " then " .. handgunTotal(after2))
          -- Bought out down to 9mm Ball, then saved and loaded: no new rounds appear.
          local reloaded = parse(sys:DebugReloadVendor(id))
          local extra = {}
          for k, v in pairs(reloaded) do if k:find("^Ammo%.AO_") then table.insert(extra, k .. "=" .. v) end end
          check(id .. " Ball-only stock isn't split again on load", #extra == 0, table.concat(extra, ","))
        end
      end
    end
  end
end
report()
