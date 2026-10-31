-- Helpers for spread.sh: SP.read() every Spread stat on the drawn gun, SP.compare() against
-- AO_SPREAD_BASE (stored between runs).
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
