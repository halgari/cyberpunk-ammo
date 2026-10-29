-- NPC damage parity: an Uncommon round's DamagePerHit Multiplier (on its selector part) is applied
-- to NPC hits by the damage roll (AmmoFeedSystem.RollGunHit), as NPC guns have DamagePerHit 0.
-- Static: AmmoFeedSystem.DebugDamageFactor per round, generic over every caliber's tier-1 round,
-- and a spawned Mushrooms ganger. The live hits are parity.sh.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local function near(a, b) return a and math.abs(a - b) <= 0.001 end
local function factor(ammo) return tonumber(sys:DebugDamageFactor(ammo)) end

for ammo, want in pairs({
  ["Ammo.AO_S10_Dumbfire"] = 1.8, ["Ammo.AO_S20_Dumbfire"] = 1.8, ["Ammo.AO_S25_Dumbfire"] = 1.8,
  ["Ammo.AO_9mm_HollowPoint"] = 1.2, ["Ammo.AO_4ga_Slug"] = 1.3, ["Ammo.AO_45_Ball"] = 1.0,
  ["Ammo.HandgunAmmo"] = 1.0, ["Ammo.Special_Missile"] = 1.0 }) do
  local got = factor(ammo)
  check(ammo .. " damage factor " .. want, near(got, want), tostring(got))
end
check("unmanaged ammo factor 1.0", near(factor("Ammo.Special_Missile"), 1.0), tostring(factor("Ammo.Special_Missile")))

-- Every caliber's tier-1 rounds: the factor is the product of the selector's DamagePerHit multipliers.
for _, cal in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local k = "AmmoOverhaul." .. cal
  local sels, ammos, tiers = flat(k, "selectors") or {}, flat(k, "selectorAmmo") or {}, flat(k, "selectorTiers") or {}
  for i, sel in ipairs(sels) do
    if tiers[i] == 1 then
      local want = 1.0
      for _, m in ipairs(flat(sel, "statModifiers") or {}) do
        local mt = flat(m, "modifierType")
        if str(flat(m, "statType")) == "BaseStats.DamagePerHit" and mt and mt.value == "Multiplier" then
          want = want * flat(m, "value")
        end
      end
      local got = factor(str(ammos[i]))
      check(cal .. " " .. str(ammos[i]) .. " factor " .. want, near(got, want), tostring(got))
    end
  end
end

-- A Mushrooms ganger: the round's factor is 1.2, and its gun's own DamagePerHit stays 0.
-- (parity.sh spawns the ganger and waits for its gun before running this file.)
local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
local w = npc and ScriptedPuppet.GetActiveWeapon(npc)
check("ganger is out with its gun", w ~= nil, "no tagged NPC with a gun; run through parity.sh")
if w then
  local ammo = sys:DebugLoadedAmmo(npc)
  check("ganger LoadedAmmo factor 1.2", near(factor(ammo), 1.2), ammo .. " " .. tostring(factor(ammo)))
  check("ganger gun DamagePerHit still 0 (no double application)",
    Game.GetStatsSystem():GetStatValue(w:GetItemData():GetStatsObjectID(), gamedataStatType.DamagePerHit) == 0)
end
report()
