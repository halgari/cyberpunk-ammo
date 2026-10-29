-- Selector sync (SelectorSync.reds): one loose selector per ammo type V holds, none at 0, fitted
-- ones left alone. One step per CET call (STEP = 0..13), driven by calibers/sync.sh, which waits
-- between steps: each step checks what the previous one's change led to, then makes the next
-- change. State between steps lives in the global SY.
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local sync = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.SelectorSyncSystem")
local mods = Game.GetScriptableSystemsContainer():Get("ItemModificationSystem")
SY = (STEP == 0) and {} or (SY or {})

local MUSH, BALL, PLUSP = "Items.AO_Feed_9mm_Mushrooms", "Items.AO_Feed_9mm_Ball", "Items.AO_Feed_9mm_PlusP"
local HP, VANILLA = "Ammo.AO_9mm_HollowPoint", "Ammo.HandgunAmmo"
local SLOT = "AttachmentSlots.AO_AmmoFeed_Power_9mm"
local TEN = { "Ammo.AO_45_PlusP", "Ammo.AO_762_PlusP", "Ammo.AO_12mm_PlusP", "Ammo.AO_127_PlusP",
  "Ammo.AO_556_PlusP", "Ammo.AO_4ga_Birdshot", "Ammo.AO_TLight_Bricks", "Ammo.AO_THeavy_Bricks",
  "Ammo.AO_S10_ShortFuse", "Ammo.AO_S25_ShortFuse" }

local function qty(ammo) return ts:GetItemQuantity(p, ItemID.FromTDBID(TweakDBID.new(ammo))) end
local function give(ammo, n) Game.AddToInventory(ammo, n) end
-- Non-stackable items (guns, selectors): AddToInventory with a count gives only one.
local function giveEach(item, n) for _ = 1, n do Game.AddToInventory(item, 1) end end
local function strip(ammo)
  local n = qty(ammo)
  if n > 0 then ts:RemoveItem(p, ItemID.FromTDBID(TweakDBID.new(ammo)), n) end
end
-- Loose copies of a selector in V's inventory, counted here (not trusting the mod's own count).
local function loose(sel)
  local n = 0
  local _, items = ts:GetItemList(p)
  for _, d in ipairs(items) do
    if str(d:GetID().id) == sel then n = n + d:GetQuantity() end
  end
  return n
end
local function debugLoose(sel)
  local ok, s = pcall(function() return sys:DebugLooseSelectors() end)
  if not ok then return nil end
  return tonumber((" " .. s):match(" " .. sel:gsub("%.", "%%.") .. "=(%d+)")) or 0
end
local function checkLoose(name, sel, want)
  local n = loose(sel)
  check(name, n == want, sel .. " loose " .. n .. ", want " .. want)
end
local function syncCount()
  local ok, n = pcall(function() return sys:DebugSyncCount() end)
  return ok and n or nil
end
-- "<selected ammo> <rounds held> <fitted part or none>" for one gun (DebugGunAmmo).
local function gunAmmo(gun)
  local ok, s = pcall(function() return sync:DebugGunAmmo(gun) end)
  if not ok then return nil, nil, nil end
  local a, n, part = s:match("^(%S+) (%-?%d+) (%S+)$")
  return a, tonumber(n), part
end
local function install(gun, sel)
  local _, items = ts:GetItemList(p)
  for _, d in ipairs(items) do
    if str(d:GetID().id) == sel then
      local r = InstallItemPart.new()
      r.obj = p; r.baseItem = gun; r.partToInstall = d:GetID(); r.slotID = TweakDBID.new(SLOT)
      mods:QueueRequest(r)
      return true
    end
  end
  return false
end
local function lexingtons()
  local out = {}
  local _, items = ts:GetItemList(p)
  for _, d in ipairs(items) do
    if str(d:GetID().id) == "Items.Preset_Lexington_Default" then table.insert(out, d:GetID()) end
  end
  return out
end
local function key(id) return tostring(id.rng_seed) .. ":" .. str(id.id) end

if STEP == 0 then
  -- Clean slate: none of the test rounds held. Note the Lexingtons already there; two new ones.
  for _, a in ipairs({ HP, "Ammo.AO_9mm_PlusP", "Ammo.AO_45_HollowPoint" }) do strip(a) end
  for _, a in ipairs(TEN) do strip(a) end
  SY.oldGuns = {}
  for _, g in ipairs(lexingtons()) do SY.oldGuns[key(g)] = true end
  giveEach("Items.Preset_Lexington_Default", 2)
  print("setup done")
elseif STEP == 1 then
  check("sync count readable", syncCount() ~= nil, "DebugSyncCount missing")
  checkLoose("ammo at 0 has no selector (Mushrooms after reset)", MUSH, 0)
  give(HP, 30)
elseif STEP == 2 then
  checkLoose("new ammo adds its selector", MUSH, 1)
  check("DebugLooseSelectors agrees", debugLoose(MUSH) == loose(MUSH), tostring(debugLoose(MUSH)) .. " vs " .. loose(MUSH))
  strip(HP)
elseif STEP == 3 then
  checkLoose("ammo at 0 removes it", MUSH, 0)
  if qty(VANILLA) < 30 then give(VANILLA, 30) end
elseif STEP == 4 then
  checkLoose("vanilla handgun ammo gives the 9mm Ball selector", BALL, 1)
  give(HP, 30)
  SY.guns = {}
  for _, g in ipairs(lexingtons()) do if not SY.oldGuns[key(g)] then table.insert(SY.guns, g) end end
  check("two new Lexingtons", #SY.guns >= 2, #SY.guns .. " new")
elseif STEP == 5 then
  checkLoose("Mushrooms selector back with the ammo", MUSH, 1)
  check("installing on gun A", SY.guns[1] and install(SY.guns[1], MUSH), "no gun or no loose selector")
elseif STEP == 6 then
  local a, _, part = gunAmmo(SY.guns[1])
  check("gun A has Mushrooms fitted", part == MUSH, tostring(part))
  checkLoose("same round on two guns: 1 loose again after fitting A", MUSH, 1)
  check("installing on gun B", SY.guns[2] and install(SY.guns[2], MUSH), "no gun or no loose selector")
elseif STEP == 7 then
  local a1 = gunAmmo(SY.guns[1])
  local a2, _, part2 = gunAmmo(SY.guns[2])
  check("same round on two guns: A loads Mushrooms", a1 == HP, tostring(a1))
  check("same round on two guns: B loads Mushrooms", a2 == HP and part2 == MUSH, tostring(a2) .. " " .. tostring(part2))
  checkLoose("fitted selectors are not counted", MUSH, 1)
  strip(HP)
elseif STEP == 8 then
  local a, n, part = gunAmmo(SY.guns[1])
  check("run out keeps the round: still fitted", part == MUSH, tostring(part))
  check("run out keeps the round: SelectedAmmo unchanged", a == HP, tostring(a))
  check("run out keeps the round: 0 rounds", n == 0, tostring(n))
  checkLoose("run out keeps the round: 0 loose", MUSH, 0)
  local r = RemoveItemPart.new()
  r.obj = p; r.baseItem = SY.guns[2]; r.slotToEmpty = TweakDBID.new(SLOT)
  mods:QueueRequest(r)
elseif STEP == 9 then
  local a, _, part = gunAmmo(SY.guns[2])
  check("removing the round loads Common", a == VANILLA and part == "none", tostring(a) .. " " .. tostring(part))
  checkLoose("removed selector of a round at 0 is cleaned up", MUSH, 0)
  strip("Ammo.AO_45_HollowPoint")
  SY.ballBefore = loose(BALL)
  giveEach(BALL, 3)
  giveEach("Items.AO_Feed_45_Mushrooms", 2)
elseif STEP == 10 then
  check("old-save cleanup: Ball held 1 before the extra 3", SY.ballBefore == 1, tostring(SY.ballBefore))
  checkLoose("old-save cleanup: duplicates trimmed to 1", BALL, 1)
  checkLoose("old-save cleanup: zero-ammo selectors removed", "Items.AO_Feed_45_Mushrooms", 0)
  SY.count = syncCount()
  for _, a in ipairs(TEN) do give(a, 20) end
elseif STEP == 11 then
  local n = syncCount()
  local d = (n and SY.count) and (n - SY.count) or nil
  check("sync count bounded (10 ammo types in one call)", d and d >= 1 and d <= 3, tostring(d))
  local missing = {}
  for _, cal in ipairs(TweakDB:GetFlat("AmmoOverhaul.calibers")) do
    local sels, ammo = TweakDB:GetFlat("AmmoOverhaul." .. cal .. ".selectors"), TweakDB:GetFlat("AmmoOverhaul." .. cal .. ".selectorAmmo")
    for i, s in ipairs(sels) do
      for _, a in ipairs(TEN) do
        if str(ammo[i]) == a and loose(str(s)) ~= 1 then table.insert(missing, str(s)) end
      end
    end
  end
  check("each of the 10 types has 1 loose selector", #missing == 0, table.concat(missing, " "))
  -- Gun A into weapon slot 1 for the mod screen; no PlusP held.
  strip("Ammo.AO_9mm_PlusP")
  local es = Game.GetScriptableSystemsContainer():Get("EquipmentSystem")
  local equip = EquipRequest.new()
  equip.owner = p; equip.itemID = SY.guns[1]; equip.slotIndex = 0
  es:QueueRequest(equip)
elseif STEP == 12 then
  checkLoose("PlusP at 0: no selector", PLUSP, 0)
  sync:DebugOpenModScreen(SY.guns[1], 0)
  print("opening mod screen")
elseif STEP == 13 then
  local ok, s = pcall(function() return sync:DebugModScreen() end)
  check("mod screen open on gun A", ok and s:find("Items.Preset_Lexington_Default", 1, true) ~= nil, tostring(s))
  check("mod screen lists Ball (held)", ok and s:match("parts [^|]*" .. BALL:gsub("%.", "%%.")) ~= nil, tostring(s))
  check("mod screen lists no PlusP before", ok and not s:find(PLUSP, 1, true), tostring(s))
  give("Ammo.AO_9mm_PlusP", 30)
elseif STEP == 14 then
  local ok, s = pcall(function() return sync:DebugModScreen() end)
  print("mod screen: " .. tostring(s))
  check("open mod screen refreshes (choice list)", ok and s:match("parts [^|]*" .. PLUSP:gsub("%.", "%%.")) ~= nil, tostring(s))
  check("open mod screen refreshes (grid)", ok and s:match("grid [^|]*" .. PLUSP:gsub("%.", "%%.")) ~= nil, tostring(s))
  Game.GetUISystem():QueueEvent(ForceCloseHubMenuEvent.new())
end
report()
