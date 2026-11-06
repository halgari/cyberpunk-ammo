#!/usr/bin/env bash
# Vanilla magazine refunds keep the gun's round (MagRefill.reds): Shinobi 50's 20% on a dash or
# slide (CeaselessLeadAmmoEffector) and ValentinosFrenzyEffector, run through the dev subclasses
# in tools/dev-scripts/AODevRefill.reds. Gives V a Lexington, two Unitys and their selectors and
# buys the dual wield perk, in the running session only: not while the user plays, and don't save
# after. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets/calibers
fails=0
lua() { $C -t 20 "$(cat $S/dual.lua); $1" 2>&1 | sed -n 's/^=> //p;/rror/p' | tail -1; }
want() { # name expected actual
  if [[ "$3" == "$2" ]]; then echo "PASS $1 ($3)"; else echo "FAIL $1: got '$3', want '$2'"; fails=$((fails + 1)); fi
}
restored() { lua 'local n = 0; for _ in string.gmatch(Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):Trail(), "engine restored") do n = n + 1 end; return tostring(n)'; }
# The drawn gun's real rounds, and whether it's loaded with $1 (its total is that round's stack).
state() { lua "local w = DW.right(); return DW.mag(w) .. ' ' .. tostring(w:GetTotalAmmoCount() == DW.qty('$1'))"; }
feed() { $C "FEED='$1'; $(cat tools/snippets/set-feed.lua)" >/dev/null; sleep 5; }
# Fills the drawn gun, then spends one real shot and the rest down to $1 rounds.
spend() {
  lua "DW.reload(DW.right()); return 1" >/dev/null; sleep 2
  lua "DW.shot(DW.right()); return 1" >/dev/null; sleep 1
  lua "local w = DW.right(); DW.consume(w, DW.mag(w) - $1); return 1" >/dev/null; sleep 1
}
shinobi() { lua "AODevCeaselessLead.new():Run(Game.GetPlayer(), 0.2); return 1" >/dev/null; sleep 2; }

# One gun: a Lexington (20 rounds, so 4 back) on hollow points.
for _ in 1 2; do $C "GUN='Items.Preset_Lexington_Default'; $(cat tools/snippets/feed-kit.lua)" >/dev/null; sleep 4; done
H=Ammo.AO_9mm_HollowPoint
# The refund comes out of the stack, so give each round its own (earlier suite steps spend them).
lua "DW.set('$H', 60); DW.set('Ammo.HandgunAmmo', 60); return 1" >/dev/null; sleep 1
feed Items.AO_Feed_9mm_Mushrooms
before=$(restored)
spend 8
want "hollow points spent to 8" "8 true" "$(state $H)"
shinobi
want "Shinobi gives 4 hollow points back" "12 true" "$(state $H)"
want "and the gun isn't unloaded" "$before" "$(restored)"
lua "DW.reload(DW.right()); return 1" >/dev/null; sleep 2
shinobi
want "a full magazine gets nothing" "20 true" "$(state $H)"
spend 8
lua "AODevValentinosFrenzy.new():Run(Game.GetPlayer(), 3); return 1" >/dev/null; sleep 2
want "Valentinos refund gives 3 hollow points back" "11 true" "$(state $H)"
want "and the gun isn't unloaded" "$before" "$(restored)"

# The default round worked before the fix and still does.
feed Items.AO_Feed_9mm_Ball
spend 8
shinobi
want "Ball gets 4 back" "12 true" "$(state Ammo.HandgunAmmo)"

# Dual wield: two Unitys (10 rounds, so 2 back each) on .45 hollow points.
want "dual wield perk" true "$(lua "return DW.perk()")"
U=Items.Preset_Unity_Default; A=Ammo.AO_45_HollowPoint
[[ -n "$(lua "return #DW.items('$U') >= 2 and 'y' or nil")" ]] || { lua "DW.give('$U'); return 1" >/dev/null; sleep 2; }
lua "for _ = 1, 2 do Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), ItemID.FromTDBID(TweakDBID.new('Items.AO_Feed_45_Mushrooms')), 1) end; DW.set('$A', 60); return 1" >/dev/null; sleep 2
# One at a time: the two selectors are one stack, and each install takes one.
for i in 1 2; do
  lua "local slot = TweakDB:GetFlat('Items.AO_Feed_45_Mushrooms.placementSlots')[1]
    local r = InstallItemPart.new(); r.obj = Game.GetPlayer(); r.baseItem = DW.items('$U')[$i]
    r.partToInstall = DW.items('Items.AO_Feed_45_Mushrooms')[1]; r.slotID = slot
    Game.GetScriptableSystemsContainer():Get('ItemModificationSystem'):QueueRequest(r); return 1" >/dev/null; sleep 3
done
lua "return DW.equip('$U')" >/dev/null; sleep 6
lua "local r, l = DW.right(), DW.left(); DW.reload(r); DW.reload(l); return 1" >/dev/null; sleep 3
lua "local r, l = DW.right(), DW.left(); DW.consume(r, DW.mag(r) - 5); DW.consume(l, DW.mag(l) - 5); return 1" >/dev/null; sleep 2
# Each gun's rounds and its stack, which shows the round it's loaded with: in dual wield only one
# gun is watched for a changed round, so the other would keep the wrong one quietly.
pair() { lua "local r, l = DW.right(), DW.left(); return DW.mag(r) .. ' ' .. DW.mag(l) .. ' ' .. r:GetTotalAmmoCount() .. ' ' .. l:GetTotalAmmoCount()"; }
set -- $(pair)
want "the pair spent to 5 each" "5 5" "$1 $2"
want "both on hollow points" "true" "$(lua "return tostring(DW.right():GetTotalAmmoCount() > 0 and DW.left():GetTotalAmmoCount() > 0)")"
before=$(restored); totals="$3 $4"
shinobi
set -- $(pair)
want "Shinobi gives 2 back to each gun" "7 7" "$1 $2"
want "and both keep their round" "$totals" "$3 $4"
want "and neither is unloaded" "$before" "$(restored)"

echo "== refill: $fails fail(s)"
(( fails == 0 ))
