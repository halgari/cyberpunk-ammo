"""Builds the ammo icon atlas texture from the source art in art/icons.

Each source image is a cut-out on a transparent background. It's cropped to what's visible and
fitted (keeping its shape) edge to edge into a square cell, as the game's own item icons are
(mostly 160x160 parts cropped tight to the art). The game draws a part at its pixel size in the
atlas's 4K texture, not scaled to the slot, so the cell is vanilla's 160x160: 256 overflowed the
backpack slot, and art in a 131px square looked small.
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
CELL = (160, 160)
# Empty margin kept around the art (fraction of the cell): just enough that soft edges aren't cut.
PAD = 0.02
ATLAS = (1024, 2048)   # 6 x 12 cells of 160 x 160 (39 used)
COLS = 6
# Source art (art/icons/<name>.png, rendered by tools/render/render.py), one per round. The part is
# "ao_" + the name with "-" as "_" (9mm-ball -> ao_9mm_ball), matching UIIcon.AO_* and the feed selector.
NAMES = [
    "9mm-ball", "9mm-mushrooms", "45-ball", "45-mushrooms", "12mm-ball", "12mm-mushrooms", "556-ball",
    "556-mushrooms", "762-ball", "762-mushrooms", "127-ball", "127-mushrooms", "12ga-buckshot", "12ga-slugs",
    "4ga-buckshot", "4ga-slugs", "5mm-railslugs", "5mm-sleevers", "heavy-railslugs", "heavy-sleevers",
    "10mm-seekers", "10mm-dumbfires", "20mm-seekers", "20mm-dumbfires", "25mm-seekers", "25mm-dumbfires",
    "9mm-plusp", "45-plusp", "12mm-plusp", "556-plusp", "762-plusp", "127-plusp", "12ga-birdshot", "4ga-birdshot",
    "5mm-bricks", "heavy-bricks", "10mm-shortfuse", "20mm-shortfuse", "25mm-shortfuse",
]
PARTS = {"ao_" + n.replace("-", "_"): n + ".png" for n in NAMES}
# Midtone lift (a gamma on each channel). The renders are darker than the game's own icons (mean
# luminance 56 against about 89 for the vanilla item atlas), which reads as greyed out in the
# backpack; 0.65 brings them to about 88 and keeps the highlights.
LIFT = 0.65


def lift(im):
    lut = [min(255, round(255 * (v / 255) ** LIFT)) for v in range(256)]
    return Image.merge("RGBA", [c.point(lut) for c in im.split()[:3]] + [im.getchannel("A")])


def cut_out(path):
    im = lift(Image.open(path).convert("RGBA"))
    # Crop to what's visible (ignoring faint alpha fringe).
    solid = im.getchannel("A").point(lambda v: 255 if v > 16 else 0)
    return im.crop(solid.getbbox())


def fit(im):
    # Square cells: the backpack tile shows a cell at its full height with room for only a square
    # of it (art in a wider cell stuck out of the tile), so the art fills the square instead.
    room = CELL[0] - 2 * round(CELL[0] * PAD)
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
        x, y = (i % COLS) * CELL[0], (i // COLS) * CELL[1]
        atlas.alpha_composite(fit(cut_out(SRC / src)), (x, y))
        uvs[part] = {"Left": x / ATLAS[0], "Top": y / ATLAS[1],
                     "Right": (x + CELL[0]) / ATLAS[0], "Bottom": (y + CELL[1]) / ATLAS[1]}
    premultiply(atlas).save(OUT / "ao_ammo_icons.png")
    (OUT / "ao_ammo_icons.uvs.json").write_text(json.dumps(uvs, indent=1))


if __name__ == "__main__":
    main()
