-- A Lexington with both feed selectors and 30 incendiary rounds, equipped into weapon slot 1 and
-- drawn (feed slot empty, so it takes the default handgun ammo).
--   tools/linux/cet.sh -f tools/snippets/feed-kit.lua   (twice if the save lacks the items)
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
local function find(record)
  local _, items = ts:GetItemList(p)
  for _, data in ipairs(items) do
    -- By name: == between TweakDBIDs is always false in CET.
    if TDBID.ToStringDEBUG(data:GetID().id) == record then return data:GetID() end
  end
end

-- Items added this frame don't show up in GetItemList yet, so a first run only hands them out.
local gun = find("Items.Preset_Lexington_Default")
if not gun then
  Game.AddToInventory("Items.Preset_Lexington_Default", 1)
  Game.AddToInventory("Items.AO_Feed_9mm_FMJ", 1)
  Game.AddToInventory("Items.AO_Feed_9mm_Incendiary", 1)
  Game.AddToInventory("Ammo.AO_9mm_Incendiary", 30)
  return "gave Lexington, both selectors, 30 incendiary; run again to equip and draw"
end

local es = Game.GetScriptableSystemsContainer():Get("EquipmentSystem")
local equip = EquipRequest.new()
equip.owner = p
equip.itemID = gun
equip.slotIndex = 0
es:QueueRequest(equip)
local draw = DrawItemRequest.new()
draw.owner = p
draw.itemID = gun
draw.equipAnimationType = gameEquipAnimationType.Instant
es:QueueRequest(draw)
return "Lexington equipped and drawing"
