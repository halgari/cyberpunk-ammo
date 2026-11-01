"""Fails unless every UIIcon atlasPartName in the mod's YAML has a cell in the built atlas
(art/build/ao_ammo_icons.uvs.json, from make_icons.py), every Rare and up round (faction rounds
included) has its part, and the cells all fit the atlas without overlapping. Run after
tools/icons/build.sh.

  python3 tools/icons/check_parts.py
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
uvs = json.loads((ROOT / "art/build/ao_ammo_icons.uvs.json").read_text())
parts = set()
for y in sorted((ROOT / "src/tweaks/AmmoOverhaul").glob("*.yaml")):
    parts |= set(re.findall(r"atlasPartName:\s*(\S+)", y.read_text()))
missing = sorted(p for p in parts if p not in uvs)
for p in sorted(parts):
    print(("FAIL " if p in missing else "PASS ") + p + " has an atlas cell")
rounds = json.loads((ROOT / "tools/render/rounds_tiers.json").read_text())["rounds"]
tier_parts = {"ao_" + n.removeprefix("hack-").replace("-", "_") for n in rounds}
unused = sorted(tier_parts - parts)
absent = sorted(tier_parts - set(uvs))
for p in unused + absent:
    print(f"FAIL {p} is a round in rounds_tiers.json with no icon part")
print(f"{'FAIL' if unused or absent else 'PASS'} all {len(tier_parts)} tiered rounds have parts")
cells = [(r["Left"], r["Top"]) for r in uvs.values()]
outside = sorted(p for p, r in uvs.items() if not (0 <= r["Left"] < r["Right"] <= 1 and 0 <= r["Top"] < r["Bottom"] <= 1))
overlap = len(cells) - len(set(cells))
for p in outside:
    print(f"FAIL {p}'s cell is outside the atlas")
print(f"{'FAIL' if overlap else 'PASS'} {len(cells)} cells, {overlap} overlapping")
bad = len(missing) + len(unused) + len(absent) + len(outside) + bool(overlap)
print(f"== atlas parts: {len(parts) - len(missing)} pass, {bad} fail")
sys.exit(1 if bad or not parts else 0)
