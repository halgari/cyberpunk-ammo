local function s(id) return id and TDBID.ToStringDEBUG(id) or "" end
local function loc(k) local ok,v=pcall(function() return Game.GetLocalizedTextByKey(k) end); return ok and (v or "") or "" end
local function enum(e) return (tostring(e):match(": ([%w_]+)")) or tostring(e) end
local function cls(id) local r=TweakDB:GetRecord(id); return r and r:GetClassName().value or "?" end
local f=io.open("parts.tsv","w")
-- one line per stat modifier / effector of every weapon part or mod
local function mods(owner, list, where)
  for _,m in ipairs(list or {}) do
    local mid=m:GetID(); local c=m:GetClassName().value
    local st=TweakDB:GetFlat(s(mid)..".statType"); local mt=TweakDB:GetFlat(s(mid)..".modifierType"); local v=TweakDB:GetFlat(s(mid)..".value")
    f:write(table.concat({owner,where,"mod",c,s(st),tostring(mt),tostring(v)},"\t").."\n")
  end
end
local function packages(owner, list, where)
  for _,p in ipairs(list or {}) do
    local pid=s(p:GetID())
    for _,e in ipairs(TweakDB:GetFlat(pid..".effectors") or {}) do
      local es=s(e); f:write(table.concat({owner,where,"effector",cls(e),es,"",""},"\t").."\n")
    end
    for _,sm in ipairs(TweakDB:GetFlat(pid..".stats") or {}) do
      local ss=s(sm); f:write(table.concat({owner,where,"pkgstat",cls(sm),s(TweakDB:GetFlat(ss..".statType")),tostring(TweakDB:GetFlat(ss..".modifierType")),tostring(TweakDB:GetFlat(ss..".value"))},"\t").."\n")
    end
  end
end
local n=0
for _,r in ipairs(TweakDB:GetRecords("gamedataItem_Record")) do
  local ok=pcall(function()
    local it=r:ItemType(); if not it then return end
    local t=enum(it:Type()); if not t:find("^Prt_") then return end
    local id=s(r:GetID()); n=n+1
    local name=loc(r:DisplayName()):gsub("[\t\n\r]"," ")
    f:write(table.concat({id,"info",t,name,loc(r:LocalizedDescription()):gsub("[\t\n\r]"," "),"",""},"\t").."\n")
    mods(id, r:StatModifiers(), "stat")
    for _,g in ipairs(r:StatModifierGroups() or {}) do mods(id, g:StatModifiers(), "group") end
    packages(id, r:OnAttach(), "onAttach")
    packages(id, r:OnEquip(), "onEquip")
  end)
end
f:close()
print("parts", n)
