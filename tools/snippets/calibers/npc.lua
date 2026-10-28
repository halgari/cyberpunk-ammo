-- v1 calibers: each AO_Test NPC carries only its gun's caliber round: the Common one, or with
-- UNCOMMON=true (roll forced on) the Uncommon one. Run by npc.sh after the NPCs drew. Sets
-- AO_EXPECT for slice/npcloot.lua.
local ts = Game.GetTransactionSystem()
local cals = {}
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local tags, recs, ammo = {}, {}, {}
  for _, t in ipairs(flat("AmmoOverhaul." .. c, "weaponTags") or {}) do tags[type(t) == "string" and t or t.value] = true end
  for _, r in ipairs(flat("AmmoOverhaul." .. c, "weaponRecords") or {}) do recs[type(r) == "string" and r or str(r)] = true end
  for _, a in ipairs(flat("AmmoOverhaul." .. c, "selectorAmmo") or {}) do table.insert(ammo, type(a) == "string" and a or str(a)) end
  table.insert(cals, { name = c, tags = tags, recs = recs, ammo = ammo })
end
local function caliberOf(gun)
  local r = TweakDB:GetRecord(gun)
  for _, c in ipairs(cals) do
    if c.recs[str(gun)] then return c end
    for _, t in ipairs(r:Tags()) do if c.tags[t.value] then return c end end
  end
end
AO_EXPECT = {}
local seen = {}
for _, npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do
  local recName = str(npc:GetRecordID())
  local w = ScriptedPuppet.GetActiveWeapon(npc)
  if w then
    local c = caliberOf(w:GetItemID().id)
    local ammo = {}
    local _, items = ts:GetItemList(npc)
    for _, it in ipairs(items or {}) do
      local n = str(it:GetID().id)
      if n:find("^Ammo%.") then ammo[n] = ts:GetItemQuantity(npc, it:GetID()) end
    end
    local stacks = {}
    for n, q in pairs(ammo) do table.insert(stacks, n .. " " .. q) end
    print(recName .. " | " .. str(w:GetItemID().id) .. " | " .. (c and c.name or "unmanaged") .. " | " .. table.concat(stacks, ", "))
    check(recName .. " gun is managed", c ~= nil, str(w:GetItemID().id))
    if c then
      seen[c.name] = true
      local expected = UNCOMMON and c.ammo[2] or c.ammo[1]
      AO_EXPECT[tostring(npc:GetEntityID().hash)] = { name = recName, ammo = expected }
      check(recName .. " carries " .. c.name .. " rounds", (ammo[expected] or 0) > 0, "expected " .. expected)
      local others = {}
      for n in pairs(ammo) do if n ~= expected then table.insert(others, n) end end
      check(recName .. " carries no other round", #others == 0, table.concat(others, ", "))
    end
  end
end
for _, c in ipairs(WANT or {}) do check("an NPC of " .. c .. " drew", seen[c], "none") end
report()
