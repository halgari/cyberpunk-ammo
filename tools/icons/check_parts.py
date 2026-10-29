"""Fails unless every UIIcon atlasPartName in the mod's YAML has a cell in the built atlas
(art/build/ao_ammo_icons.uvs.json, from make_icons.py). Run after tools/icons/build.sh.

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
print(f"== atlas parts: {len(parts) - len(missing)} pass, {len(missing)} fail")
sys.exit(1 if missing or not parts else 0)
