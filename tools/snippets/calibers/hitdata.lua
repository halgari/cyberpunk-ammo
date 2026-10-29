-- Per-round hit data (AOData.HitEffects, DamageShare, MachineBonus, IsNonlethal) as the hit hooks
-- read it, through AmmoFeedSystem.DebugHitData. Static: no restart, no NPC.
--   tools/snippets/calibers/check.sh calibers/hitdata.lua
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local function data(ammo) return tostring(sys:DebugHitData(ammo)) end

local t = data("Ammo.AO_Test_HitData")
check("test round: Burning every hit", t:find("effects=BaseStatusEffect.Burning:1;", 1, true) ~= nil, t)
check("test round: half of Physical as Thermal", t:find("share=Thermal:0.50;", 1, true) ~= nil, t)
check("test round: x2 against machines", t:find("machine=2;", 1, true) ~= nil, t)
check("test round: non-lethal", t:find("nonlethal=true", 1, true) ~= nil, t)

local s = data("Ammo.AO_4ga_Slug")
check("4ga Slug knocks targets down every hit", s:find("effects=BaseStatusEffect.Knockdown:1;", 1, true) ~= nil, s)
check("4ga Slug moves no damage and has no machine bonus", s:find("share=none", 1, true) ~= nil and s:find("machine=1;", 1, true) ~= nil, s)

for _, a in ipairs({ "Ammo.HandgunAmmo", "Ammo.AO_9mm_HollowPoint", "Ammo.Standard" }) do
  local d = data(a)
  check(a .. " has no hit data", d == "effects=;share=none;machine=1;nonlethal=false", d)
end
check("the old ammoEffects list is gone", flat("AmmoOverhaul", "ammoEffects") == nil, "still set")
report()
