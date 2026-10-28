"""Builds the ammo icon atlas texture from the source art in art/icons.

Each source image is a cut-out on a transparent background. It's cropped to what's visible and
fitted (keeping its shape) into a cell of
the vanilla ammo icon's proportions (124x78 at 2048, so 248x156 here for a sharper 4K slot).
The atlas is saved with premultiplied alpha, as the game expects.
Writes art/build/ao_ammo_icons.png and each part's UV rect (art/build/ao_ammo_icons.uvs.json)
for the .inkatlas.

  python3 tools/icons/make_icons.py
"""
import json
import pathlib
from PIL import Image, ImageChops

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "art" / "icons"
OUT = ROOT / "art" / "build"
CELL = (248, 156)
# Empty margin kept around the art inside its square (fraction of the cell's height).
PAD = 0.08
ATLAS = (2048, 1024)   # 8 x 4 cells of 256 x 160
COLS = 8
# Source art (art/icons/<name>.png, rendered by tools/render/render.py), one per round. The part is
# "ao_" + the name with "-" as "_" (9mm-ball -> ao_9mm_ball), matching UIIcon.AO_* and the feed selector.
NAMES = [
    "9mm-ball", "9mm-mushrooms", "45-ball", "45-mushrooms", "12mm-ball", "12mm-mushrooms", "556-ball",
    "556-mushrooms", "762-ball", "762-mushrooms", "127-ball", "127-mushrooms", "12ga-buckshot", "12ga-slugs",
    "4ga-buckshot", "4ga-slugs", "5mm-railslugs", "5mm-sleevers", "heavy-railslugs", "heavy-sleevers",
    "10mm-seekers", "10mm-dumbfires", "20mm-seekers", "20mm-dumbfires", "25mm-seekers", "25mm-dumbfires",
]
PARTS = {"ao_" + n.replace("-", "_"): n + ".png" for n in NAMES}


def cut_out(path):
    im = Image.open(path).convert("RGBA")
    # Crop to what's visible (ignoring faint alpha fringe).
    solid = im.getchannel("A").point(lambda v: 255 if v > 16 else 0)
    return im.crop(solid.getbbox())


def fit(im):
    # The backpack tile shows a cell at its full height with room for only a square of it, so
    # the art is kept inside the centred CELL[1] x CELL[1] square (wider art stuck out of the tile).
    room = CELL[1] - 2 * round(CELL[1] * PAD)
    scale = min(room / im.width, room / im.height)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    cell = Image.new("RGBA", CELL, (0, 0, 0, 0))
    cell.alpha_composite(im, ((CELL[0] - im.width) // 2, (CELL[1] - im.height) // 2))
    return cell


def premultiply(im):
    # The game draws UI textures as premultiplied alpha (vanilla atlases store colour × alpha);
    # straight alpha leaves a bright, off-colour fringe on every soft edge.
    r, g, b, a = im.split()
    return Image.merge("RGBA", [ImageChops.multiply(c, a) for c in (r, g, b)] + [a])


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", ATLAS, (0, 0, 0, 0))
    uvs = {}
    for i, (part, src) in enumerate(PARTS.items()):
        x, y = (i % COLS) * 256, (i // COLS) * 160
        atlas.alpha_composite(fit(cut_out(SRC / src)), (x, y))
        uvs[part] = {"Left": x / ATLAS[0], "Top": y / ATLAS[1],
                     "Right": (x + CELL[0]) / ATLAS[0], "Bottom": (y + CELL[1]) / ATLAS[1]}
    premultiply(atlas).save(OUT / "ao_ammo_icons.png")
    (OUT / "ao_ammo_icons.uvs.json").write_text(json.dumps(uvs, indent=1))


if __name__ == "__main__":
    main()
