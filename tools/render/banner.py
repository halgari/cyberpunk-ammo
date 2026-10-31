"""The Nexus page images, 16:9, from the round art (art/icons/*.png, rendered by render.py):

  python3 tools/render/banner.py [--title TITLE.png]

  art/banner/background-8k.png, background-4k.png: the rounds' boxes, 16 x 9 on a dark ground,
    in caliber order (Power, Tech, Smart; Common to Legendary within each), the last row centred.
  The 8K files aren't committed (.gitignore); rerun to get them.
  art/banner/main-8k.png, main-4k.png, main-4k.jpg (with --title): the background, darkened behind the title,
    with TITLE.png (a transparent 8K render, tools/render/title.py) on top.
"""
import argparse
import json
import pathlib
import re

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "art" / "icons"
OUT = ROOT / "art" / "banner"
W, H = 7680, 4320
COLS, ROWS = 16, 9
# Legendary rounds are for players to find: the page shows only the two the public text names.
UNNAMED = ("gatecrasher", "cookoff", "lockout", "mulekick")
# Power, Tech, Smart, by the caliber prefix of the icon file names.
CALIBERS = ["9mm", "45", "12mm", "556", "762", "127", "12ga", "4ga", "5mm", "heavy", "10mm", "20mm", "25mm"]


def order(names):
    """Caliber order, then render.py's order within a caliber (Common, Uncommon, then Rare and Epic)."""
    here = pathlib.Path(__file__).parent
    listed = re.findall(r'^    "([a-z0-9-]+)": \(', (here / "render.py").read_text(), re.M)
    listed += list(json.loads((here / "rounds_tiers.json").read_text())["rounds"])
    rank = {n: i for i, n in enumerate(listed)}
    return sorted(names, key=lambda n: (CALIBERS.index(n.split("-", 1)[0]), rank.get(n, len(rank)), n))


def ground():
    """Charcoal with a soft light from the top centre."""
    g = Image.new("RGB", (W, H), (14, 15, 17))
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((-W * 0.2, -H * 0.6, W * 1.2, H * 1.1), fill=60)
    glow = glow.filter(ImageFilter.GaussianBlur(H // 5))
    g = Image.composite(Image.new("RGB", (W, H), (40, 42, 46)), g, glow)
    return g


def background():
    names = order([p.stem for p in ART.glob("*.png")
                   if not p.stem.endswith("-ref") and not p.stem.endswith(UNNAMED)])
    assert COLS * (ROWS - 1) < len(names) <= COLS * ROWS, f"{len(names)} icons for {COLS * ROWS} cells"
    i = names.index("12ga-pumpndump")   # one cell on, clear of the title
    names[i], names[i + 1] = names[i + 1], names[i]
    img = ground().convert("RGBA")
    cw, ch = W / COLS, H / ROWS
    # The boxes fill about 760 x 505 of their 1024 tile: scale the tile so a box fills ~92% of a cell.
    side = round(min(cw / 760, ch / 505) * 0.92 * 1024)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    boxes = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for i, n in enumerate(names):
        r, c = divmod(i, COLS)
        if r == ROWS - 1:   # the last, short row centred
            c += (COLS * ROWS - len(names)) / 2
        icon = Image.open(ART / f"{n}.png").convert("RGBA").resize((side, side), Image.LANCZOS)
        x = round(c * cw + cw / 2 - side / 2)
        y = round(r * ch + ch / 2 - side / 2)
        a = icon.getchannel("A").point(lambda v: v * 0.55)
        shadow.paste(Image.new("RGBA", icon.size, (0, 0, 0, 255)), (x + side // 40, y + side // 28), a)
        boxes.alpha_composite(icon, (x, y))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(side // 30)))
    img.alpha_composite(boxes)
    return img.convert("RGB")


def compose(bg, title):
    """The background with the title on top: darkened and blurred behind the letters, the bar glowing."""
    # Darken and blur the boxes behind the title so it reads: a soft band from its alpha.
    band = title.getchannel("A").filter(ImageFilter.MaxFilter(51)).filter(ImageFilter.GaussianBlur(bg.size[1] // 12))
    dark = bg.filter(ImageFilter.GaussianBlur(12)).point(lambda v: v * 0.28)
    main_img = Image.composite(dark, bg, band.point(lambda v: min(255, v * 2)))
    main_img = main_img.convert("RGBA")
    # A neon glow off the cyan bar: its pixels, blurred wide and added under the letters.
    r, g, b, a = title.split()
    cyan = Image.eval(Image.merge("RGB", (r, g, b)).convert("HSV").getchannel("S"), lambda v: 255 if v > 150 else 0)
    cyan = ImageChops.multiply(ImageChops.multiply(cyan, b), a)
    glow = Image.merge("RGB", (cyan.point(lambda v: v * 0.1), cyan.point(lambda v: v * 0.85), cyan))
    glow = ImageChops.add(glow.filter(ImageFilter.GaussianBlur(bg.size[1] // 60)), glow.filter(ImageFilter.GaussianBlur(bg.size[1] // 18)))
    main_img = Image.merge("RGBA", (*ImageChops.add(main_img.convert("RGB"), glow).split(), Image.new("L", bg.size, 255)))
    main_img.alpha_composite(title)
    main_img = main_img.convert("RGB")
    return main_img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--title", help="transparent 8K title render to lay over the background")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    bg = background()
    bg.save(OUT / "background-8k.png")
    bg.resize((W // 2, H // 2), Image.LANCZOS).save(OUT / "background-4k.png")
    if args.title:
        title = Image.open(args.title).convert("RGBA")
        assert title.size == (W, H), f"title is {title.size}, not {W}x{H}"
        main_img = compose(bg, title)
        main_img.save(OUT / "main-8k.png")
        small = main_img.resize((W // 2, H // 2), Image.LANCZOS)
        small.save(OUT / "main-4k.png")
        small.save(OUT / "main-4k.jpg", quality=92)   # Nexus caps image uploads in size
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.png"))))


if __name__ == "__main__":
    main()
