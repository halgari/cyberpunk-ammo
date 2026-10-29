-- A Mushrooms ganger: the round's factor is 1.2, and its gun's own DamagePerHit stays 0 (no double
-- application). parity.sh spawns the ganger and waits for its gun before running this file.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
local w = npc and ScriptedPuppet.GetActiveWeapon(npc)
check("ganger is out with its gun", w ~= nil, "no tagged NPC with a gun; run through parity.sh")
if w then
  local ammo = sys:DebugLoadedAmmo(npc)
  local f = tonumber(sys:DebugDamageFactor(ammo))
  check("ganger LoadedAmmo " .. ammo .. " factor 1.2", f and math.abs(f - 1.2) <= 0.001, tostring(f))
  check("ganger gun DamagePerHit still 0 (no double application)",
    Game.GetStatsSystem():GetStatValue(w:GetItemData():GetStatsObjectID(), gamedataStatType.DamagePerHit) == 0)
end
report()
