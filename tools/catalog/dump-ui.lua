local function s(id) return id and TDBID.ToStringDEBUG(id) or "" end
local f=io.open("ui.tsv","w")
for _,p in ipairs(TweakDB:GetRecords("gamedataGameplayLogicPackage_Record")) do
  pcall(function()
    local ui=p:UIData(); if not ui then return end
    local d=Game.GetLocalizedText(ui:LocalizedDescription()) or ""
    if d=="" then return end
    local fv={} for _,v in ipairs(ui:FloatValues() or {}) do table.insert(fv,string.format("%.3g",v)) end
    local iv={} for _,v in ipairs(ui:IntValues() or {}) do table.insert(iv,tostring(v)) end
    f:write(s(p:GetID()).."\t"..d:gsub("[\t\n\r]"," ").."\t"..table.concat(fv,",").."\t"..table.concat(iv,",").."\n")
  end)
end
f:close() print("ok")
