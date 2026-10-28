-- Task 7: vanilla handgun ammo in a loot container becomes our rounds, once per container.
-- Uses the nearest loot container (within 60 m): gives it 100 handgun and 50 rifle rounds,
-- converts, then checks a second conversion of the same container changes nothing.
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local six = {["Ammo.HandgunAmmo"]=1, ["Ammo.AO_9mm_HollowPoint"]=1, ["Ammo.AO_TLight_Slug"]=1,
             ["Ammo.AO_TLight_Sabot"]=1, ["Ammo.AO_S10_Standard"]=1, ["Ammo.AO_S10_Dumbfire"]=1}
local function stock(o)
  local t = {}
  local _, items = ts:GetItemList(o)
  for _, it in ipairs(items or {}) do
    local n = str(it:GetID().id)
    if n:find("^Ammo%.") then t[n] = (t[n] or 0) + it:GetQuantity() end
  end
  return t
end
local function handgun(t) local n = 0; for k, v in pairs(t) do if six[k] then n = n + v end end; return n end
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
  check("handgun-type rounds unchanged in total", handgun(after) == handgun(before), handgun(before) .. " -> " .. handgun(after))
  check("rifle ammo untouched", after["Ammo.RifleAmmo"] == before["Ammo.RifleAmmo"], tostring(after["Ammo.RifleAmmo"]))
  local foreign = {}
  for k in pairs(after) do if not six[k] and k ~= "Ammo.RifleAmmo" and not before[k] then table.insert(foreign, k) end end
  check("every new stack is one of the six rounds", #foreign == 0, table.concat(foreign, ","))
  sys:DebugConvert(box, true)  -- marks the container converted (as the fill event does)
  ts:GiveItem(box, ItemID.FromTDBID(TweakDBID.new("Ammo.HandgunAmmo")), 30)
  local marked = stock(box)
  sys:DebugConvert(box, true)
  check("a converted container isn't converted again", show(stock(box)) == show(marked), show(marked) .. " -> " .. show(stock(box)))
end
-- Clean up what was given.
for k, v in pairs(stock(box)) do
  if six[k] or k == "Ammo.RifleAmmo" then ts:RemoveItem(box, ItemID.FromTDBID(TweakDBID.new(k)), v) end
end
report()
