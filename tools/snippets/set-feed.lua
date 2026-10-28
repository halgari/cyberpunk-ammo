-- Installs a feed selector into the drawn gun, like the mod screen does. Set FEED first, e.g.
--   tools/linux/cet.sh "FEED='Items.AO_Feed_9mm_Mushrooms'; $(cat tools/snippets/set-feed.lua)"
-- FEED = nil removes whatever is in the feed slot named by SLOT (default the 9mm one).
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local w = p:GetActiveWeapon()
if not w then return "no active weapon" end
local slot = TweakDBID.new(SLOT or "AttachmentSlots.AO_AmmoFeed_Power_9mm")
if FEED then slot = TweakDB:GetFlat(FEED .. ".placementSlots")[1] end
local mods = Game.GetScriptableSystemsContainer():Get("ItemModificationSystem")
if not FEED then
  local r = RemoveItemPart.new()
  r.obj = p
  r.baseItem = w:GetItemID()
  r.slotToEmpty = slot
  mods:QueueRequest(r)
  return "removing feed"
end
local _, items = ts:GetItemList(p)
for _, data in ipairs(items) do
  if TDBID.ToStringDEBUG(data:GetID().id) == FEED then
    local r = InstallItemPart.new()
    r.obj = p
    r.baseItem = w:GetItemID()
    r.partToInstall = data:GetID()
    r.slotID = slot
    mods:QueueRequest(r)
    return "installing " .. FEED
  end
end
return "no " .. FEED .. " in inventory"
