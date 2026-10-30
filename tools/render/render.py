"""Renders the ammo icon art in Blender: one box shot per round (art/icons/<name>.png) and, with
--rounds, a single-round reference (art/icons/<name>-ref.png).

  python3 tools/render/render.py [--rounds] [--only NAME[,NAME]] [--samples N]

Blender comes from $BLENDER or ~/.cache/ammo-overhaul/blender/blender-*/blender. The box art (colour,
stripe, the round's name, wear) is drawn here with PIL and handed to tools/render/scene.py, which
builds the round and the box. Sizes are in centimetres, close to the real cartridges.
"""
import argparse
import glob
import json
import math
import os
import pathlib
import random
import subprocess
import tempfile

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "art" / "icons"
FONT = "/usr/share/fonts/gsfonts/NimbusSansNarrow-Bold.otf"

# Round shapes. pistol: d, case, oal; rifle: base, neck, shoulder (start, end), case, oal;
# shell: R, L, head; rail: r, L, rings; smart: r, L, fin_len, fin_span.
P9 = dict(kind="pistol", d=0.90, case=1.92, oal=2.95)
P45 = dict(kind="pistol", d=1.15, case=2.27, oal=3.20)
P12 = dict(kind="pistol", d=1.09, case=3.29, oal=4.00, rimmed=True, rim=0.66, nose="flat")
R556 = dict(kind="rifle", base=0.96, neck=0.62, shoulder=(3.65, 3.95), case=4.48, oal=5.70)
R762 = dict(kind="rifle", base=1.20, neck=0.86, shoulder=(4.00, 4.35), case=5.10, oal=7.10, case_mat="green")
R127 = dict(kind="rifle", base=2.04, neck=1.40, shoulder=(7.70, 8.40), case=9.90, oal=13.8)
G12 = dict(kind="shell", R=1.0, L=7.0, head=1.4, color="red")
G4 = dict(kind="shell", R=1.35, L=9.5, head=3.0, color="black")
T5 = dict(kind="rail", r=0.25, L=1.0, rings=[0.8])
TH = dict(kind="rail", r=0.45, L=2.7, rings=[0.72, 0.86])
# idband: the painted ID band (teal Seekers, red Short-Fuse; Dumbfires carry a hazard band instead).
S10 = dict(kind="dian", r=0.5, L=5.4, idband="teal")
S20 = dict(kind="cassette", cell_r=0.35, L=6.0, idband="teal")
S25 = dict(kind="ashura", R=0.625, L=6.5, idband="teal")

# Box looks per load, in sRGB: (panel, stripe). Same load, same box in every caliber.
LOOK = {
    "Ball": ((150, 112, 70), (40, 38, 34)),
    "Mushrooms": ((96, 22, 18), (20, 18, 18)),
    "RailSlugs": ((52, 55, 60), (40, 90, 170)),
    "Sleevers": ((22, 22, 24), (170, 30, 30)),
    "Seekers": ((70, 78, 44), (225, 225, 220)),
    "Dumbfires": ((70, 78, 44), None),
    "Buckshot": ((30, 44, 80), (225, 225, 220)),
    "Slugs": ((28, 66, 38), (220, 170, 30)),
    "PlusP": ((150, 112, 70), (170, 30, 30)),
    "Birdshot": ((70, 110, 60), (225, 225, 220)),
    "Bricks": ((40, 42, 46), (215, 110, 30)),
    "ShortFuse": ((70, 78, 44), (180, 30, 30)),
}


def hp(s):
    return dict(s, hp=True)


# icon file -> (shape, box look, label lines). The label is the round's name and nothing else.
ROUNDS = {
    "9mm-ball": (P9, "Ball", ["9MM", "BALL"]),
    "9mm-mushrooms": (hp(P9), "Mushrooms", ["9MM", "MUSHROOMS"]),
    "45-ball": (P45, "Ball", [".45", "BALL"]),
    "45-mushrooms": (hp(P45), "Mushrooms", [".45", "MUSHROOMS"]),
    "12mm-ball": (P12, "Ball", ["12MM", "BALL"]),
    "12mm-mushrooms": (hp(P12), "Mushrooms", ["12MM", "MUSHROOMS"]),
    "556-ball": (R556, "Ball", ["5.56", "BALL"]),
    "556-mushrooms": (hp(R556), "Mushrooms", ["5.56", "MUSHROOMS"]),
    "762-ball": (R762, "Ball", ["7.62", "BALL"]),
    "762-mushrooms": (hp(R762), "Mushrooms", ["7.62", "MUSHROOMS"]),
    "127-ball": (R127, "Ball", ["12.7", "BALL"]),
    "127-mushrooms": (hp(R127), "Mushrooms", ["12.7", "MUSHROOMS"]),
    "12ga-buckshot": (dict(G12, crimp="star"), "Buckshot", ["BUCKSHOT"]),
    "12ga-slugs": (dict(G12, crimp="roll"), "Slugs", ["SLUGS"]),
    "4ga-buckshot": (dict(G4, crimp="star"), "Buckshot", ["4GA", "BUCKSHOT"]),
    "4ga-slugs": (dict(G4, crimp="roll"), "Slugs", ["4GA", "SLUGS"]),
    "5mm-railslugs": (T5, "RailSlugs", ["5MM", "RAIL SLUGS"]),
    "5mm-sleevers": (dict(T5, sleeve=True), "Sleevers", ["5MM", "SLEEVERS"]),
    "heavy-railslugs": (TH, "RailSlugs", ["HEAVY", "RAIL SLUGS"]),
    "heavy-sleevers": (dict(TH, sleeve=True), "Sleevers", ["HEAVY", "SLEEVERS"]),
    "10mm-seekers": (S10, "Seekers", ["10MM", "SEEKERS"]),
    "10mm-dumbfires": (dict(S10, dumbfire=True), "Dumbfires", ["10MM", "DUMBFIRES"]),
    "20mm-seekers": (S20, "Seekers", ["20MM", "SEEKERS"]),
    "20mm-dumbfires": (dict(S20, dumbfire=True), "Dumbfires", ["20MM", "DUMBFIRES"]),
    "25mm-seekers": (S25, "Seekers", ["25MM", "SEEKERS"]),
    "25mm-dumbfires": (dict(S25, dumbfire=True), "Dumbfires", ["25MM", "DUMBFIRES"]),
    # Second Uncommons. +P: Ball with a red case-mouth seal; Birdshot: light green star-crimped shell;
    # Bricks: thicker dark gunmetal rail slug; Short-Fuse: shorter, fatter smart round.
    "9mm-plusp": (dict(P9, seal=True), "PlusP", ["9MM", "+P"]),
    "45-plusp": (dict(P45, seal=True), "PlusP", [".45", "+P"]),
    "12mm-plusp": (dict(P12, seal=True), "PlusP", ["12MM", "+P"]),
    "556-plusp": (dict(R556, seal=True), "PlusP", ["5.56", "+P"]),
    "762-plusp": (dict(R762, seal=True), "PlusP", ["7.62", "+P"]),
    "127-plusp": (dict(R127, seal=True), "PlusP", ["12.7", "+P"]),
    "12ga-birdshot": (dict(G12, color="green", crimp="star"), "Birdshot", ["BIRDSHOT"]),
    "4ga-birdshot": (dict(G4, color="green", crimp="star"), "Birdshot", ["4GA", "BIRDSHOT"]),
    "5mm-bricks": (dict(T5, r=T5["r"] * 1.3, gunmetal=True), "Bricks", ["5MM", "BRICKS"]),
    "heavy-bricks": (dict(TH, r=TH["r"] * 1.25, gunmetal=True), "Bricks", ["HEAVY", "BRICKS"]),
    "10mm-shortfuse": (dict(S10, L=S10["L"] * 0.78, r=S10["r"] * 1.2, idband="red"), "ShortFuse", ["10MM", "SHORT-FUSE"]),
    "20mm-shortfuse": (dict(S20, L=S20["L"] * 0.78, cell_r=S20["cell_r"] * 1.15, idband="red"), "ShortFuse", ["20MM", "SHORT-FUSE"]),
    "25mm-shortfuse": (dict(S25, L=S25["L"] * 0.78, R=S25["R"] * 1.15, idband="red"), "ShortFuse", ["25MM", "SHORT-FUSE"]),
}

# Rare and Epic rounds, from tools/rounds/rounds.py (rounds_tiers.json): each takes its caliber's
# shape (with any overrides) and a box look of its own per load.
_TIERS = json.loads((pathlib.Path(__file__).parent / "rounds_tiers.json").read_text())
for _load, (_panel, _stripe) in _TIERS["looks"].items():
    LOOK.setdefault(_load, (tuple(_panel), tuple(_stripe) if _stripe else None))
LEGENDARY_NAMES = {_n for _n, _r in _TIERS["rounds"].items() if _r.get("tier") == 4}
for _name, _r in _TIERS["rounds"].items():
    ROUNDS[_name] = (dict(globals()[_r["shape"]], **_r["over"]), _r["look"], _r["label"])

# Legendary looks, one per style (--legendary): a lacquered box with a metallic band and keylines,
# the load's own colour as a thin line through the band; polished or glowing rounds (over the load's
# art, by round shape); and a strong warm rim light (r, g, b, power factor).
_SMART = ("dian", "cassette", "ashura")
LEGENDARY = {
    # Gold foil box, black band with a glowing orange line; black cases with a glowing mouth ring.
    "foil": dict(panel=(236, 176, 60), band=(14, 13, 12), keyline=(14, 13, 12), text=(14, 13, 12),
                 glow=(255, 120, 20), box=dict(metal=1.0, rough=0.26, glow=5.0), rim=[1.0, 0.55, 0.15, 2.4],
                 round=dict(pistol=dict(case_mat="black", glow="orange"), rifle=dict(case_mat="black", glow="orange"),
                            shell=dict(head_mat="gold", color="black"), rail=dict(coil="orange"),
                            **{k: dict(nose_mat="gold") for k in _SMART})),
    # Blaze-orange lacquer, black band edged in glowing gold; polished gold cases.
    "blaze": dict(panel=(226, 98, 10), band=(16, 15, 14), keyline=(240, 190, 70), text=(16, 15, 14),
                  glow=(255, 190, 60), box=dict(metal=0.0, rough=0.35, glow=4.0), rim=[1.0, 0.42, 0.08, 2.6],
                  round=dict(pistol=dict(case_mat="gold"), rifle=dict(case_mat="gold"),
                             shell=dict(head_mat="gold", color="orange"), rail=dict(coil="orange", core="gunmetal"),
                             **{k: dict(idband="orange", nose_mat="gold") for k in _SMART})),
    # Black chrome box with a neon orange band; chrome cases with glowing tips.
    "chrome": dict(panel=(40, 42, 48), band=(230, 110, 14), keyline=(255, 150, 40), text=(240, 238, 232),
                   glow=(255, 110, 15), box=dict(metal=1.0, rough=0.18, glow=7.0), rim=[1.0, 0.6, 0.25, 2.0],
                   round=dict(pistol=dict(case_mat="chrome", tipglow=True), rifle=dict(case_mat="chrome", tipglow=True),
                              shell=dict(head_mat="chrome", color="black"), rail=dict(core="chrome", coil="orange"),
                              **{k: dict(nose_mat="chrome") for k in _SMART})),
    # Crimson lacquer, black band edged in glowing gold; polished gold cases.
    "crimson": dict(panel=(170, 12, 30), band=(16, 15, 14), keyline=(240, 190, 70), text=(246, 236, 214),
                    glow=(255, 190, 60), box=dict(metal=0.0, rough=0.3, glow=4.0), rim=[1.0, 0.1, 0.12, 2.6],
                    round=dict(pistol=dict(case_mat="gold"), rifle=dict(case_mat="gold"),
                               shell=dict(head_mat="gold", color="crimson"), rail=dict(coil="crimson", core="gunmetal"),
                               **{k: dict(idband="crimson", nose_mat="gold") for k in _SMART})),
    # Hot magenta lacquer, black band edged in glowing cyan; chrome cases.
    "magenta": dict(panel=(214, 16, 118), band=(16, 15, 14), keyline=(70, 235, 255), text=(16, 15, 14),
                    glow=(70, 235, 255), box=dict(metal=0.0, rough=0.3, glow=4.0), rim=[1.0, 0.1, 0.6, 2.6],
                    round=dict(pistol=dict(case_mat="chrome"), rifle=dict(case_mat="chrome"),
                               shell=dict(head_mat="chrome", color="magenta"), rail=dict(coil="magenta", core="gunmetal"),
                               **{k: dict(idband="magenta", nose_mat="chrome") for k in _SMART})),
    # Electric cyan lacquer, black band edged in glowing white; chrome cases.
    "cyan": dict(panel=(0, 186, 208), band=(16, 15, 14), keyline=(225, 250, 255), text=(10, 16, 20),
                 glow=(190, 245, 255), box=dict(metal=0.0, rough=0.3, glow=4.0), rim=[0.15, 0.8, 1.0, 2.6],
                 round=dict(pistol=dict(case_mat="chrome"), rifle=dict(case_mat="chrome"),
                            shell=dict(head_mat="chrome", color="cyan"), rail=dict(coil="cyan", core="gunmetal"),
                            **{k: dict(idband="cyan", nose_mat="chrome") for k in _SMART})),
    # Hazard yellow lacquer, black band edged in glowing cyan; polished gold cases.
    "yellow": dict(panel=(248, 222, 0), band=(16, 15, 14), keyline=(70, 235, 255), text=(16, 15, 14),
                   glow=(70, 235, 255), box=dict(metal=0.0, rough=0.3, glow=4.0), rim=[1.0, 0.85, 0.1, 2.4],
                   round=dict(pistol=dict(case_mat="gold"), rifle=dict(case_mat="gold"),
                              shell=dict(head_mat="gold", color="yellow"), rail=dict(coil="yellow", core="gunmetal"),
                              **{k: dict(idband="yellow", nose_mat="gold") for k in _SMART})),
}


def extent(s):
    """(length, radius) of a round as scene.py builds it."""
    k = s["kind"]
    if k == "pistol":
        return s["oal"], s["rim"] if s.get("rimmed") else s["d"] / 2 * 1.04
    if k == "rifle":
        return s["oal"], s["base"] / 2
    if k == "shell":
        return s["L"], s["R"] * 1.1
    if k == "rail":
        return (s["L"] * 1.06, s["r"] * 1.12) if s.get("sleeve") else (s["L"], s["r"])
    if k == "dian":
        return s["L"], s["r"] * 1.02
    if k == "cassette":
        side = s["cell_r"] * 2.35 * 3 + s["cell_r"] * 0.7
        return s["L"], side / 2 * 1.04
    return s["L"], s["R"] * 1.1


def layout(s):
    L, rad = extent(s)
    d = rad * 2 * 1.06
    cols = max(5, min(12, round(1.3 * L / d)))
    rows = max(3, cols // 2)
    return dict(d=d, cols=cols, rows=rows, W=cols * d, D=rows * d, H=L * 0.75)


def blotches(w, h, scale, rng):
    """Smooth random greyscale (L) image: random values on a coarse grid, scaled up."""
    sw, sh = max(2, w // scale), max(2, h // scale)
    small = Image.new("L", (sw, sh))
    small.putdata([rng.randint(0, 255) for _ in range(sw * sh)])
    return small.resize((w, h), Image.BICUBIC)


def edge_shade(w, h):
    """L image, 255 inside and darker toward the panel's edges."""
    gw, gh = 64, max(8, round(64 * h / w))
    g = Image.new("L", (gw, gh))
    m = 0.08 * min(gw, gh) / min(gw, gh) * min(gw, gh)
    g.putdata([round(255 * (0.7 + 0.3 * min(1.0, min(x, gw - 1 - x, y, gh - 1 - y) / max(1.0, m))))
               for y in range(gh) for x in range(gw)])
    return g.resize((w, h), Image.BICUBIC)


def mul(im, l):
    return ImageChops.multiply(im, Image.merge("RGB", [l] * 3))


def panel_art(path, w, h, look, lines, seed):
    """Printed cardboard panel: base colour, a stripe band, the name in white block letters, wear."""
    rng = random.Random(seed)
    base, stripe = LOOK[look]
    im = Image.new("RGB", (w, h), base)
    dr = ImageDraw.Draw(im)
    band = (int(h * 0.62), int(h * 0.80))
    if stripe:
        dr.rectangle([0, band[0], w, band[1]], fill=stripe)
    else:   # hazard band
        step = max(8, (band[1] - band[0]))
        for x in range(-step * 2, w + step * 2, step):
            dr.polygon([(x, band[1]), (x + step // 2, band[1]), (x + step // 2 + (band[1] - band[0]), band[0]),
                        (x + (band[1] - band[0]), band[0])], fill=(215, 160, 20))
        dr.rectangle([0, band[0], w, band[1]], outline=None)
    if lines:
        big = lines[-1]
        top = int(h * 0.12)
        avail_w = w * 0.86
        size = int(h * (0.36 if len(lines) == 2 else 0.44))
        f = ImageFont.truetype(FONT, size)
        while dr.textlength(big, font=f) > avail_w:
            size -= 2
            f = ImageFont.truetype(FONT, size)
        if len(lines) == 2:
            fs = ImageFont.truetype(FONT, int(size * 0.62))
            dr.text((w * 0.07, top), lines[0], font=fs, fill=(235, 232, 225))
            top += int(size * 0.62 * 1.02)
        else:
            top += int(h * 0.08)
        dr.text((w * 0.07, top), big, font=f, fill=(235, 232, 225))
    # Wear: blotchy dirt, fine grain, scuffs where the print is rubbed off, darker edges.
    dirt = Image.blend(blotches(w, h, 40, rng), blotches(w, h, 9, rng), 0.4)
    im = mul(im, dirt.point(lambda v: 210 + v * 45 // 255))
    grain = Image.effect_noise((w, h), 4)
    im = ImageChops.add(im, Image.merge("RGB", [grain] * 3), 1.0, -128)
    scuff = blotches(w, h, 14, rng).point(lambda v: 255 if v > 225 else 0).filter(ImageFilter.GaussianBlur(1.2))
    im = Image.composite(Image.blend(im, Image.new("RGB", (w, h), (150, 112, 72)), 0.55), im, scuff)
    im = mul(im, edge_shade(w, h))
    im.filter(ImageFilter.GaussianBlur(0.6)).save(path)


def legendary_panel(path, w, h, style, look, lines, seed):
    """Lacquered Legendary panel: dark or bright base, a metallic band edged with keylines and the
    load's colour as a thin line through it, the name in the style's text colour, light wear only."""
    st = LEGENDARY[style]
    rng = random.Random(seed)
    im = Image.new("RGB", (w, h), st["panel"])
    dr = ImageDraw.Draw(im)
    b0, b1 = int(h * 0.60), int(h * 0.82)
    k = max(2, h // 60)
    dr.rectangle([0, b0, w, b1], fill=st["band"])
    for y in (b0 - 3 * k, b1 + 2 * k):
        dr.rectangle([0, y, w, y + k], fill=st["keyline"])
    kind = LOOK[look][1]
    mid = (b0 + b1) // 2
    if kind:
        dr.rectangle([0, mid - k * 2, w, mid + k * 2], fill=kind)
    # What glows (the "-glow" image beside the art, read by scene.py): the keylines, and for the
    # black-band foil look a line through the band.
    glow = Image.new("RGB", (w, h))
    gd = ImageDraw.Draw(glow)
    if style == "foil":
        gd.rectangle([0, mid + k * 3, w, mid + k * 4], fill=st["glow"])
        dr.rectangle([0, mid + k * 3, w, mid + k * 4], fill=st["glow"])
    elif style == "chrome":
        gd.rectangle([0, b0, w, b1], fill=tuple(c // 3 for c in st["glow"]))
    for y in (b0 - 3 * k, b1 + 2 * k):
        if style != "foil":
            gd.rectangle([0, y, w, y + k], fill=st["glow"])
    glow.save(str(path).replace(".png", "-glow.png"))
    # Metallic sheen on the band: lighter toward its top edge.
    sheen = Image.linear_gradient("L").resize((w, b1 - b0)).point(lambda v: 255 - v * 70 // 255)
    im.paste(mul(im.crop((0, b0, w, b1)), sheen), (0, b0))
    if lines:
        big = lines[-1]
        top = int(h * 0.12)
        size = int(h * (0.36 if len(lines) == 2 else 0.44))
        f = ImageFont.truetype(FONT, size)
        while dr.textlength(big, font=f) > w * 0.86:
            size -= 2
            f = ImageFont.truetype(FONT, size)
        if len(lines) == 2:
            fs = ImageFont.truetype(FONT, int(size * 0.62))
            dr.text((w * 0.07, top), lines[0], font=fs, fill=st["text"])
            top += int(size * 0.62 * 1.02)
        else:
            top += int(h * 0.08)
        dr.text((w * 0.07, top), big, font=f, fill=st["text"])
    dirt = blotches(w, h, 40, rng)
    im = mul(im, dirt.point(lambda v: 236 + v * 19 // 255))
    grain = Image.effect_noise((w, h), 2)
    im = ImageChops.add(im, Image.merge("RGB", [grain] * 3), 1.0, -128)
    im = mul(im, edge_shade(w, h).point(lambda v: 190 + v * 65 // 255))
    im.filter(ImageFilter.GaussianBlur(0.5)).save(path)


def blender():
    exe = os.environ.get("BLENDER") or sorted(glob.glob(os.path.expanduser(
        "~/.cache/ammo-overhaul/blender/blender-*/blender")))[-1]
    return exe


def linear(rgb):
    """sRGB (0-255) to the linear colour a Blender material wants."""
    return tuple((c / 255) ** 2.2 for c in rgb)


def form_art(tmp, name, shape, st, lines, i):
    """The printed parts of the Legendary case and hero forms; returns their spec entries."""
    tmp = pathlib.Path(tmp)
    accent, line, gold = st["panel"], st["glow"], (232, 190, 96)
    # Lid liner: dark satin, a lit keyline, the crest over the round's name in foil.
    L, R = extent(shape)
    W, D = 1400, max(620, round(1400 * 0.72))
    im = Image.new("RGB", (W, D), (20, 18, 24))
    glow = Image.new("RGB", (W, D))
    dr, gd = ImageDraw.Draw(im), ImageDraw.Draw(glow)
    m = D // 22
    for d in (dr, gd):
        d.rectangle([m, m, W - m, D - m], outline=line, width=max(4, D // 110))
    ring = D * 0.19
    cx, cy = W / 2, D * 0.3
    dr.ellipse([cx - ring, cy - ring, cx + ring, cy + ring], outline=gold, width=D // 44)
    f = ImageFont.truetype(FONT, int(ring * 1.25))
    dr.text((cx, cy), "€$", font=f, fill=gold, anchor="mm")
    f = ImageFont.truetype(FONT, D // 11)
    dr.text((cx, D * 0.555), "BRA€$MARKET", font=f, fill=gold, anchor="mm")
    big = lines[-1]
    size = D // 4
    f = ImageFont.truetype(FONT, size)
    while dr.textlength(big, font=f) > W * 0.8:
        size -= 2
        f = ImageFont.truetype(FONT, size)
    dr.text((cx, D * 0.77), big, font=f, fill=accent, anchor="mm")
    if len(lines) == 2:
        dr.text((m * 2.2, m * 2), lines[0], font=ImageFont.truetype(FONT, D // 9), fill=gold)
    lid = tmp / f"{name}-lid.png"
    im.save(lid)
    glow.save(str(lid).replace(".png", "-glow.png"))
    # Steel plate: the serial.
    im = Image.new("RGB", (640, 260), (176, 176, 182))
    dr = ImageDraw.Draw(im)
    dr.rectangle([8, 8, 631, 251], outline=(40, 40, 44), width=5)
    dr.text((320, 84), "BRA€$MARKET", font=ImageFont.truetype(FONT, 62), fill=(20, 20, 22), anchor="mm")
    dr.text((320, 176), f"No {1007 + i * 137:04d}", font=ImageFont.truetype(FONT, 92), fill=(20, 20, 22), anchor="mm")
    plate = tmp / f"{name}-plate.png"
    im.save(plate)
    # Tamper strip: accent and white diagonals, VOID down the middle.
    im = Image.new("RGB", (160, 800), (236, 234, 228))
    dr = ImageDraw.Draw(im)
    for y in range(-200, 1000, 120):
        dr.polygon([(0, y), (160, y - 110), (160, y - 50), (0, y + 60)], fill=accent)
    txt = Image.new("L", (800, 160))
    ImageDraw.Draw(txt).text((400, 80), "VOID", font=ImageFont.truetype(FONT, 120), fill=255, anchor="mm")
    im.paste((16, 15, 14), (0, 0), txt.rotate(90, expand=True))
    tamper = tmp / f"{name}-tamper.png"
    im.save(tamper)
    # Engraving, unrolled: red is cut lines (guilloche bands and rings), green the name's inlay, in
    # square pixels; the middle of the image faces the camera.
    w = 2048
    h = min(4096, max(512, round(w * L / (2 * math.pi * R))))
    red = Image.new("L", (w, h))
    dr = ImageDraw.Draw(red)
    for y0 in [h * k for k in (0.13, 0.5, 0.86)]:
        for k in range(5):
            for sign in (-1, 1):
                pts = [(x, y0 + sign * (h * 0.012 + k * h * 0.012) * math.sin(x / w * 2 * math.pi * 24 + k * 0.6))
                       for x in range(0, w + 8, 8)]
                dr.line(pts, fill=255, width=max(4, h // 170))
    for x in range(0, w, w // 48):
        for yy in (0.3, 0.7):
            dr.ellipse([x, h * yy - h * 0.012, x + h * 0.024, h * yy + h * 0.012], outline=255, width=max(4, h // 220))
    for yy in (0.06, 0.2, 0.42, 0.58, 0.8, 0.94):
        dr.line([(0, h * yy), (w, h * yy)], fill=255, width=max(6, h // 130))
    green = Image.new("L", (w, h))
    tw = round(h * 0.62)
    size = round(w * 0.2)
    f = ImageFont.truetype(FONT, size)
    while ImageDraw.Draw(green).textlength(big, font=f) > tw:
        size -= 2
        f = ImageFont.truetype(FONT, size)
    strip = Image.new("L", (tw, round(size * 1.3)))
    ImageDraw.Draw(strip).text((tw / 2, strip.height / 2), big, font=f, fill=255, anchor="mm")
    strip = strip.rotate(90, expand=True)
    # A rail round's glowing coils would cut the name to pieces, so it goes without.
    if shape["kind"] != "rail":
        green.paste(strip, (w // 2 - strip.width // 2, h // 2 - strip.height // 2))
    # Keep the name readable: no cut lines under it.
    ImageDraw.Draw(red).rectangle([w // 2 - strip.width // 2 - 12, h // 2 - strip.height // 2 - 12,
                                   w // 2 + strip.width // 2 + 12, h // 2 + strip.height // 2 + 12], fill=0)
    eng = tmp / f"{name}-engrave.png"
    Image.merge("RGB", (red, green, Image.new("L", (w, h)))).save(eng)
    return dict(lid=str(lid), plate=str(plate), tamper=str(tamper), engrave=str(eng), R=R, accent=linear(accent))


def run(spec, tmp):
    sp = pathlib.Path(tmp) / "spec.json"
    sp.write_text(json.dumps(spec))
    r = subprocess.run([blender(), "-b", "-P", str(ROOT / "tools/render/scene.py"), "--", str(sp)],
                       capture_output=True, text=True)
    if r.returncode or "Traceback" in r.stdout + r.stderr:
        raise SystemExit(r.stdout[-3000:] + r.stderr[-3000:])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rounds", action="store_true", help="render single-round references too")
    ap.add_argument("--only", default="")
    ap.add_argument("--samples", type=int, default=256)
    ap.add_argument("--out", default=str(ART))
    ap.add_argument("--legendary", default="blaze", choices=sorted(LEGENDARY), help="Legendary look")
    ap.add_argument("--form", default="", choices=("", "case", "hero"), help="Legendary form: a box by default")
    args = ap.parse_args()
    names = args.only.split(",") if args.only else list(ROUNDS)
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for i, name in enumerate(names):
            shape, look, lines = ROUNDS[name]
            legendary = LEGENDARY[args.legendary] if name in LEGENDARY_NAMES else None
            if legendary:
                shape = dict(shape, **legendary["round"].get(shape["kind"], {}))
            if args.rounds:
                run({"mode": "round", "out": str(out / f"{name}-ref.png"), "round": shape,
                     "samples": args.samples}, tmp)
            if legendary and args.form:
                run({"mode": "box", "out": str(out / f"{name}.png"), "round": shape, "samples": args.samples,
                     "rim": legendary["rim"][:3] + [legendary["rim"][3] * 1.5],
                     "box": dict(form_art(tmp, name, shape, legendary, lines, i), form=args.form)}, tmp)
                print(name, flush=True)
                continue
            lay = layout(shape)
            px = 1024
            front, side = pathlib.Path(tmp) / f"{name}-front.png", pathlib.Path(tmp) / f"{name}-side.png"
            art = (lambda *a, **k: legendary_panel(*a[:3], args.legendary, *a[3:], **k)) if legendary else panel_art
            art(front, px, max(64, round(px * lay["H"] / lay["W"])), look, lines, seed=i + 1)
            art(side, px, max(64, round(px * lay["H"] / lay["D"])), look, [], seed=i + 101)
            extra = dict(rim=legendary["rim"]) if legendary else {}
            run({"mode": "box", "out": str(out / f"{name}.png"), "round": shape, "samples": args.samples,
                 "box": dict(lay, front=str(front), side=str(side), seed=i + 1, lacquer=legendary and legendary["box"]), **extra}, tmp)
            print(name, flush=True)


if __name__ == "__main__":
    main()
