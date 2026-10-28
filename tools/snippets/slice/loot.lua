-- Task 7: vanilla ammo in a loot container becomes our rounds, once per container.
-- Uses the nearest loot container (within 60 m): gives it 100 handgun and 50 rifle rounds,
-- converts, then checks a second conversion of the same container changes nothing. Each game
-- ammo item converts only into the rounds of the calibers that come from it (vanillaAmmo).
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
-- round -> the game ammo its caliber comes from
local source = {}
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local v = flat("AmmoOverhaul." .. c, "vanillaAmmo")
  v = type(v) == "string" and v or str(v)
  for _, a in ipairs(flat("AmmoOverhaul." .. c, "selectorAmmo") or {}) do source[type(a) == "string" and a or str(a)] = v end
end
source["Ammo.HandgunAmmo"], source["Ammo.RifleAmmo"] = "Ammo.HandgunAmmo", "Ammo.RifleAmmo"
local function stock(o)
  local t = {}
  local _, items = ts:GetItemList(o)
  for _, it in ipairs(items or {}) do
    local n = str(it:GetID().id)
    if n:find("^Ammo%.") then t[n] = (t[n] or 0) + it:GetQuantity() end
  end
  return t
end
local function from(t, vanilla) local n = 0; for k, v in pairs(t) do if source[k] == vanilla then n = n + v end end; return n end
local function show(t) local s = {}; for k, v in pairs(t) do table.insert(s, k .. "=" .. v) end; return table.concat(s, ";") end

local q = TSQ_ALL(); q.maxDistance = 60; q.testedSet = TargetingSet.Complete; q.searchFilter = TSF_All(TSFMV.Obj_Other)
local _, parts = Game.GetTargetingSystem():GetTargetParts(p, q)
local box, best = nil, 1e9
for _, part in ipairs(parts or {}) do
  local o = part:GetComponent():GetEntity()
  if o and o:IsA("gameLootContainerBase") then
    local d = Vector4.Distance(o:GetWorldPosition(), p:GetWorldPosition())
    if d < best then box, best = o, d end
  end
end
check("found a loot container", box ~= nil, "none within 60 m")
if not box then report() return end
print(string.format("container %s at %.1f m", box:GetClassName().value, best))

ts:GiveItem(box, ItemID.FromTDBID(TweakDBID.new("Ammo.HandgunAmmo")), 100)
ts:GiveItem(box, ItemID.FromTDBID(TweakDBID.new("Ammo.RifleAmmo")), 50)
local before = stock(box)
local ok, res = pcall(function() return sys:DebugConvert(box, false) end)
check("DebugConvert exists", ok, tostring(res))
if ok then
  local after = stock(box)
  print("before " .. show(before) .. "\nafter  " .. show(after))
  for _, v in ipairs({ "Ammo.HandgunAmmo", "Ammo.RifleAmmo" }) do
    check(v .. "-sourced rounds unchanged in total", from(after, v) == from(before, v), from(before, v) .. " -> " .. from(after, v))
  end
  local foreign = {}
  for k in pairs(after) do if not before[k] and source[k] ~= "Ammo.HandgunAmmo" and source[k] ~= "Ammo.RifleAmmo" then table.insert(foreign, k) end end
  check("every new stack comes from handgun or rifle ammo", #foreign == 0, table.concat(foreign, ","))
  sys:DebugConvert(box, true)  -- marks the container converted (as the fill event does)
  ts:GiveItem(box, ItemID.FromTDBID(TweakDBID.new("Ammo.HandgunAmmo")), 30)
  local marked = stock(box)
  sys:DebugConvert(box, true)
  check("a converted container isn't converted again", show(stock(box)) == show(marked), show(marked) .. " -> " .. show(stock(box)))
end
-- Clean up what was given.
for k, v in pairs(stock(box)) do
  if source[k] then ts:RemoveItem(box, ItemID.FromTDBID(TweakDBID.new(k)), v) end
end
report()
