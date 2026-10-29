-- Hit rig: a frozen, invulnerable test NPC with V 5 m in front of it, and a log of every hit's
-- damage before and after DamageSystem.CalculateDamageVariants (the damage roll). Spawned NPCs
-- strafe, so they're frozen with time dilation; teleporting a frozen NPC doesn't stick, so V moves.
-- Defines the global RIG; driven one call per shot by rig.sh / roll.sh:
--   RIG.setup(gun, dist=5)  -> "ready" or "wait" (first call spawns); RIG.fireV()  RIG.letNpcShoot() then RIG.freeze()
--   RIG.ratios(who) -> sorted post/pre ratios of hits by "V" (on the NPC) or "NPC" (on V)
--   RIG.volleys(who) -> {n, total} per shot (hits within 0.1 s)
--   RIG.thermal(who) -> sorted Thermal / (Physical + Thermal) of each hit after the roll
--   RIG.effects(who, id) -> times status effect `id` was applied to V ("V") or an NPC ("NPC")
--   RIG.npcMode: the NPC's god mode, Invulnerable unless set (vanilla gives an Invulnerable target
--     no debuffs, so effect checks set gameGodModeType.Immortal)
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
      t = EngineTime.ToFloat(Game.GetSimTime()),
      byV = i ~= nil and i:IsPlayer(),
      dot = AttackData.IsDoT(e.attackData),
      phys = e.attackComputed:GetAttackValue(gamedataDamageType.Physical),
      therm = e.attackComputed:GetAttackValue(gamedataDamageType.Thermal),
      onV = e.target ~= nil and e.target:IsPlayer(),
      -- V's hits count only when they land on the rig's NPC (a miss can hit someone else).
      onNpc = e.target ~= nil and RIG.npc() ~= nil and e.target:GetEntityID().hash == RIG.npc():GetEntityID().hash,
    })
  end)
  RIG.hooked = true
end
-- Status effects applied to V and to NPCs, by record name (hitdata.sh). Effects reach V a moment
-- after the hit, so they're counted as they arrive rather than read off the hit.
RIG.applied = RIG.applied or { V = {}, NPC = {} }
if not RIG.effectHooked then
  local function note(who, evt)
    local ok, id = pcall(function() return TDBID.ToStringDEBUG(evt.staticData:GetID()) end)
    if ok then RIG.applied[who][id] = (RIG.applied[who][id] or 0) + 1 end
  end
  ObserveAfter("PlayerPuppet", "OnStatusEffectApplied", function(_, evt) note("V", evt) end)
  ObserveAfter("NPCPuppet", "OnStatusEffectApplied", function(_, evt) note("NPC", evt) end)
  RIG.effectHooked = true
end

function RIG.npc() return Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1] end

-- Where V stands before each spawn: the middle of the open road by the test save's load point,
-- facing 30 m of clear road (checked by screenshot, tools/linux/game-shot.sh). The NPC spawns
-- 12 m ahead of it.
RIG.HOME = { x = -1279.61, y = -979.01, z = 11.84, yaw = 115 }
local function goHome(p)
  local a, h = p:GetWorldPosition(), RIG.HOME
  if math.abs(a.x - h.x) + math.abs(a.y - h.y) > 1 then
    Game.GetTeleportationFacility():Teleport(p, Vector4.new(h.x, h.y, h.z, 1), EulerAngles.new(0, 0, h.yaw))
  end
end

-- The NPC's chest: its Chest slot, which follows crouches and cover (1.0 m above its feet if the
-- slot can't be read).
local function chest(o)
  local sc = o:GetSlotComponent()
  local ok, t = false, nil
  if sc then ok, t = sc:GetSlotTransform(CName.new("Chest")) end
  if ok and t then return WorldPosition.ToVector4(WorldTransform.GetWorldPosition(t)) end
  local v = o:GetWorldPosition(); v.z = v.z + 1.0; return v
end

-- V's shots follow V's camera, not AIWeapon.Fire's target position: a level camera fires at eye
-- height, over a crouching NPC's head. Pitch the camera at the NPC's chest (lands next frame).
local function aim(p, n, pitch)
  -- Face the NPC too: V's yaw was only set when the rig moved V, so a frozen NPC could sit off to
  -- the side of the crosshair. Turning in place is a teleport to where V stands.
  local a, c = p:GetWorldPosition(), chest(n)
  local yaw = math.deg(math.atan2(-(c.x - a.x), c.y - a.y))
  local off = (yaw - p:GetWorldYaw() + 540) % 360 - 180
  if math.abs(off) > 1 then
    Game.GetTeleportationFacility():Teleport(p, a, EulerAngles.new(0, 0, yaw))
  end
  if not pitch then
    local a, c = p:GetWorldPosition(), chest(n)
    a.z = a.z + 1.7
    local dx, dy = c.x - a.x, c.y - a.y
    pitch = math.deg(math.atan2(c.z - a.z, math.sqrt(dx * dx + dy * dy)))
  end
  -- The camera's offset adds to V's own aim, which recoil walks upward over many shots (80 degrees
  -- up after a long run, all shots over the NPC): set the offset from where the camera really points.
  local cam = p:GetFPPCameraComponent()
  local world = math.deg(math.asin(math.max(-1, math.min(1, cam:GetLocalToWorld():GetAxisY().z))))
  local offset = cam:GetLocalOrientation():ToEulerAngles().pitch
  cam:SetLocalOrientation(EulerAngles.new(0, pitch - (world - offset), 0):ToQuat())
end

-- Whether level geometry blocks a shot from V's eyes to the NPC's chest.
local function blocked(p, n)
  local a, b = p:GetWorldPosition(), chest(n)
  a.z = a.z + 1.5
  return (Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(a, b, CName.new("Static"), true, false))
end
local function respawn(p, why)
  GetMod("AOTestKit").despawnAll()
  goHome(p)
  return "wait: " .. why .. ", respawning"
end

-- Shooting in the street draws police heat, and police crowd in, block shots and fire at V:
-- the police system is locked off while the rig runs (TogglePreventionSystem with a lock source).
local function police(on)
  local r = TogglePreventionSystem.new()
  r.sourceName = tag
  r.isActive = on
  Game.GetScriptableSystemsContainer():Get("PreventionSystem"):QueueRequest(r)
end

function RIG.setup(gun, dist)
  dist = dist or 5
  local p = Game.GetPlayer()
  police(false)
  if StatusEffectSystem.ObjectHasStatusEffectWithTag(p, CName.new("NoCombat")) then return "V is in a no-combat zone" end
  if gun then
    local w = p:GetActiveWeapon()
    if not w or TDBID.ToStringDEBUG(w:GetItemID().id) ~= gun then return "draw " .. gun .. " first" end
  end
  local n = RIG.npc()
  if not n then
    goHome(p)
    GetMod("AOTestKit").state.distance = 12
    GetMod("AOTestKit").spawn("Character.AO_Test_Plain_Unity", 1)
    return "wait: spawning"
  end
  -- A spawned NPC can sink into the floor, where shots can't reach it: spawn a fresh one.
  if n:GetWorldPosition().z < p:GetWorldPosition().z - 1.0 then
    return respawn(p, "sunk")
  end
  -- Let loose to shoot V, it can run off or go down: start over with a fresh one.
  local a, b = p:GetWorldPosition(), n:GetWorldPosition()
  local away = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
  if away > dist + 5 and not Game.GetTransactionSystem():GetItemInSlot(n, TweakDBID.new("AttachmentSlots.WeaponRight"))
      or n:IsDead() or ScriptedPuppet.IsDefeated(n) then
    return respawn(p, string.format("npc gone (%.0f m)", away))
  end
  if blocked(p, n) then return respawn(p, "no line of sight") end
  if RIG.npcMode == gameGodModeType.Immortal then gm():RemoveGodMode(n:GetEntityID(), gameGodModeType.Invulnerable, tag) end
  gm():AddGodMode(n:GetEntityID(), RIG.npcMode or gameGodModeType.Invulnerable, tag)
  gm():AddGodMode(p:GetEntityID(), gameGodModeType.Immortal, tag)
  -- Freeze only once its gun is drawn, or it has nothing to shoot V with. An NPC can holster
  -- while it's let loose and then be frozen gunless: unfreeze it so it draws again.
  if not Game.GetTransactionSystem():GetItemInSlot(n, TweakDBID.new("AttachmentSlots.WeaponRight")) then
    n:UnsetIndividualTimeDilation()
    return string.format("wait: npc gun not drawn (%.0f m)", away)
  end
  RIG.freeze()
  local a, b = p:GetWorldPosition(), n:GetWorldPosition()
  local dx, dy = a.x - b.x, a.y - b.y
  local l = math.sqrt(dx * dx + dy * dy)
  if math.abs(l - dist) > 0.5 then
    local yaw = math.deg(math.atan2(-dx, dy)) + 180
    Game.GetTeleportationFacility():Teleport(p, Vector4.new(b.x + dx / l * dist, b.y + dy / l * dist, a.z, 1), EulerAngles.new(0, 0, yaw))
    return "wait: moved V"
  end
  aim(p, n)
  return "ready"
end

-- "holstered" when V has put the gun away (it happens after teleports and spawns): redraw, retry.
function RIG.fireV()
  local p, n = Game.GetPlayer(), RIG.npc()
  if not p:GetActiveWeapon() then return "holstered" end
  -- AIWeapon.Fire doesn't reload, and V only auto-reloads some guns. StartReload alone leaves
  -- V's gun stuck mid-reload; StopReload(Standard) completes it and fills the magazine.
  if WeaponObject.GetMagazineAmmoCount(p:GetActiveWeapon()) == 0 then
    p:GetActiveWeapon():StartReload()
    p:GetActiveWeapon():StopReload(gameweaponReloadStatus.Standard)
    return "reloaded"
  end
  aim(p, n)
  -- Fire only with the NPC under the crosshair (the game's look-at target, what turns it red);
  -- the turn and pitch land a frame later, so the next call fires.
  local look = Game.GetTargetingSystem():GetLookAtObject(p, false, false)
  if not look or look:GetEntityID().hash ~= n:GetEntityID().hash then return "off target" end
  AIWeapon.Fire(p, p:GetActiveWeapon(), EngineTime.ToFloat(Game.GetSimTime()), 1.0, gamedataTriggerMode.SemiAuto, chest(n), n)
  return "fired"
end

-- AIWeapon.Fire with the NPC as shooter lands nothing, so the NPC's own AI shoots V: unfreeze
-- it, let the caller wait a few seconds, then RIG.freeze(). V is Immortal (takes the hits).
function RIG.letNpcShoot() RIG.npc():UnsetIndividualTimeDilation() end
function RIG.freeze()
  RIG.npc():SetIndividualTimeDilation(tag, 0.0001, 9999.0, CName.new(""), CName.new(""))
end

function RIG.ratios(who)
  local out = {}
  for _, h in ipairs(RIG.hits) do
    local match = not h.dot and ((who == "V" and h.byV and h.onNpc) or (who == "NPC" and not h.byV and h.onV))
    if match and h.pre > 0 then table.insert(out, h.post / h.pre) end
  end
  table.sort(out)
  return out
end

-- Shots as groups of hits within 0.1 s (a shotgun's pellets land together): {n = hits, total = damage}.
function RIG.volleys(who)
  local out, last = {}, nil
  for _, h in ipairs(RIG.hits) do
    if not h.dot and ((who == "V" and h.byV and h.onNpc) or (who == "NPC" and not h.byV and h.onV)) then
      if last and h.t - last < 0.1 then
        out[#out].n = out[#out].n + 1; out[#out].total = out[#out].total + h.post
      else
        table.insert(out, { n = 1, total = h.post })
      end
      last = h.t
    end
  end
  return out
end

function RIG.thermal(who)
  local out = {}
  for _, h in ipairs(RIG.hits) do
    local match = not h.dot and ((who == "V" and h.byV and h.onNpc) or (who == "NPC" and not h.byV and h.onV))
    if match and h.phys + h.therm > 0 then table.insert(out, h.therm / (h.phys + h.therm)) end
  end
  table.sort(out)
  return out
end

-- How many times `effect` was applied to V ("V") or an NPC ("NPC") since RIG.clear().
function RIG.effects(who, effect) return RIG.applied[who][effect] or 0 end

function RIG.clear() RIG.hits = {}; RIG.applied = { V = {}, NPC = {} } end

function RIG.teardown()
  local n = RIG.npc()
  RIG.npcMode = nil
  police(true)
  aim(Game.GetPlayer(), nil, 0)
  gm():RemoveGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Immortal, tag)
  if n then GetMod("AOTestKit").despawnAll() end
end
