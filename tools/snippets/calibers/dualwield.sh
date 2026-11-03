#!/usr/bin/env bash
# Two guns on one round never hold more than the stack (DualWield.reds). Buys V the dual wield
# perk and gives two Unitys and two Nues, in the running session only: not while the user plays,
# and don't save after. Run after a restart: the first check needs guns that were never drawn.
# Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets/calibers
G=${GUN:-Items.Preset_Unity_Default}; A=${AMMO:-Ammo.AO_45_Ball}
fails=0
lua() { $C -t 20 "$(cat $S/dual.lua); $1" 2>&1 | sed -n 's/^=> //p;/rror/p' | tail -1; }
want() { # name expected actual
  if [[ "$3" == "$2" ]]; then echo "PASS $1 ($3)"; else echo "FAIL $1: got '$3', want '$2'"; fails=$((fails + 1)); fi
}
state() { drawn; lua "return DW.state('$A')"; }
# The gun holsters on its own after a while out of combat.
drawn() {
  for _ in $(seq 6); do
    [[ $(lua "return (DW.left() and DW.right()) and 'y' or 'n'") == y ]] && return
    lua "return DW.equip('$G')" >/dev/null; sleep 4
  done
}
# Both magazines empty, guns drawn, then a stack of $1 with the right gun reloading from it. Empty
# guns also reload on their own once there are rounds, so both get the same chance.
prep() {
  drawn
  lua "DW.set('$A', 0); return 1" >/dev/null; sleep 1
  lua "local r, l = DW.right(), DW.left(); DW.consume(r, DW.mag(r)); DW.consume(l, DW.mag(l)); return 1" >/dev/null; sleep 2
  lua "DW.set('$A', $1); return 1" >/dev/null
}
# Reloads both guns in one frame until one takes rounds; a gun that's drawing or lowered ignores it.
both() {
  for try in 1 2 3 4 5 6; do
    drawn
    lua "local r, l = DW.right(), DW.left(); DW.reload(r); DW.reload(l); return 1" >/dev/null; sleep 2
    [[ $(lua "return DW.mag(DW.right()) + DW.mag(DW.left())") != 0 ]] && { [[ $try == 1 ]] || echo "  ($try tries)"; return; }
  done
}
# Pulls the trigger $2 times on gun $1 (right or left), every 0.7 s. A pull during a draw fires
# nothing, so the cases that run a gun dry pull a few extra.
fire() { for _ in $(seq "$2"); do drawn; lua "DW.shot(DW.$1()); return 1" >/dev/null; sleep 0.7; done; sleep 1; }

want "dual wield perk" true "$(lua "return DW.perk()")"
# Two fresh 10-round guns from the inventory, 15 rounds: no reload, no shot, and they show 15.
N=Items.Preset_Nue_Default
if [[ $(lua "return #DW.items('$N')") == 0 ]]; then
  lua "DW.set('$A', 15); DW.give('$N'); return 1" >/dev/null; sleep 2
  lua "return DW.equip('$N')" >/dev/null; sleep 5
  want "fresh pair shows the stack on the draw" "15 10 5" "$(lua "return DW.state('$A')")"
  lua "DW.reload(DW.left()); return 1" >/dev/null; sleep 2
  want "and stays there" "15 10 5" "$(lua "return DW.state('$A')")"
fi
[[ -n "$(lua "return #DW.items('$G') >= 2 and 'y' or nil")" ]] || { lua "DW.give('$G'); return 1" >/dev/null; sleep 2; }
lua "DW.set('$A', 40); return DW.equip('$G')" >/dev/null; sleep 6
cap=$(lua "return tostring(WeaponObject.GetMagazineCapacity(DW.right()))")

prep "$cap"
lua "DW.reload(DW.right()); return 1" >/dev/null; sleep 3
s=$(state); set -- $s
want "the pair holds the stack, no more" "$cap" "$(($2 + $3))"
want "right can't reload" false "$(lua "return WeaponObject.CanReload(DW.right())")"
want "left can't reload" false "$(lua "return WeaponObject.CanReload(DW.left())")"
lua "DW.reload(DW.left()); return 1" >/dev/null; sleep 2
s=$(state); set -- $s
want "a forced reload is given back" "$cap" "$(($2 + $3))"
fire right "$(($2 + 2))"; fire left "$(($3 + 2))"
want "they fire the stack and no more" "0 0 0" "$(state)"

prep "$cap"
both
s=$(state); set -- $s
want "both reloading at once share the stack" "$cap" "$(($2 + $3))"
fire right "$(($2 + 3))"; fire left "$(($3 + 3))"
want "and fire exactly that many" "0 0 0" "$(state)"

# A part-loaded pair, stack 6: a bigger stack only tops up what's free.
prep 6
both
s=$(state); set -- $s
want "stack of 6 in the pair" 6 "$(($2 + $3))"
drawn
lua "DW.set('$A', 10); return 1" >/dev/null; sleep 1
lua "DW.reload(DW.right()); DW.reload(DW.left()); return 1" >/dev/null; sleep 3
s=$(state); set -- $s
want "reloads take only what's free" 10 "$(($2 + $3))"

# Plenty of rounds: nothing changes.
prep $((cap * 3))
lua "DW.reload(DW.right()); DW.reload(DW.left()); return 1" >/dev/null; sleep 3
want "big stack fills both" "$((cap * 3)) $cap $cap" "$(state)"
fire right 3; fire left 2
want "shots still count" "$((cap * 3 - 5)) $((cap - 3)) $((cap - 2))" "$(state)"

# A stack that shrank under a loaded pair: the next shot puts it right.
drawn
lua "DW.set('$A', 4); return 1" >/dev/null; sleep 1
fire right 1
s=$(state); set -- $s
echo "  stale: $s"
want "stale magazines trimmed on the next shot" true "$( (($2 + $3 <= $1)) && echo true || echo false)"

# Different rounds in each hand are two stacks: no cap. Fitting a round to a part-used gun really
# empties it, without a redraw.
drawn
lua "DW.set('$A', 20); return 1" >/dev/null; sleep 1
both
fire right 2
drawn
echo "  before the fit: $(state)"
# Owning a round is what gives its selector.
lua "DW.set('Ammo.AO_45_HollowPoint', 40); return 1" >/dev/null; sleep 4
echo "  fit: $($C -t 15 "FEED='Items.AO_Feed_45_Mushrooms'; $(cat tools/snippets/set-feed.lua)" | tail -1)"; sleep 6
drawn
want "switching rounds empties the magazine" 0 "$(lua "return DW.mag(DW.right())")"
lua "DW.set('$A', 12); return 1" >/dev/null; sleep 1
both
want "different rounds aren't capped" "$cap $cap" "$(lua "return DW.mag(DW.right()) .. ' ' .. DW.mag(DW.left())")"
$C "SLOT='AttachmentSlots.AO_AmmoFeed_Power_45'; $(cat tools/snippets/set-feed.lua)" >/dev/null

echo "fails: $fails"
exit $((fails > 0))
