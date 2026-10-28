-- Hit rig: a frozen, invulnerable test NPC with V 5 m in front of it, and a log of every hit's
-- damage before and after DamageSystem.CalculateDamageVariants (the damage roll). Spawned NPCs
-- strafe, so they're frozen with time dilation; teleporting a frozen NPC doesn't stick, so V moves.
-- Defines the global RIG; driven one call per shot by rig.sh / roll.sh:
--   RIG.setup(gun, dist=5)  -> "ready" or "wait" (first call spawns); RIG.fireV()  RIG.fireNpc()
--   RIG.ratios(who) -> sorted post/pre ratios of hits by "V" (on the NPC) or "NPC" (on V)
--   RIG.clear()  RIG.teardown()
RIG = RIG or { hits = {} }
local gm = function() return Game.GetGodModeSystem() end
local tag = CName.new("aorig")

if not RIG.hooked then
  ObserveBefore("DamageSystem", "CalculateDamageVariants", function(_, e)
    RIG.pre = e.attackComputed:GetTotalAttackValue(gamedataStatPoolType.Health)
  end)
  ObserveAfter("DamageSystem", "CalculateDamageVariants", function(_, e)
    local i = e.attackData:GetInstigator()
    table.insert(RIG.hits, {
      pre = RIG.pre or 0,
      post = e.attackComputed:GetTotalAttackValue(gamedataStatPoolType.Health),
      byV = i ~= nil and i:IsPlayer(),
      onV = e.target ~= nil and e.target:IsPlayer(),
    })
  end)
  RIG.hooked = true
end

function RIG.npc() return Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1] end

function RIG.setup(gun, dist)
  dist = dist or 5
  local p = Game.GetPlayer()
  if gun then
    local w = p:GetActiveWeapon()
    if not w or TDBID.ToStringDEBUG(w:GetItemID().id) ~= gun then return "draw " .. gun .. " first" end
  end
  local n = RIG.npc()
  if not n then
    GetMod("AOTestKit").spawn("Character.AO_Test_Plain_Unity", 1)
    return "wait"
  end
  n:SetIndividualTimeDilation(tag, 0.0001, 9999.0, CName.new(""), CName.new(""))
  gm():AddGodMode(n:GetEntityID(), gameGodModeType.Invulnerable, tag)
  gm():AddGodMode(p:GetEntityID(), gameGodModeType.Invulnerable, tag)
  local a, b = p:GetWorldPosition(), n:GetWorldPosition()
  local dx, dy = a.x - b.x, a.y - b.y
  local l = math.sqrt(dx * dx + dy * dy)
  if math.abs(l - dist) > 0.5 then
    local yaw = math.deg(math.atan2(-dx, dy)) + 180
    Game.GetTeleportationFacility():Teleport(p, Vector4.new(b.x + dx / l * dist, b.y + dy / l * dist, b.z, 1), EulerAngles.new(0, 0, yaw))
    return "wait"
  end
  return "ready"
end

local function chest(o) local v = o:GetWorldPosition(); v.z = v.z + 1.0; return v end

function RIG.fireV()
  local p, n = Game.GetPlayer(), RIG.npc()
  AIWeapon.Fire(p, p:GetActiveWeapon(), EngineTime.ToFloat(Game.GetSimTime()), 1.0, gamedataTriggerMode.SemiAuto, chest(n), n)
end

function RIG.fireNpc()
  local p, n = Game.GetPlayer(), RIG.npc()
  local w = Game.GetTransactionSystem():GetItemInSlot(n, TweakDBID.new("AttachmentSlots.WeaponRight"))
  AIWeapon.Fire(n, w, EngineTime.ToFloat(Game.GetSimTime()), 1.0, gamedataTriggerMode.SemiAuto, chest(p), p)
end

function RIG.ratios(who)
  local out = {}
  for _, h in ipairs(RIG.hits) do
    local match = (who == "V" and h.byV and not h.onV) or (who == "NPC" and not h.byV and h.onV)
    if match and h.pre > 0 then table.insert(out, h.post / h.pre) end
  end
  table.sort(out)
  return out
end

function RIG.clear() RIG.hits = {} end

function RIG.teardown()
  local n = RIG.npc()
  gm():RemoveGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, tag)
  if n then GetMod("AOTestKit").despawnAll() end
end
