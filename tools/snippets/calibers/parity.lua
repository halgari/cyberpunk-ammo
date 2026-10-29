-- NPC damage parity: an Uncommon round's DamagePerHit Multiplier (on its selector part) is applied
-- to NPC hits by the damage roll (AmmoFeedSystem.RollGunHit), as NPC guns have DamagePerHit 0.
-- Static: AmmoFeedSystem.DebugDamageFactor per round, generic over every caliber's tier-1 round.
-- The Mushrooms ganger (parity-ganger.lua) and the live hits are parity.sh.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local function near(a, b) return a and math.abs(a - b) <= 0.001 end
local function factor(ammo) return tonumber(sys:DebugDamageFactor(ammo)) end

for ammo, want in pairs({
  ["Ammo.AO_S10_Dumbfire"] = 1.8, ["Ammo.AO_S20_Dumbfire"] = 1.8, ["Ammo.AO_S25_Dumbfire"] = 1.8,
  ["Ammo.AO_9mm_HollowPoint"] = 1.2, ["Ammo.AO_4ga_Slug"] = 1.3, ["Ammo.AO_45_Ball"] = 1.0,
  ["Ammo.HandgunAmmo"] = 1.0 }) do
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

report()
