-- How each game ammo item splits across the calibers that come from it (spec "Where each
-- caliber's ammo comes from"). With VENDOR set: every gun shop the save knows of, restocked,
-- splits its rifle, sniper and shotgun ammo too (slice-era saves marked them split already).
--   tools/snippets/calibers/check.sh calibers/distribution.lua   (PRE="VENDOR=true;" for vendors)
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local SHARES = {
  ["Ammo.HandgunAmmo"] = { Power_9mm = 0.40, Power_45 = 0.20, Power_12mm = 0.10, Tech_Light = 0.15, Smart_10 = 0.15 },
  ["Ammo.RifleAmmo"] = { Power_556 = 0.65, Power_762 = 0.35 },
  ["Ammo.SniperRifleAmmo"] = { Power_127 = 0.60, Tech_Heavy = 0.30, Smart_25 = 0.10 },
  ["Ammo.ShotgunAmmo"] = { Power_12ga = 0.70, Power_4ga = 0.10, Smart_20 = 0.20 },
}
local function parse(s)
  local t, total = {}, 0
  for k, v in tostring(s):gmatch("([%w%._]+)=(%d+)") do t[k] = tonumber(v); total = total + tonumber(v) end
  return t, total
end
local function rounds(cal)
  local r = {}
  for _, a in ipairs(flat("AmmoOverhaul." .. cal, "selectorAmmo") or {}) do table.insert(r, type(a) == "string" and a or str(a)) end
  return r
end
for vanilla, shares in pairs(SHARES) do
  local res = sys:DebugSpread(vanilla, 1000, 1)
  local t, total = parse(res)
  check(vanilla .. " spread totals 1000", total == 1000, res)
  for cal, share in pairs(shares) do
    local n = 0
    for _, r in ipairs(rounds(cal)) do n = n + (t[r] or 0) end
    check(vanilla .. " -> " .. cal .. " ~" .. share * 1000, math.abs(n - share * 1000) <= 3, n .. " of " .. res)
  end
  local t0 = parse(sys:DebugSpread(vanilla, 1000, 0))
  for cal in pairs(shares) do
    local uncommon = rounds(cal)[2]
    check(vanilla .. " maxTier 0 has no " .. uncommon, not t0[uncommon], tostring(t0[uncommon]))
  end
end

if VENDOR then
  local resv = sys:DebugVendors()
  local shops = 0
  for line in resv:gmatch("[^\n]+") do
    local id, vtype = line:match("^(%S+) (%S+) |")
    if id and vtype:find("Gunsmith") then
      shops = shops + 1
      sys:DebugOpenVendor(id)
      local r = sys:DebugRestock(id)
      local after = parse(r:match("-> (.*)$"))
      local found = {}
      for _, k in ipairs({ "Ammo.AO_762_Ball", "Ammo.AO_THeavy_Slug", "Ammo.AO_S25_Standard", "Ammo.AO_4ga_Buckshot", "Ammo.AO_S20_Standard" }) do
        if (after[k] or 0) > 0 then table.insert(found, k) end
      end
      local sells = (after["Ammo.RifleAmmo"] or 0) + (after["Ammo.SniperRifleAmmo"] or 0) + (after["Ammo.ShotgunAmmo"] or 0) > 0
      if sells then
        check(id .. " restock splits rifle/sniper/shotgun ammo", #found >= 3, r)
      end
    end
  end
  check("found a gun shop", shops > 0, resv)
end
report()
