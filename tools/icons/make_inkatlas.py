"""Writes the .inkatlas json for the ammo icons from a vanilla atlas json (the template).

  python3 tools/icons/make_inkatlas.py <vanilla .inkatlas.json> <uvs.json> <texture depot path> <out .json>

Both resolution slots point at the one texture; the parts are the UV rects from make_icons.py.
"""
import copy
import json
import sys

template, uvs_path, texture, out = sys.argv[1:5]
doc = json.load(open(template))
uvs = json.load(open(uvs_path))
root = doc["Data"]["RootChunk"]
slots = root["slots"]["Elements"]
mapper = copy.deepcopy(slots[0]["parts"][0])
parts = []
for name, rect in uvs.items():
    part = copy.deepcopy(mapper)
    part["partName"]["$value"] = name
    for key in ("Left", "Top", "Right", "Bottom"):
        part["clippingRectInUVCoords"][key] = rect[key]
    parts.append(part)
for slot in slots[:2]:
    slot["parts"] = copy.deepcopy(parts)
    slot["texture"]["DepotPath"] = {"$type": "ResourcePath", "$storage": "string", "$value": texture}
doc["Header"]["ArchiveFileName"] = ""
json.dump(doc, open(out, "w"), indent=1)
