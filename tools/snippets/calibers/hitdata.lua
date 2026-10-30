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

-- On V, the effects vanilla swaps for its Player versions (DamageSystem.ProcessStatusEffectApplicationStats)
-- are swapped too; the rest stay as they are.
local swaps = { Burning = "PlayerBurning", MediumBurning = "PlayerBurning", Poisoned = "PlayerPoisoned",
  Bleeding = "PlayerBleeding", EMP = "PlayerElectrocuted", Blind = "Blind", Knockdown = "Knockdown" }
for from, to in pairs(swaps) do
  local got = tostring(sys:DebugPlayerEffect("BaseStatusEffect." .. from))
  check("on V " .. from .. " is " .. to, got == "BaseStatusEffect." .. to, got)
  check("BaseStatusEffect." .. to .. " exists", TweakDB:GetRecord("BaseStatusEffect." .. to) ~= nil, "no record")
end
-- An effect's chance is per shot: each of a shot's n pellets rolls 1 - (1 - chance)^(1/n).
local function near(a, b) return math.abs(a - b) < 0.0005 end
local p1, p8 = sys:DebugPelletChance(0.6, 1), sys:DebugPelletChance(0.6, 8)
check("one projectile rolls the chance as given", near(p1, 0.6), tostring(p1))
check("8 pellets: 0.6 per shot is 0.108 per pellet", near(p8, 1 - 0.4 ^ (1 / 8)), tostring(p8))
check("certain stays certain per pellet", near(sys:DebugPelletChance(1.0, 6), 1.0), "")

-- Ping: tags what it hits (AmmoOverhaul.PingTag, Hawk's tag for 5 s); the only drawback is -10% damage.
for _, loc in ipairs({ "762", "127" }) do
  local d = data("Ammo.AO_" .. loc .. "_Ping")
  check("Ammo.AO_" .. loc .. "_Ping tags every hit", d:find("effects=AmmoOverhaul.PingTag:1;", 1, true) ~= nil, d)
  local sel = "Items.AO_Feed_" .. loc .. "_Ping"
  local mods = flat(sel, "statModifiers") or {}
  local m = mods[1]
  local only = #mods == 1 and str(flat(m, "statType")) == "BaseStats.DamagePerHit"
    and flat(m, "modifierType") ~= nil and flat(m, "modifierType").value == "Multiplier" and near(flat(m, "value") or 0, 0.90)
  check(sel .. " carries only DamagePerHit x0.90", rec(sel) ~= nil and only, tostring(#mods) .. " modifiers")
end
local tag = rec("AmmoOverhaul.PingTag")
check("AmmoOverhaul.PingTag exists", tag ~= nil, "no record")
if tag then
  local dur
  for _, m in ipairs(tag:Duration() and tag:Duration():StatModifiers() or {}) do
    if m:IsA("gamedataConstantStatModifier_Record") then dur = m:Value() end
  end
  check("AmmoOverhaul.PingTag lasts 5 s", dur ~= nil and near(dur, 5), tostring(dur))
  local auto = false
  for _, t in ipairs(tag:GameplayTags()) do if t.value == "AutoTag" then auto = true end end
  check("AmmoOverhaul.PingTag is an AutoTag", auto, "no AutoTag tag")
end
report()
