-- After rarity.lua: the Sleevers selector went into the Common Kenshin; then cleans up.
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local gun = AO_RARITY_GUN
local part = ts:GetItemData(p, gun):GetItemPart(TweakDBID.new("AttachmentSlots.AO_AmmoFeed_Tech_Light"))
local name = part and str(part:GetItemID().id) or "empty"
check("Sleevers installed in the Common Kenshin", name == "Items.AO_Feed_5mm_Sleevers", name)
ts:RemoveItem(p, gun, 1)
report()
