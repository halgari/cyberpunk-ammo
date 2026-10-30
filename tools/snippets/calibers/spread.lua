-- Helpers for spread.sh: SP.read() every Spread stat on the drawn gun, SP.compare() against
-- AO_SPREAD_BASE (stored between runs), SP.scatter() of V's hit positions, SP.undo/redo the x0.2.
SP = SP or {}
local function stats() return Game.GetStatsSystem() end
local function gun() return Game.GetPlayer():GetActiveWeapon() end
local function stat(n) return stats():GetStatValue(gun():GetEntityID(), gamedataStatType[n]) end
if not SP.names then
  SP.names = {}
  for i = 0, 3000 do
    local ok, n = pcall(function() return Game.EnumValueToString("gamedataStatType", i) end)
    if ok and n and n ~= "" and n:find("Spread") then table.insert(SP.names, n) end
  end
end
function SP.read()
  local s = { ProjectilesPerShot = stat("ProjectilesPerShot"), CycleTime = stat("CycleTime") }
  for _, n in ipairs(SP.names) do s[n] = stat(n) end
  return s
end
-- "PASS ...|FAIL ...|" : each spread stat that isn't zero at factor `f`; prints all of them.
function SP.compare(label, f, cycle)
  local now, base, out, seen = SP.read(), AO_SPREAD_BASE, {}, {}
  for _, n in ipairs(SP.names) do
    if base[n] ~= 0 or now[n] ~= 0 then
      local r = base[n] ~= 0 and now[n] / base[n] or 0
      table.insert(seen, string.format("%s %.3f->%.3f (x%.2f)", n, base[n], now[n], r))
      if n:find("^Spread[AM]?[da]?") and n:find("[XY]$") then
        table.insert(out, string.format("%s %s %s x%.2f", math.abs(r - f) < 0.01 and "PASS" or "FAIL", label, n, r))
      end
    end
  end
  print(label .. ": " .. table.concat(seen, ", "))
  table.insert(out, (now.ProjectilesPerShot == 1 and "PASS " or "FAIL ") .. label .. " one projectile")
  if cycle then
    local r = now.CycleTime / base.CycleTime
    table.insert(out, string.format("%s %s cycle x%.2f", math.abs(r - cycle) < 0.01 and "PASS" or "FAIL", label, r))
  end
  return label .. ": " .. table.concat(seen, ", ") .. "|" .. table.concat(out, "|")
end
function SP.hook()
  if SP.hooked then return end
  SP.hooked = true
  ObserveAfter("DamageSystem", "CalculateDamageVariants", function(_, e)
    local i = e.attackData:GetInstigator()
    if i and i:IsPlayer() and not e.target:IsPlayer() and SP.points then
      table.insert(SP.points, e.hitPosition)
    end
  end)
end
-- Hits, and the standard deviation of their height and of the offset across the line of fire.
function SP.scatter(label)
  local pts, p = SP.points or {}, Game.GetPlayer():GetWorldPosition()
  local n = #pts
  if n == 0 then return label .. ": 0 hits" end
  local mx, my, mz = 0, 0, 0
  for _, h in ipairs(pts) do mx, my, mz = mx + h.x / n, my + h.y / n, mz + h.z / n end
  local ax, ay = mx - p.x, my - p.y
  local len = math.sqrt(ax * ax + ay * ay)
  local su, sz = 0, 0
  for _, h in ipairs(pts) do
    local u = ((h.x - mx) * -ay + (h.y - my) * ax) / len
    su, sz = su + u * u / n, sz + (h.z - mz) ^ 2 / n
  end
  return string.format("%s: %d hits at %.1f m, across %.3f m, height %.3f m", label, n, len, math.sqrt(su), math.sqrt(sz))
end
local function mods(f)
  local id = gun():GetItemData():GetStatsObjectID()
  for _, n in ipairs({ "SpreadDefaultX", "SpreadDefaultY", "SpreadMaxX", "SpreadMaxY",
                       "SpreadAdsDefaultX", "SpreadAdsDefaultY", "SpreadAdsMaxX", "SpreadAdsMaxY" }) do
    local m = RPGManager.CreateStatModifier(gamedataStatType[n], gameStatModifierType.Multiplier, f)
    stats():AddModifier(id, m)
    SP.undone = SP.undone or {}
    table.insert(SP.undone, m)
  end
end
function SP.undo() mods(5.0); return stat("SpreadDefaultX") end
function SP.redo()
  local id = gun():GetItemData():GetStatsObjectID()
  for _, m in ipairs(SP.undone or {}) do stats():RemoveModifier(id, m) end
  SP.undone = nil
  return stat("SpreadDefaultX")
end
