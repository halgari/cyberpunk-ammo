-- Stats of an Uncommon round's selector on an NPC's gun, read from the gun's stats object while it is
-- in the NPC's hand (as slice/npcdrop.sh does). parity.sh runs it twice per case on a Plain_* NPC:
--   PS_MODE='base'  with the roll off (Common round): stores the gun's values in AO_PS_BASE
--   PS_MODE='held'  with the roll forced to PS_SEL's round: each stat in PS_STATS (comma list) equals
--                   (base + Additive modifiers) * Multiplier modifiers of the selector, and differs from base
--   PS_ZERO (comma list): stats the NPC gun has no value for (0 with or without the round, so a
--                   multiplier changes nothing; DESIGN.md Known gaps)
local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
local w = npc and ScriptedPuppet.GetActiveWeapon(npc)
local ss = Game.GetStatsSystem()
local stats = {}
for s in PS_STATS:gmatch("[^,]+") do table.insert(stats, s) end
table.insert(stats, "ProjectilesPerShotBase")
local zero = {}
for s in (PS_ZERO or ""):gmatch("[^,]+") do table.insert(zero, s); table.insert(stats, s) end
if not w then check(PS_NAME .. ": NPC gun is out", false, "no NPC with a gun") report() return end
local id = w:GetItemData():GetStatsObjectID()
local function value(s) return ss:GetStatValue(id, gamedataStatType[s]) end
if PS_MODE == "base" then
  AO_PS_BASE = {}
  for _, s in ipairs(stats) do AO_PS_BASE[s] = value(s) end
  return "stored"
end
local zeroSet = {}
for _, s in ipairs(zero) do zeroSet[s] = true end
for _, s in ipairs(stats) do
  if s ~= "ProjectilesPerShotBase" and not zeroSet[s] then
    local base, got = AO_PS_BASE[s], value(s)
    local add, mult, any = 0, 1, false
    for _, m in ipairs(flat(PS_SEL, "statModifiers") or {}) do
      if str(flat(m, "statType")) == "BaseStats." .. s then
        any = true
        local mt, v = flat(m, "modifierType").value, flat(m, "value")
        if flat(m, "refStat") then v = v * AO_PS_BASE[(str(flat(m, "refStat")):gsub("^BaseStats%.", ""))] end
        if mt == "Additive" then add = add + v else mult = mult * v end
      end
    end
    local want = (base + add) * mult
    check(string.format("%s: NPC gun %s %.3f -> %.3f (selector says %.3f)", PS_NAME, s, base, got, want),
      any and math.abs(got - want) < 0.001 and math.abs(got - base) > 0.0005, "base " .. base)
  end
end
for _, s in ipairs(zero) do
  local base, got = AO_PS_BASE[s], value(s)
  check(string.format("%s: NPC gun %s is 0 with and without the round (%s -> %s)", PS_NAME, s, base, got), base == 0 and got == 0)
end
report()
