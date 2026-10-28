-- Task 4: the weapon screen's Ammo section, as last built (open Inventory -> a slice gun first).
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local ok, d = pcall(function() return sys:DebugAmmoSection() end)
check("DebugAmmoSection exists", ok, tostring(d))
if ok then
  check("section built", d ~= "", "no section built yet: open Inventory and a slice gun's screen")
  if d ~= "" then
    print(d)
    local a, m, mo = d:match("attachments (%-?%d+) ammo (%-?%d+) mods (%-?%d+)")
    a, m, mo = tonumber(a), tonumber(m), tonumber(mo)
    check("label reads Ammo", d:match("| label (.*)$") == "Ammo", d:match("| label (.*)$"))
    check("one feed slot", select(2, d:gsub("AO_AmmoFeed_", "")) == 1, d)
    check("Ammo before Mods", m and mo and m < mo, d)
    check("Attachments before Ammo (or in another parent)", a and (a == -1 or a < m), d)
  end
end
report()
