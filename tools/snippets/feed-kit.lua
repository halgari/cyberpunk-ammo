-- The slice kit (the three guns, six selectors, 60 of each round), then one gun equipped into
-- weapon slot 1 and drawn. GUN picks the preset (default the Lexington):
--   tools/linux/cet.sh "GUN='Items.Preset_Omaha_Default'; $(cat tools/snippets/feed-kit.lua)"
-- Run twice if the save lacks the items.
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
local name = GUN or "Items.Preset_Lexington_Default"
local gun = find(name)
if not gun then
  GetMod("AOTestKit").giveKit()
  return "gave the slice kit; run again to equip and draw " .. name
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
return name .. " equipped and drawing"
