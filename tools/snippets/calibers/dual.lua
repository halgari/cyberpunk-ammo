-- Helpers for dualwield.sh: two guns in hand, the stack, reloads and real shots.
DW = {}
local p = Game.GetPlayer(); local ts = Game.GetTransactionSystem()
function DW.items(rec)
  local out, _, items = {}, ts:GetItemList(p)
  for _, d in ipairs(items) do if TDBID.ToStringDEBUG(d:GetID().id) == rec then table.insert(out, d:GetID()) end end
  return out
end
function DW.qty(a) return ts:GetItemQuantity(p, ItemID.CreateQuery(TweakDBID.new(a))) end
function DW.set(a, n)
  local have = DW.qty(a)
  if have > 0 then ts:RemoveItemByTDBID(p, TweakDBID.new(a), have) end
  if n > 0 then ts:GiveItem(p, ItemID.CreateQuery(TweakDBID.new(a)), n) end
end
function DW.left() return ts:GetItemInSlot(p, TweakDBID.new("AttachmentSlots.WeaponLeft")) end
function DW.right() return ts:GetItemInSlot(p, TweakDBID.new("AttachmentSlots.WeaponRight")) end
-- The rounds the gun will really fire; GetMagazineAmmoCount only reads the blackboard.
function DW.mag(w) return w and AO_ReadInt32(w, 0x2f8) or -1 end
function DW.state(a) return DW.qty(a) .. " " .. DW.mag(DW.right()) .. " " .. DW.mag(DW.left()) end
function DW.give(rec) for _ = 1, 2 do ts:GiveItem(p, ItemID.FromTDBID(TweakDBID.new(rec)), 1) end end
function DW.perk()
  local d, T = PlayerDevelopmentSystem.GetData(p), gamedataNewPerkType.Cool_Central_Milestone_2
  d:UnlockNewPerk(T); d:BuyNewPerk(T, true); return d:IsNewPerkBoughtAnyLevel(T)
end
function DW.equip(rec)
  local es, g = Game.GetScriptableSystemsContainer():Get("EquipmentSystem"), DW.items(rec)
  if #g < 2 then return "have " .. #g end
  for i, s in ipairs({ 0, 3 }) do
    local e = EquipRequest.new(); e.owner = p; e.itemID = g[i]; e.slotIndex = s; es:QueueRequest(e)
  end
  local d = DrawItemRequest.new(); d.owner = p; d.itemID = g[1]; d.equipAnimationType = gameEquipAnimationType.Instant
  es:QueueRequest(d)
  return "ok"
end
function DW.consume(w, n) local e = WeaponConsumeMagazineAmmoEvent.new(); e.amount = n; w:QueueEvent(e) end
function DW.reload(w) w:StartReload(); w:StopReload(gameweaponReloadStatus.Standard) end
function DW.shot(w)
  local f, d = p:GetWorldPosition(), p:GetWorldForward()
  AIWeapon.Fire(p, w, EngineTime.ToFloat(Game.GetSimTime()), 1.0, gamedataTriggerMode.SemiAuto,
    Vector4.new(f.x + d.x * 20, f.y + d.y * 20, f.z + 1.5, 1))
end
