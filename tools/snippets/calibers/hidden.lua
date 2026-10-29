-- Selectors are invisible everywhere except a gun's mod screen: tagged HideInBackpackUI (not
-- HideInUI), weightless, unpriced; the mod screen still lists them; the vendor sell list doesn't.
--   tools/linux/cet.sh 'Game.AddToInventory("Items.AO_Feed_9mm_Mushrooms", 1)'; sleep 3
--   tools/snippets/calibers/check.sh calibers/hidden.lua
--   tools/linux/cet.sh 'Game.GetTransactionSystem():RemoveItemByTDBID(Game.GetPlayer(), TweakDBID.new("Items.AO_Feed_9mm_Mushrooms"), 1)'
-- The first line matters: the backpack's item map picks up new items a moment after they are
-- added, so the backpack check needs a selector held before the file runs.
local function tagset(id)
  local t = {}
  for _, x in ipairs(rec(id):Tags()) do t[x.value] = true end
  return t
end
local count = 0
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  for _, sel in ipairs(flat("AmmoOverhaul." .. c, "selectors") or {}) do
    local id = str(sel)
    local t = tagset(id)
    count = count + 1
    check(id .. " tagged HideInBackpackUI", t.HideInBackpackUI == true)
    check(id .. " not HideInUI", not t.HideInUI)
    check(id .. " tagged AO_AmmoSelector + itemPart", t.AO_AmmoSelector and t.itemPart)
    check(id .. " no buy/sell price", #(flat(id, "buyPrice") or {}) == 0 and #(flat(id, "sellPrice") or {}) == 0)
  end
end
check(count .. " selectors scanned", count >= 39, tostring(count))

-- A held selector: weight 0, and it shows where it should.
local player = Game.GetPlayer()
local sel = "Items.AO_Feed_9mm_Mushrooms"
local selID = ItemID.FromTDBID(TweakDBID.new(sel))
local ts = Game.GetTransactionSystem()
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
-- What the test adds, taken out again at the end.
local added = {}
local function give(id, n)
  Game.AddToInventory(id, n)
  added[#added + 1] = { id, n }
end
give(sel, 1)
give("Ammo.HandgunAmmo", 5)
local function held(name)
  local _, list = ts:GetItemList(player)
  for _, d in ipairs(list or {}) do
    if str(ItemID.GetTDBID(d:GetID())) == name then return d end
  end
end
local data = held(sel)
check("selector is in the inventory", data ~= nil)
if data then
  local w = Game.GetStatsSystem():GetStatValue(data:GetStatsObjectID(), gamedataStatType.Weight)
  check("held selector weighs 0", w == 0, tostring(w))
  check("held selector has HideInBackpackUI", data:HasTag("HideInBackpackUI"))
  -- The backpack's filter over the player's item map (the stash drops the same tag).
  local raw = sys:DebugBackpackItems(false)
  local shown = sys:DebugBackpackItems(true)
  check("item map holds the selector (control)", raw:find(sel, 1, true) ~= nil, raw)
  check("item map holds ammo that the backpack shows (control)", shown:find("Ammo.HandgunAmmo", 1, true) ~= nil, shown)
  check("backpack filter drops the selector", shown:find(sel, 1, true) == nil, shown)
  local stash = UIInventoryItemsManager.GetStashBlacklistedTags()
  local inStash = false
  for _, t in ipairs(stash) do if t.value == "HideInBackpackUI" then inStash = true end end
  check("stash blacklist has HideInBackpackUI", inStash)

  -- Mod screen: a held Lexington's feed slot still lists it.
  give("Items.Preset_Lexington_Default", 1)
  local gun = held("Items.Preset_Lexington_Default")
  local mgr = InventoryDataManagerV2.new()
  mgr:Initialize(player)
  local found = false
  if gun then
    local slot = TweakDBID.new("AttachmentSlots.AO_AmmoFeed_Power_9mm")
    local parts = mgr:GetPlayerInventoryPartsForItem(gun:GetID(), slot)
    for _, p in ipairs(parts or {}) do
      if str(ItemID.GetTDBID(p.ID)) == sel then found = true end
    end
  end
  check("mod screen lists the selector for a Lexington", found)
end

-- Vendor sell list: the vendor screen's own list builder (wrapped GetItemsPlayerCanSellFast),
-- against a vendor record, with a selector, an ammo stack and a junk item in V's inventory.
local tried, tested = 0, 0
for _, v in ipairs(TweakDB:GetRecords("gamedataVendor_Record")) do
  local vid = str(v:GetID())
  local blocked = {}
  for _, t in ipairs(v:CustomerFilterTags()) do blocked[t.value] = true end
  local ok, list = pcall(function() return sys:DebugSellList(vid, false) end)
  if ok and list:find("Ammo.HandgunAmmo=", 1, true) and tested < 3 then
    -- Control: with the filter bypassed the same vendor lists the selector, so its absence
    -- below comes from the wrap and not from the vendor's tags or the item's price.
    local open = sys:DebugSellList(vid, true)
    if open:find(sel, 1, true) then
      tested = tested + 1
      check(vid .. " unfiltered list holds the selector (control)", true)
      check(vid .. " sell list keeps ammo", list:find("Ammo.HandgunAmmo=", 1, true) ~= nil, list)
      check(vid .. " sell list excludes the selector", not list:find("AO_Feed_", 1, true), list:match("AO_Feed_[%w_]+") or "")
    end
  end
  tried = tried + 1
end
check("vendor sell list tested on a vendor (of " .. tried .. ")", tested > 0, tostring(tested))
for _, a in ipairs(added) do ts:RemoveItemByTDBID(player, TweakDBID.new(a[1]), a[2]) end
report()
