local function s(id) return id and TDBID.ToStringDEBUG(id) or "" end
local function loc(k) local ok,v=pcall(function() return Game.GetLocalizedTextByKey(k) end); return ok and v or "" end
local f=io.open("weapons.tsv","w")
local n=0
for _,r in ipairs(TweakDB:GetRecords("gamedataWeaponItem_Record")) do
  local ok,err=pcall(function()
    local id=s(r:GetID())
    local evo=r:Evolution() and tostring(r:Evolution():Type()):match(": (%w+)") or ""
    local typ=r:ItemType() and tostring(r:ItemType():Type()):match(": ([%w_]+)") or ""
    local man=r:Manufacturer() and s(r:Manufacturer():GetID()) or ""
    local ammo=r:Ammo() and s(r:Ammo():GetID()) or ""
    local tags={} for _,t in ipairs(r:Tags()) do table.insert(tags, Game.NameToString(t)) end
    local q=r:Quality() and s(r:Quality():GetID()) or ""
    local name=loc(r:DisplayName()):gsub("[\t\n\r]"," ")
    local desc=loc(r:LocalizedDescription()):gsub("[\t\n\r]"," ")
    f:write(table.concat({id,typ,evo,man,ammo,q,name,desc,table.concat(tags,",")},"\t").."\n")
    n=n+1
  end)
  if not ok then f:write("ERR\t"..tostring(err).."\n") end
end
f:close()
print("wrote", n)
