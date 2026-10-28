-- Quick check that the mod loaded: the Lexington is patched, the records exist, the feed system is
-- up and the text resolves. Direct lookups only: looping over TweakDB:GetRecords for every weapon
-- record froze the game under Proton (CET 1.38, 2.50).
--   tools/linux/cet.sh -f tools/snippets/mod-check.lua
print("lex ammo", TweakDB:GetFlat("Items.Preset_Lexington_Default.ammo"))
print("lex blueprint", TweakDB:GetFlat("Items.Preset_Lexington_Default.blueprint"))
print("records", TweakDB:GetRecord("Ammo.AO_9mm_HollowPoint") ~= nil,
      TweakDB:GetRecord("AttachmentSlots.AO_AmmoFeed_Tech_Light") ~= nil,
      TweakDB:GetRecord("Items.AO_Feed_10mm_Dumbfires") ~= nil)
print("system", Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem") ~= nil)
print("loc", GetLocalizedTextByKey("AO-Slot-AmmoFeed"))
