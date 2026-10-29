-- Gives one of each selector in SELS and 60 of the round it feeds: the selector sync keeps a
-- selector only while its ammo is held. Set SELS = {'Items.AO_Feed_...', ...} before this.
for _, sel in ipairs(SELS) do
  Game.AddToInventory(sel, 1)
  for _, cal in ipairs(TweakDB:GetFlat('AmmoOverhaul.calibers')) do
    local ammo = TweakDB:GetFlat('AmmoOverhaul.'..cal..'.selectorAmmo')
    for i, s in ipairs(TweakDB:GetFlat('AmmoOverhaul.'..cal..'.selectors')) do
      if TDBID.ToStringDEBUG(s) == sel then Game.AddToInventory(TDBID.ToStringDEBUG(ammo[i]), 60) end
    end
  end
end
