-- Damage roll values (DamageRoll.reds): each layer's resolved range, and the draws' spread.
-- Reads AmmoFeedSystem.DebugRollFor/DebugRollDraws; no gun or NPC needed.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local function nums(s) local t = {} for v in s:gmatch("%S+") do table.insert(t, tonumber(v)) end return t end
local function near(a, b, e) return a and math.abs(a - b) <= (e or 0.001) end
local function same(name, got, want)
  local g, ok = nums(got), true
  for i, w in ipairs(want) do if not near(g[i], w) then ok = false end end
  check(name, ok, got)
end
local function roll(ammo, t, fresh) return sys:DebugRollFor(ammo, t or "", fresh or false) end

same("45 Ball: global roll", roll("Ammo.AO_45_Ball"), { 0.90, 1.01, 0, 1, 0, 1 })
same("Ammo.Standard: global roll", roll("Ammo.Standard"), { 0.90, 1.01, 0, 1, 0, 1 })
same("Test_Roll: round values", roll("Ammo.AO_Test_Roll"), { 0.5, 0.6, 0.2, 0.1, 0.2, 3.0 })
same("Test_Roll Thermal: per-type range", roll("Ammo.AO_Test_Roll", "Thermal"), { 2.0, 2.0, 0.2, 0.1, 0.2, 3.0 })
same("Test_Roll Physical: falls back to the round", roll("Ammo.AO_Test_Roll", "Physical"), { 0.5, 0.6 })
same("Test_RollFaction: faction layer", roll("Ammo.AO_Test_RollFaction"), { 0.7, 0.8, 0, 1, 0, 1 })

local key = "AmmoOverhaul.roll.Tech.min"
local old = TweakDB:GetFlat(key)
TweakDB:SetFlat(key, 0.95)
same("Tech family layer applies to TLight Slug", roll("Ammo.AO_TLight_Slug", "", true), { 0.95, 1.01 })
if old then TweakDB:SetFlat(key, old) else TweakDB:SetFlat(key, -1.0) end
same("Tech family layer restored", roll("Ammo.AO_TLight_Slug", "", true), { 0.90, 1.01 })

local d = nums(sys:DebugRollDraws("Ammo.AO_45_Ball", "", 5000))
check("45 Ball draws within 0.90..1.01", d[1] >= 0.90 - 1e-4 and d[2] <= 1.01 + 1e-4, d[1] .. ".." .. d[2])
check("45 Ball mean 0.955", near(d[3], 0.955, 0.01), tostring(d[3]))
check("45 Ball no duds or hots", d[4] == 0 and d[5] == 0, d[4] .. " " .. d[5])

local t = nums(sys:DebugRollDraws("Ammo.AO_Test_Roll", "", 5000))
check("Test_Roll duds 20%", near(t[4] / 5000, 0.20, 0.03), tostring(t[4]))
check("Test_Roll hots 16%", near(t[5] / 5000, 0.16, 0.03), tostring(t[5]))
-- min/max cover every draw: duds at 0.1, hots at 3.0, the rest in 0.5..0.6.
check("Test_Roll lowest is a dud (0.1)", near(t[1], 0.1), tostring(t[1]))
check("Test_Roll highest is hot (3.0)", near(t[2], 3.0), tostring(t[2]))
local rest = (t[3] * 5000 - t[4] * 0.1 - t[5] * 3.0) / (5000 - t[4] - t[5])
check("Test_Roll other draws average in 0.5..0.6", rest > 0.5 and rest < 0.6, tostring(rest))

-- The cached caliber of every weapon record agrees with a fresh lookup.
local bad, n = {}, 0
for _, r in ipairs(TweakDB:GetRecords("gamedataWeaponItem_Record") or {}) do
  local id = str(r:GetID())
  local cached, fresh = sys:DebugCaliber(id, false), sys:DebugCaliber(id, true)
  n = n + 1
  if cached ~= fresh then table.insert(bad, id .. " " .. cached .. "/" .. fresh) end
end
check("cached CaliberForWeapon matches fresh for " .. n .. " weapon records", n > 0 and #bad == 0, table.concat(bad, ", "))
report()
