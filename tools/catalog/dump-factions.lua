-- Weapons carried by each faction's NPCs: for every character record, its affiliation and the
-- guns in its primary/secondary equipment (groups, pools and items, followed recursively).
-- Writes factions.tsv (affiliation, character, rarity, weapon record) next to the harness.
local function s(id) return id and TDBID.ToStringDEBUG(id) or "" end
local function cls(id) local r=TweakDB:GetRecord(id); return r and r:GetClassName().value or "" end
local function collect(id, out, depth)
  if depth > 6 or not id then return end
  local c = cls(id)
  if c == "gamedataNPCEquipmentGroup_Record" then
    for _, e in ipairs(TweakDB:GetFlat(s(id)..".equipmentItems") or {}) do collect(e, out, depth+1) end
  elseif c == "gamedataNPCEquipmentItemPool_Record" then
    for _, e in ipairs(TweakDB:GetFlat(s(id)..".pool") or {}) do collect(e, out, depth+1) end
  elseif c == "gamedataNPCEquipmentItemsPoolEntry_Record" then
    for _, e in ipairs(TweakDB:GetFlat(s(id)..".items") or {}) do collect(e, out, depth+1) end
  elseif c == "gamedataNPCEquipmentItem_Record" then
    local item = TweakDB:GetFlat(s(id)..".item")
    if item then table.insert(out, s(item)) end
  end
end
local f = io.open("factions.tsv", "w")
for _, r in ipairs(TweakDB:GetRecords("gamedataCharacter_Record")) do
  pcall(function()
    local id = s(r:GetID())
    local aff = TweakDB:GetFlat(id..".affiliation")
    local rar = TweakDB:GetFlat(id..".rarity")
    local guns = {}
    collect(TweakDB:GetFlat(id..".primaryEquipment"), guns, 0)
    collect(TweakDB:GetFlat(id..".secondaryEquipment"), guns, 0)
    for _, g in ipairs(guns) do
      f:write(s(aff).."\t"..id.."\t"..s(rar).."\t"..g.."\n")
    end
  end)
end
f:close()
print("ok")
