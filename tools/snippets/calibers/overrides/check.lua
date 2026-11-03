-- User overrides (docs/DESIGN.md "User overrides"). With aaa_aotest.yaml and zz_aotest.yaml copied into
-- r6/tweaks (one sorts before AmmoOverhaul\, one after) and the game restarted:
--   tools/linux/cet.sh -t 40 "EXPECT='override'; $(cat tools/snippets/calibers/overrides/check.lua)"
-- Without them, EXPECT='none' checks nothing changed. Gives V one of each checked round.
local out, fails = {}, 0
local function ok(name, got, want)
  local pass = tostring(got) == tostring(want)
  if not pass then fails = fails + 1 end
  table.insert(out, (pass and "PASS " or "FAIL ") .. name .. ": got " .. tostring(got) .. (pass and "" or (", want " .. tostring(want))))
end
local function ammo(rec) local a = TweakDB:GetFlat(rec .. ".ammo"); return a and TDBID.ToStringDEBUG(a) or "nil" end
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local function cal(rec) return sys:CachedCaliber(TweakDBID.new(rec)) end
local function dflt(c) return TweakDB:GetFlat("AmmoOverhaul." .. c .. ".defaultAmmo") end
EXPECT = EXPECT or "override"
if EXPECT == "override" then
  ok("weapon line moves Lexington to .45", cal("Items.Preset_Lexington_Default"), "Power_45")
  ok("Lexington record ammo", ammo("Items.Preset_Lexington_Default"), dflt("Power_45"))
  ok("tag line moves Unity presets to 12mm", cal("Items.Preset_Unity_Military"), "Power_12mm")
  ok("weapon none beats tag line", cal("Items.Preset_Unity_Default"), "")
  ok("none leaves vanilla ammo", ammo("Items.Preset_Unity_Default"), "Ammo.HandgunAmmo")
  ok("second tag line works", cal("Items.Preset_Liberty_Default"), "Power_9mm")
  ok("unknown caliber ignored", cal("Items.Preset_Nova_Default"), "Power_12mm")
  ok("melee not mapped", cal("Items.Preset_Katana_Default"), "")
else
  ok("Lexington is 9mm", cal("Items.Preset_Lexington_Default"), "Power_9mm")
  ok("Unity Default is .45", cal("Items.Preset_Unity_Default"), "Power_45")
  ok("Unity Military is .45", cal("Items.Preset_Unity_Military"), "Power_45")
  ok("Liberty is .45", cal("Items.Preset_Liberty_Default"), "Power_45")
  ok("Nova is 12mm", cal("Items.Preset_Nova_Default"), "Power_12mm")
end
-- weights: stat on a real stack vs unscaled base
local p, ts = Game.GetPlayer(), Game.GetTransactionSystem()
local scales = EXPECT == "override" and
  {["Ammo.HandgunAmmo"]=2, ["Ammo.AO_9mm_Toxin"]=6, ["Ammo.AO_S10_Standard"]=1, ["Ammo.SniperRifleAmmo"]=0, ["Ammo.AO_127_HollowPoint"]=0, ["Ammo.AO_TLight_Slug"]=2, ["Ammo.AO_45_Ball"]=2}
  or {["Ammo.HandgunAmmo"]=1, ["Ammo.AO_9mm_Toxin"]=1, ["Ammo.AO_S10_Standard"]=1, ["Ammo.SniperRifleAmmo"]=1, ["Ammo.AO_127_HollowPoint"]=1, ["Ammo.AO_TLight_Slug"]=1, ["Ammo.AO_45_Ball"]=1}
for rec, k in pairs(scales) do
  if TweakDB:GetRecord(rec) then
    ts:GiveItemByTDBID(p, TweakDBID.new(rec), 1)
    local d = ts:GetItemData(p, ItemID.FromTDBID(TweakDBID.new(rec)))
    local w = d and d:GetStatValueByType(gamedataStatType.Weight) or -1
    local base = TweakDB:GetFlat(rec .. ".aoBaseWeight") or -1
    ok(rec .. " weight = base " .. string.format("%.3f", base) .. " x" .. k, string.format("%.4f", w), string.format("%.4f", base * k))
    if base <= 0 then ok(rec .. " has a base weight", base > 0, true) end
  else
    table.insert(out, "SKIP " .. rec .. " (no record)")
  end
end
table.insert(out, "fails " .. fails)
return table.concat(out, "\n")
