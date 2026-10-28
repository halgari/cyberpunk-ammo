-- An Uncommon round's selector is offered as installable on a Common gun (vanilla blocks parts of
-- a higher quality than the gun). Gives a Common Kenshin and the 5mm Sleevers selector.
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local gun = ItemID.FromTDBID(TweakDBID.new("Items.Preset_Kenshin_Default"))
ts:GiveItem(p, gun, 1)
ts:GiveItem(p, ItemID.FromTDBID(TweakDBID.new("Items.AO_Feed_5mm_Sleevers")), 1)
local gunQ = RPGManager.GetItemDataQuality(ts:GetItemData(p, gun))
check("test gun is below Uncommon", gunQ == gamedataQuality.Common, tostring(gunQ))
local m = InventoryDataManagerV2.new()
m:Initialize(p)
local items = m:GetPlayerInventoryPartsForItem(gun, TweakDBID.new("AttachmentSlots.AO_AmmoFeed_Tech_Light"))
local found = false
for _, it in ipairs(items) do
  if str(InventoryItemData.GetID(it).id) == "Items.AO_Feed_5mm_Sleevers" then
    found = true
    check("Sleevers installable on a Common Kenshin", InventoryItemData.IsRequirementMet(it), "requirement not met")
  end
end
check("Sleevers offered for the Kenshin's feed slot", found, "not in list")
-- Install it the way the mod screen does; rarity2.lua checks the result a moment later.
local slot = TweakDBID.new("AttachmentSlots.AO_AmmoFeed_Tech_Light")
local r = InstallItemPart.new()
r.obj = p
r.baseItem = gun
r.partToInstall = ItemID.FromTDBID(TweakDBID.new("Items.AO_Feed_5mm_Sleevers"))
for _, data in ipairs(select(2, ts:GetItemList(p))) do
  if str(data:GetID().id) == "Items.AO_Feed_5mm_Sleevers" then r.partToInstall = data:GetID() end
end
r.slotID = slot
Game.GetScriptableSystemsContainer():Get("ItemModificationSystem"):QueueRequest(r)
AO_RARITY_GUN = gun
report()
