-- Hit rig: a frozen, invulnerable test NPC with V 5 m in front of it, and a log of every hit's
-- damage before and after DamageSystem.CalculateDamageVariants (the damage roll). Spawned NPCs
-- strafe, so they're frozen with time dilation; teleporting a frozen NPC doesn't stick, so V moves.
-- Defines the global RIG; driven one call per shot by rig.sh / roll.sh:
--   RIG.setup(gun, dist=5)  -> "ready" or "wait" (first call spawns); RIG.fireV()  RIG.letNpcShoot() then RIG.freeze()
--   RIG.ratios(who) -> sorted post/pre ratios of hits by "V" (on the NPC) or "NPC" (on V)
--   RIG.volleys(who) -> {n, total} per shot (hits within 0.1 s)
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
      onV = e.target ~= nil and e.target:IsPlayer(),
    })
  end)
  RIG.hooked = true
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

-- Whether level geometry blocks a shot from V's eyes to the NPC's chest.
local function blocked(p, n)
  local a, b = p:GetWorldPosition(), n:GetWorldPosition()
  a.z = a.z + 1.5; b.z = b.z + 1.2
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
  gm():AddGodMode(n:GetEntityID(), gameGodModeType.Invulnerable, tag)
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
  return "ready"
end

local function chest(o) local v = o:GetWorldPosition(); v.z = v.z + 1.0; return v end

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
    local match = (who == "V" and h.byV and not h.onV) or (who == "NPC" and not h.byV and h.onV)
    if match and h.pre > 0 then table.insert(out, h.post / h.pre) end
  end
  table.sort(out)
  return out
end

-- Shots as groups of hits within 0.1 s (a shotgun's pellets land together): {n = hits, total = damage}.
function RIG.volleys(who)
  local out, last = {}, nil
  for _, h in ipairs(RIG.hits) do
    if (who == "V" and h.byV and not h.onV) or (who == "NPC" and not h.byV and h.onV) then
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

function RIG.clear() RIG.hits = {} end

function RIG.teardown()
  local n = RIG.npc()
  police(true)
  gm():RemoveGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Immortal, tag)
  if n then GetMod("AOTestKit").despawnAll() end
end
