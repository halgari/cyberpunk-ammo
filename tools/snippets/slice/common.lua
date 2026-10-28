-- Shared by the slice checks: PASS/FAIL printing and TweakDB helpers. Each check script starts
-- with this file's text (cet.sh sends one chunk), so run them as
--   tools/linux/cet.sh "$(cat tools/snippets/slice/common.lua tools/snippets/slice/<check>.lua)"
local out = {}
function check(name, ok, why)
  table.insert(out, (ok and "PASS " or "FAIL ") .. name .. ((not ok and why) and (": " .. why) or ""))
end
function report() for _, l in ipairs(out) do print(l) end end
function str(id) local ok, s = pcall(TDBID.ToStringDEBUG, id); return ok and s or tostring(id) end
function rec(id) return TweakDB:GetRecord(id) end
-- `id` may be a string or a TweakDBID (runtime clones have no string name).
function tid(id) return type(id) == "string" and TweakDBID.new(id) or id end
function flat(id, f) return TweakDB:GetFlat(TweakDBID.new(tid(id), "." .. f)) end
function locName(id) local r = rec(id); return r and Game.GetLocalizedTextByKey(r:DisplayName()) or nil end
-- Sum of additive constant modifiers of `stat` on a record's statModifiers.
function statSum(id, stat)
  local sum = 0
  for _, m in ipairs(flat(id, "statModifiers") or {}) do
    local mt = flat(m, "modifierType")
    if str(flat(m, "statType")) == "BaseStats." .. stat and mt and mt.value == "Additive" then
      sum = sum + (flat(m, "value") or 0)
    end
  end
  return sum
end
