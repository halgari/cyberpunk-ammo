"""PIL art for the faction forms: the printed parts scene.py puts on them. The logos are the game's
own decals, extracted by tools/render/faction_textures.sh. Every part is drawn to the shape of the
face it goes on, so nothing stretches.
"""
import math
import os
import pathlib
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

TEX = pathlib.Path(os.environ.get("AO_ASSETS", os.path.expanduser("~/.cache/ammo-overhaul/assets"))) / "faction"
RED = (196, 18, 22)


def emblem(px):
    """The Arasaka crest as a mask of px by px, from the label sheet's largest print."""
    a = Image.open(TEX / "w_arasaka_decal_01_d01.png").getchannel("A").crop((4, 876, 148, 1020))
    a = a.resize((px, px), Image.LANCZOS).filter(ImageFilter.GaussianBlur(px / 400))
    return a.point(lambda v: 255 if v > 120 else 0)


def word(name, height):
    """A wordmark decal cut to its ink, as a mask `height` tall."""
    m = Image.open(TEX / name).convert("L")
    m = m.crop(m.point(lambda v: 255 if v > 90 else 0).getbbox())
    return m.resize((round(m.width * height / m.height), height), Image.LANCZOS)


def ara_label(path, w, h):
    """The lid's label: black card, a red keyline, the red crest over the white wordmark."""
    im = Image.new("RGB", (w, h), (13, 13, 15))
    dr = ImageDraw.Draw(im)
    k = max(4, min(w, h) // 34)
    dr.rectangle([k, k, w - k, h - k], outline=RED, width=k)
    tw = round(w * 0.74)
    wm = word("corpo_arasaka_decal_b_m.png", round(tw * 0.18))
    if wm.width > tw:
        wm = wm.resize((tw, round(wm.height * tw / wm.width)), Image.LANCZOS)
    c = round(min(h * 0.86 - wm.height * 1.5, w * 0.6))
    top = round((h - c - wm.height * 1.25) / 2)
    im.paste(RED, ((w - c) // 2, top), emblem(c))
    im.paste((232, 230, 224), ((w - wm.width) // 2, top + c + wm.height // 4), wm)
    im.save(path)


def ara_print(path, L, R, along=0.28, u_center=0.5):
    """What's printed on a round, wrapped round it: green is the red crest (scene.py engrave). The
    crest is sized to the round's width and sits `along` the round, turned to read as it lies."""
    h = 1024
    w = round(h * 2 * math.pi * R / L)
    im = Image.new("L", (w, h))
    c = round(min(R * 1.5 / L * h, w * 0.4))
    m = emblem(c).rotate(-90)
    im.paste(255, (round(w * u_center - m.width / 2), round(h * along - c / 2)), m)
    zero = Image.new("L", (w, h))
    Image.merge("RGB", (zero, im, zero)).transpose(Image.FLIP_TOP_BOTTOM).save(path)


def spray(mask, spread):
    """A stencil's mask sprayed on: soft-edged, with overspray specks round it."""
    soft = mask.filter(ImageFilter.GaussianBlur(spread))
    noise = Image.effect_noise(mask.size, 90).point(lambda v: 255 if v > 150 else 0)
    halo = ImageChops.multiply(soft.point(lambda v: min(255, v * 2)), noise)
    return ImageChops.lighter(mask, halo)


def wear(mask, rng, chips=240):
    """Knocks chips and scratches out of a mask, as paint worn off a steel wall."""
    w, h = mask.size
    keep = Image.new("L", (w, h), 255)
    dr = ImageDraw.Draw(keep)
    for _ in range(chips):
        x, y, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(1, h / 160)
        dr.polygon([(x + r * rng.uniform(0.5, 2) * math.cos(t), y + r * rng.uniform(0.5, 1.4) * math.sin(t))
                    for t in (0, 1.1, 2.2, 3.3, 4.4, 5.5)], fill=0)
    for _ in range(26):
        x, y = rng.uniform(0, w), rng.uniform(0, h)
        a, l = rng.uniform(-0.5, 0.5), rng.uniform(0.05, 0.3) * w
        dr.line([(x, y), (x + l * math.cos(a), y + l * math.sin(a))], fill=0, width=rng.choice((1, 2, 3)))
    return ImageChops.multiply(mask, keep)


def mael_wall(path, w, h, seed):
    """The can's front wall: black paint over steel, a white skull stencil filling the wall's height,
    MAELSTROM sprayed red across its jaw. Sized to the wall."""
    rng = random.Random(seed)
    im = Image.new("RGB", (w, h), (84, 84, 88))
    paint = wear(Image.new("L", (w, h), 255), rng, 110).filter(ImageFilter.GaussianBlur(0.8))
    im.paste((19, 19, 21), (0, 0), paint)
    sk = Image.open(TEX / "maelstrom_skull_03_m.png").convert("L")
    sk = sk.crop(sk.point(lambda v: 255 if v > 70 else 0).getbbox())
    sh = round(h * 0.94)
    sk = sk.resize((round(sk.width * sh / sk.height), sh), Image.LANCZOS)
    skull = Image.new("L", (w, h))
    skull.paste(sk, (round(w * 0.5 - sk.width / 2), round((h - sh) / 2)))
    im.paste((226, 224, 214), (0, 0), wear(skull, rng, 70))
    tw = round(w * 0.95)
    wm = word("maelstrom_logo_a_01_m.png", round(tw * 0.2))
    if wm.width > tw:
        wm = wm.resize((tw, round(wm.height * tw / wm.width)), Image.LANCZOS)
    red = Image.new("L", (w, h))
    red.paste(wm, ((w - wm.width) // 2, round(h * 0.74 - wm.height / 2)))
    im.paste((206, 16, 20), (0, 0), wear(spray(red, h / 50), rng, 50))
    im.filter(ImageFilter.GaussianBlur(0.5)).save(path)


# Each mark as the pen moves, in a box 1 wide and 1 tall, y down.
STROKES = {
    "1": [[(0.25, 0.28), (0.55, 0.0), (0.56, 1.0)]],
    "2": [[(0.08, 0.28), (0.32, 0.02), (0.72, 0.04), (0.84, 0.3), (0.5, 0.66), (0.08, 1.0), (0.96, 0.95)]],
    "4": [[(0.72, 1.0), (0.68, 0.0), (0.04, 0.68), (0.98, 0.64)]],
    "5": [[(0.86, 0.0), (0.2, 0.04), (0.14, 0.46), (0.6, 0.36), (0.92, 0.6), (0.72, 0.95), (0.12, 0.9)]],
    "9": [[(0.82, 0.2), (0.5, 0.0), (0.14, 0.2), (0.24, 0.52), (0.68, 0.46), (0.82, 0.2)], [(0.82, 0.14), (0.74, 1.0)]],
    "M": [[(0.04, 1.0), (0.12, 0.0), (0.5, 0.72), (0.86, 0.0), (0.98, 1.0)]],
    ".": [[(0.2, 0.9), (0.26, 0.97), (0.2, 1.0), (0.16, 0.93)]],
}
WIDTHS = {".": 0.42, "M": 1.12, "1": 0.72}
INK = (14, 12, 12)


def curve(pts, n=40):
    """A Catmull-Rom line through the pen's points."""
    p = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(p) - 2):
        for t in (k / n for k in range(n)):
            out.append(tuple(0.5 * (2 * p[i][a] + (p[i + 1][a] - p[i - 1][a]) * t
                                    + (2 * p[i - 1][a] - 5 * p[i][a] + 4 * p[i + 1][a] - p[i + 2][a]) * t * t
                                    + (3 * p[i][a] - p[i - 1][a] - 3 * p[i + 1][a] + p[i + 2][a]) * t ** 3) for a in (0, 1)))
    return out + [pts[-1]]


def pen_stroke(dr, line, pen, rng, step):
    """One pull of a dying marker: a row of felt fibres dragged along the line. The hand wobbles and
    the pressure comes and goes; a fibre runs dry and catches again, and the whole pen skips in places."""
    fibres = [True] * 13
    ph = rng.uniform(0, 6.28), rng.uniform(0, 6.28), rng.uniform(0, 6.28)
    skips = [(rng.uniform(0.15, 0.85), rng.uniform(0.03, 0.08))]
    dist = 0.0
    for i, (x, y) in enumerate(line):
        a = line[min(i + 1, len(line) - 1)]
        b = line[max(i - 1, 0)]
        dx, dy = a[0] - b[0], a[1] - b[1]
        m = math.hypot(dx, dy) or 1.0
        t = i / len(line)
        dist += step
        wob = pen * 0.34 * (math.sin(dist / (pen * 2.1) + ph[0]) + 0.6 * math.sin(dist / (pen * 0.8) + ph[1]))
        x, y = x - dy / m * wob, y + dx / m * wob
        press = 0.74 + 0.26 * math.sin(dist / (pen * 3.3) + ph[2])
        dry, wet = 0.002 + 0.012 * t, 0.14
        if any(abs(t - c) < w for c, w in skips):
            dry, wet = 0.05, 0.012
        for k in range(len(fibres)):
            fibres[k] = rng.random() > dry if fibres[k] else rng.random() < wet
            if fibres[k]:
                o = (k / (len(fibres) - 1) - 0.5) * pen * 1.25 * press
                r = pen * 0.07
                dr.ellipse([x - dy / m * o - r, y + dx / m * o - r, x - dy / m * o + r, y + dx / m * o + r], fill=255)


def scrawl(text, w, h, rng):
    """The text in marker, as a mask of w by h: no font, each mark drawn by hand and a little different."""
    size = min(h * 0.72, w * 0.56 / sum(WIDTHS.get(c, 0.86) for c in text))
    pen = size * 0.135
    total = sum(WIDTHS.get(c, 0.86) for c in text) * size * 0.98
    mask = Image.new("L", (w, h))
    dr = ImageDraw.Draw(mask)
    x = (w - total) / 2
    slope = rng.uniform(-0.05, 0.03)
    for c in text:
        cw = WIDTHS.get(c, 0.86) * size
        turn = rng.uniform(-0.09, 0.09)
        for stroke in STROKES[c]:
            sx, sy = cw * 0.8 * rng.uniform(0.94, 1.06), size * rng.uniform(0.94, 1.06)
            pts = [(rng.uniform(-0.03, 0.03) + u, rng.uniform(-0.03, 0.03) + v) for u, v in stroke]
            pts = [(x + (u + (v - 0.5) * turn) * sx, (h - size) / 2 + slope * x + (v - (u - 0.5) * turn) * sy) for u, v in pts]
            line = curve(pts, 90)
            pen_stroke(dr, line, pen, rng, math.dist(line[0], line[1]) or 1.0)
        x += cw * 0.98
    return mask.filter(ImageFilter.GaussianBlur(0.7))


def streaks(size, along, rng):
    """Noise pulled out along a drag: vertical bands when `along` is 1, horizontal when 0."""
    w, h = size
    n = Image.effect_noise((w, 6) if along else (6, h), 70)
    return n.resize(size, Image.BILINEAR)


def hand_mask(size, c, s, tilt, rng):
    """A bloody hand's mark at c, s tall: palm, four fingers, a thumb, dragged down the card, so it
    breaks up into streaks where the blood ran out."""
    w, h = size
    k = 3
    hand = Image.new("L", (round(s * k), round(s * k)))
    dr = ImageDraw.Draw(hand)
    u = s * k
    dr.rounded_rectangle([u * 0.28, u * 0.5, u * 0.74, u * 0.92], u * 0.14, fill=255)
    for x0, top, x1, fw in ((0.1, 0.2, 0.32, 0.105), (0.32, 0.03, 0.42, 0.11), (0.56, 0.02, 0.55, 0.11), (0.82, 0.14, 0.68, 0.095)):
        dr.line([(u * x0, u * top), (u * x1, u * 0.6)], fill=255, width=round(u * fw))
        dr.ellipse([u * (x0 - fw / 2), u * (top - fw / 2), u * (x0 + fw / 2), u * (top + fw / 2)], fill=255)
    dr.line([(u * 0.38, u * 0.8), (u * 0.02, u * 0.62)], fill=255, width=round(u * 0.11))
    hand = hand.rotate(tilt, resample=Image.BICUBIC, fillcolor=0).resize((round(s), round(s)), Image.LANCZOS)
    stamp = Image.new("L", size)
    stamp.paste(hand, (round(c[0] - s / 2), round(c[1] - s / 2)))
    drag = stamp
    for k in range(1, 30):
        drag = ImageChops.lighter(drag, ImageChops.offset(stamp, round(k * s * 0.004), round(k * s * 0.012)))
    bands = streaks(size, 1, rng).filter(ImageFilter.GaussianBlur(s * 0.012))
    drag = ImageChops.multiply(drag, bands.point(lambda v: 255 if v > 122 else 0))
    return ImageChops.lighter(stamp, drag)


def spatter(mask, c, spread, n, rng):
    """Droplets thrown out from c, longer the further they fly."""
    dr = ImageDraw.Draw(mask)
    for _ in range(n):
        a, d = rng.uniform(0, 6.28), spread * rng.random() ** 1.6
        r = spread * 0.075 * rng.uniform(0.15, 1) * (1 - 0.7 * d / spread)
        x, y = c[0] + d * math.cos(a), c[1] + d * math.sin(a) * 0.8
        e = 1 + 2.2 * d / spread
        pts = [(x + r * math.cos(t) * (e if abs(math.cos(t - a)) > 0.7 else 1) * math.cos(a) - r * math.sin(t) * math.sin(a),
                y + r * math.cos(t) * (e if abs(math.cos(t - a)) > 0.7 else 1) * math.sin(a) + r * math.sin(t) * math.cos(a))
               for t in (i * 0.5 for i in range(13))]
        dr.polygon(pts, fill=255)


def stain(im, mask, rng):
    """Dried blood over the card: near-black brown where it pooled at the edges, thinner rust-brown
    inside, soaked into the card rather than sat on it."""
    w, h = im.size
    mask = mask.filter(ImageFilter.GaussianBlur(1.6)).point(lambda v: 255 if v > 105 else 0).filter(ImageFilter.GaussianBlur(0.9))
    rim = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(7)))
    tone = Image.effect_noise((w // 12, h // 12), 60).resize((w, h), Image.BICUBIC)
    body = Image.composite(Image.new("RGB", (w, h), (46, 13, 9)), Image.new("RGB", (w, h), (76, 24, 14)), tone)
    im.paste(body, (0, 0), mask.point(lambda v: v * 0.94))
    im.paste((24, 8, 6), (0, 0), rim.filter(ImageFilter.GaussianBlur(1.2)).point(lambda v: v * 0.6))


def flat_front(path, w, h, text, seed):
    """The flat's front: kraft card, a bloody hand dragged down it from the rim and a spatter, and
    the caliber in a dying marker over the top."""
    rng = random.Random(seed)
    im = Image.new("RGB", (w, h), (120, 86, 52))
    m = hand_mask((w, h), (w * 0.105, h * 0.42), h * 0.82, rng.uniform(-16, 8), rng)
    spatter(m, (w * 0.88, h * 0.4), h * 0.8, 70, rng)
    spatter(m, (w * 0.88, h * 0.34), h * 0.28, 12, rng)
    stain(im, m, rng)
    im.paste(INK, (0, 0), scrawl(text, w, h, rng))
    im.save(path)


def flat_side(path, w, h, seed):
    """The flat's end: blood run over the edge from the front, and a spatter."""
    rng = random.Random(seed)
    im = Image.new("RGB", (w, h), (120, 86, 52))
    m = Image.new("L", (w, h))
    dr = ImageDraw.Draw(m)
    dr.rounded_rectangle([w * 0.62, -h * 0.2, w * 1.1, h * 0.46], h * 0.2, fill=255)
    for _ in range(9):
        x, top, wide = w * rng.uniform(0.6, 1.0), h * rng.uniform(0.1, 0.3), h * rng.uniform(0.05, 0.13)
        dr.rounded_rectangle([x, top, x + wide, top + h * rng.uniform(0.35, 0.95)], wide / 2, fill=255)
    spatter(m, (w * 0.8, h * 0.3), h * 0.7, 46, rng)
    stain(im, m, rng)
    im.save(path)
