-- Installs a feed selector into the drawn gun, like the mod screen does. Set FEED first, e.g.
--   tools/linux/cet.sh "FEED='Items.AO_Feed_9mm_Incendiary'; $(cat tools/snippets/set-feed.lua)"
-- FEED = nil removes whatever is in the 9mm feed slot.
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local w = p:GetActiveWeapon()
if not w then return "no active weapon" end
local slot = TweakDBID.new("AttachmentSlots.AO_AmmoFeed_Power_9mm")
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
