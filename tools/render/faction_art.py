"""PIL art for the faction forms: the printed parts scene.py puts on them. The logos are the game's
own decals, extracted by tools/render/faction_textures.sh. Every part is drawn to the shape of the
face it goes on, so nothing stretches.
"""
import math
import os
import pathlib
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

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


def decal(name):
    """A decal cut to its ink, RGBA as the game has it (a one-channel mask comes back white on its own alpha)."""
    im = Image.open(TEX / name)
    if im.mode != "RGBA":
        m = im.convert("L")
        im = Image.merge("RGBA", (m, m, m, m))
    return im.crop(im.getchannel("A").point(lambda v: 255 if v > 60 else 0).getbbox())


def fit(im, w, h):
    k = min(w / im.width, h / im.height)
    return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def centre(ground, im, cx, cy):
    ground.alpha_composite(im, (round(cx - im.width / 2), round(cy - im.height / 2)))


def keyline(dr, w, h, inset, colour, width):
    dr.rectangle([inset, inset, w - inset, h - inset], outline=colour, width=width)


GILT = (214, 166, 74)


def tyger_label(path, w, h):
    """The lacquer box's lid: black, a gold keyline, the gang's red tiger crest over its kanji."""
    im = Image.new("RGBA", (w, h), (9, 8, 9, 255))
    keyline(ImageDraw.Draw(im), w, h, min(w, h) // 26, GILT, max(3, min(w, h) // 120))
    centre(im, fit(decal("tyger_claws.png"), w * 0.86, h * 0.84), w / 2, h / 2)
    im.convert("RGB").save(path)


def val_label(path, w, h, muerte=False):
    """The cigar box's lid label. Burgundy and gold: the gang's gilt V in roses and its script name;
    Santa Muerte's is black, with the Santisima Muerte stencil in gold."""
    im = Image.new("RGBA", (w, h), (10, 8, 9, 255) if muerte else (112, 12, 28, 255))
    dr = ImageDraw.Draw(im)
    k = min(w, h)
    keyline(dr, w, h, k // 26, GILT, max(3, k // 110))
    keyline(dr, w, h, k // 17, GILT, max(1, k // 320))
    if muerte:
        m = fit(decal("valentinos_dec_v29_m.png"), w * 0.8, h * 0.84).getchannel("A")
        gold = Image.new("RGBA", m.size, (*GILT, 255))
        gold.putalpha(m)
        centre(im, gold, w / 2, h / 2)
    else:
        centre(im, fit(decal("valentinos_dec_v05.png"), w * 0.5, h * 0.72), w / 2, h * 0.44)
        sc = Image.open(TEX / "w_gangs_valentinos_d01.png").crop((440, 860, 1024, 1024)).getchannel("A")
        sc = sc.crop(sc.point(lambda v: 255 if v > 60 else 0).getbbox())
        sc = fit(sc, w * 0.5, h * 0.15)
        gold = Image.new("RGBA", sc.size, (*GILT, 255))
        gold.putalpha(sc)
        centre(im, gold, w / 2, h * 0.86)
    im.convert("RGB").save(path)


OLIVE = (64, 70, 40)


def boards(im, n, rng):
    """Plank seams and a little grain drawn over a painted face, running across it."""
    w, h = im.size
    dr = ImageDraw.Draw(im)
    for i in range(1, n):
        y = h * i / n + rng.uniform(-1.5, 1.5)
        dr.line([(0, y), (w, y)], fill=(20, 19, 14), width=max(2, h // 130))


def six_wall(path, w, h, seed):
    """The crate's front: olive paint over boards, the gang's skull badge stencilled in white, its
    name beside it."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (*OLIVE, 255))
    ink = Image.new("L", (w, h))
    badge = fit(decal("6th_street_a_graffiti_i_m.png"), h * 0.92, h * 0.92).getchannel("A")
    ink.paste(badge, (round(w * 0.2 - badge.width / 2), round((h - badge.height) / 2)))
    name = Image.open(TEX / "6th_street_a_graffiti_m_m.png").convert("L").crop((0, 150, 1024, 256))
    name = name.crop(name.point(lambda v: 255 if v > 90 else 0).getbbox())
    name = fit(name, w * 0.56, h * 0.42)
    ink.paste(name, (round(w * 0.67 - name.width / 2), round(h / 2 - name.height / 2)))
    white = Image.new("RGBA", (w, h), (216, 212, 192, 255))
    white.putalpha(wear(ink, rng, 120))
    im.alpha_composite(white)
    boards(im, 3, rng)
    im.convert("RGB").save(path)


def six_flag(path, w, h, seed):
    """The crate's lid, inside: a flag painted by hand on the boards, faded and chipped to olive."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (*OLIVE, 255))
    flag = Image.new("RGB", (w, h), (196, 188, 164))
    dr = ImageDraw.Draw(flag)
    s = h / 13
    for i in range(0, 13, 2):
        dr.rectangle([0, i * s, w, (i + 1) * s], fill=(128, 30, 28))
    cw, ch = w * 0.42, s * 7
    dr.rectangle([0, 0, cw, ch], fill=(28, 36, 70))
    for r in range(5):
        for c in range(6 + (r % 2 == 0)):
            x = cw * (c + (0.5 if r % 2 == 0 else 1.0)) / 7
            y = ch * (r + 0.6) / 5.2
            q = s * 0.3
            dr.polygon([(x + q * (1 if k % 2 == 0 else 0.42) * math.sin(k * math.pi / 5),
                         y - q * (1 if k % 2 == 0 else 0.42) * math.cos(k * math.pi / 5)) for k in range(10)], fill=(196, 188, 164))
    im.paste(flag, (0, 0), wear(Image.new("L", (w, h), 255), rng, 320))
    boards(im, 4, rng)
    im.convert("RGB").save(path)


HAZARD = (232, 182, 24)


def mil_stripes(im, box):
    """Black and yellow hazard stripes across `box`."""
    x0, y0, x1, y1 = box
    strip = Image.new("RGBA", (x1 - x0, y1 - y0), (*HAZARD, 255))
    dr = ImageDraw.Draw(strip)
    t = y1 - y0
    for x in range(-t, strip.width + t, t * 2):
        dr.polygon([(x, t), (x + t, t), (x + t * 2, 0), (x + t, 0)], fill=(14, 14, 15, 255))
    im.alpha_composite(strip, (x0, y0))


def mil_lid(path, w, h, seed):
    """The transit case's lid: gunmetal, the white Militech mark, hazard stripes along the foot."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (38, 40, 44, 255))
    m = wear(fit(decal("militech_logo_a_m.png"), w * 0.7, h * 0.72).getchannel("A"), rng, 30)
    white = Image.new("RGBA", m.size, (226, 226, 222, 255))
    white.putalpha(m)
    centre(im, white, w / 2, h * 0.44)
    mil_stripes(im, (0, round(h * 0.88), w, h))
    im.convert("RGB").save(path)


def mil_front(path, w, h, seed):
    """The case's front: the wordmark over a lot plate, a warning label cut from the game's own sheet."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (38, 40, 44, 255))
    m = wear(fit(decal("militech_logo_b_m.png"), w * 0.74, h * 0.5).getchannel("A"), rng, 24)
    white = Image.new("RGBA", m.size, (226, 226, 222, 255))
    white.putalpha(m)
    centre(im, white, w * 0.42, h * 0.38)
    sheet = Image.open(TEX / "w_militech_decal_d01.png").convert("RGBA")
    tag = fit(sheet.crop((10, 850, 400, 965)), w * 0.17, h * 0.5)
    centre(im, tag, w * 0.895, h * 0.4)
    mil_stripes(im, (0, round(h * 0.76), round(w * 0.8), h))
    im.convert("RGB").save(path)


def tub_label(path, w, h):
    """The tub's label, a gym supplement's: loud yellow, the gang's flexing jaguar, its red name, and
    PAIN PAIN PAIN GAIN up the side."""
    im = Image.new("RGBA", (w, h), (236, 190, 22, 255))
    dr = ImageDraw.Draw(im)
    dr.rectangle([0, 0, w, h * 0.05], fill=(14, 14, 15))
    dr.rectangle([0, h * 0.95, w, h], fill=(14, 14, 15))
    centre(im, fit(decal("animals_dec_v11.png"), w * 0.3, h * 0.84), w * 0.4, h * 0.5)
    name = fit(decal("animals_dec_v01.png"), w * 0.3, h * 0.6)
    centre(im, name, w * 0.67, h * 0.34)
    centre(im, fit(decal("animals_dec_v06.png"), w * 0.12, h * 0.42), w * 0.67, h * 0.74)
    im.convert("RGB").save(path)


BOLD = "/usr/share/fonts/gsfonts/NimbusSansNarrow-Bold.otf"
TYPED = "/usr/share/fonts/gsfonts/NimbusMonoPS-Bold.otf"
HAND = "/usr/share/fonts/gsfonts/Z003-MediumItalic.otf"


def lettered(text, width, font=BOLD, spacing=0):
    """`text` as an L mask `width` wide."""
    f = ImageFont.truetype(font, 200)
    box = f.getbbox(text)
    tw = box[2] - box[0] + spacing * (len(text) - 1)
    im = Image.new("L", (tw + 20, box[3] + 20))
    dr = ImageDraw.Draw(im)
    x = 10
    for c in text:
        dr.text((x, 0), c, fill=255, font=f)
        x += f.getlength(c) + spacing
    im = im.crop(im.getbbox())
    return im.resize((round(width), max(1, round(im.height * width / im.width))), Image.LANCZOS)


def stamp(im, mask, colour, cx, cy):
    ink = Image.new("RGBA", mask.size, (*colour, 255))
    ink.putalpha(mask)
    centre(im, ink, cx, cy)


def bar_front(path, w, h, seed):
    """The Barghest can's front: yellow stencil on sand paint, worn by a lot of Dogtown."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (104, 92, 62, 255))
    stamp(im, wear(spray(lettered("BARGHEST", w * 0.74, spacing=12), 3), rng, 160), (214, 176, 48), w / 2, h * 0.4)
    stamp(im, wear(lettered("PROPERTY OF THE COLONEL", w * 0.5, TYPED), rng, 60), (214, 176, 48), w / 2, h * 0.76)
    im.convert("RGB").save(path)


def bar_lid(path, w, h, seed):
    """The can's lid, inside: the sand paint and a tally of what it cost, in marker."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (92, 82, 56, 255))
    stamp(im, wear(spray(lettered("HANSEN'S CUT", w * 0.66, spacing=8), 2), rng, 90), (20, 20, 18), w / 2, h * 0.3)
    stamp(im, lettered("Tax paid", w * 0.6, HAND), (150, 24, 20), w / 2, h * 0.68)
    im.convert("RGB").save(path)


def vdb_mark(path, w, h, seed):
    """The shrine's board: the Voodoo Boys' chalk mark on black paint."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (12, 18, 22, 255))
    m = wear(fit(decal("voodoo_boys_dec_v5.png"), w * 0.8, h * 0.8).getchannel("A"), rng, 60)
    stamp(im, m, (70, 214, 200), w / 2, h / 2)
    im.convert("RGB").save(path)


def deck_screen(path, w, h, seed):
    """The deck's screen: the one word through Blackwall static. The text and the static are the
    "-glow" image, so they light up."""
    rng = random.Random(seed)
    im = Image.new("L", (w, h))
    px = im.load()
    for y in range(0, h, 4):
        row = rng.randint(0, 34)
        for x in range(0, w, 4):
            v = rng.randint(0, 50) + row
            for dy in range(min(3, h - y)):
                for dx in range(min(4, w - x)):
                    px[x + dx, y + dy] = v
    t = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    t.paste((200, 14, 18, 255), (0, 0), im)
    stamp(t, lettered("BLACKWALL", w * 0.8, TYPED), (255, 60, 56), w / 2, h / 2)
    t = t.convert("RGB")
    t.save(path)
    t.save(str(path).replace(".png", "-glow.png"))


def wraith_wall(path, w, h, seed):
    """The jerrycan's side: rust red paint, the gang's name sprayed by hand."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (112, 42, 26, 255))
    stamp(im, wear(spray(lettered("WRAITHS", w * 0.8, spacing=10), 3), rng, 220), (222, 214, 196), w / 2, h * 0.5)
    im.convert("RGB").save(path)


def nomad_lid(path, w, h, seed):
    """The tobacco tin's paper label, gone yellow: the clan's bone horse over its name."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (214, 194, 150, 255))
    dr = ImageDraw.Draw(im)
    k = min(w, h)
    keyline(dr, w, h, k // 22, (92, 40, 24), max(3, k // 120))
    centre(im, fit(decal("aldecaldos_j.png"), w * 0.56, h * 0.6), w / 2, h * 0.4)
    centre(im, fit(decal("aldecaldos_b.png"), w * 0.78, h * 0.26), w / 2, h * 0.8)
    im.convert("RGB").save(path)


def mox_plate(path, w, h):
    """The clutch's clasp plate, engraved."""
    im = Image.new("RGBA", (w, h), (214, 170, 92, 255))
    stamp(im, lettered("THE MOX", w * 0.82, spacing=10), (70, 40, 20), w / 2, h / 2)
    im.convert("RGB").save(path)


def ncpd_label(path, w, h, seed):
    """The evidence bag's label: the department's blue, the form, and a tired officer's pen."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (236, 234, 226, 255))
    dr = ImageDraw.Draw(im)
    blue = (24, 44, 104)
    dr.rectangle([0, 0, w, h * 0.3], fill=blue)
    stamp(im, lettered("NCPD EVIDENCE", w * 0.8, spacing=6), (236, 234, 226), w / 2, h * 0.15)
    for k, line in enumerate(("CASE NO", "OFFICER", "CHAIN OF CUSTODY")):
        y = h * (0.44 + k * 0.2)
        m = lettered(line, w * (0.14 + 0.012 * len(line)), TYPED)
        stamp(im, m, blue, w * 0.05 + m.width / 2, y)
        dr.line([(w * 0.42, y + h * 0.05), (w * 0.95, y + h * 0.05)], fill=blue, width=max(2, h // 90))
    stamp(im, lettered("oops", w * 0.2, HAND), (30, 30, 34), w * 0.7, h * 0.42)
    im.convert("RGB").save(path)


def kang_lid(path, w, h):
    """The device case's lid: graphite, the game's own Kang Tao wordmark and red tag, a thin teal line."""
    im = Image.new("RGBA", (w, h), (46, 48, 54, 255))
    sheet = Image.open(TEX / "w_kangtao_decal_d01.png").convert("RGBA")
    word_ = sheet.crop((0, 112, 660, 218)).getchannel("A")
    word_ = fit(word_.crop(word_.point(lambda v: 255 if v > 60 else 0).getbbox()), w * 0.66, h * 0.34)
    stamp(im, word_, (228, 230, 234), w * 0.42, h * 0.42)
    tag = fit(sheet.crop((0, 830, 110, 1010)), w * 0.13, h * 0.76)
    centre(im, tag, w * 0.88, h * 0.5)
    ImageDraw.Draw(im).rectangle([w * 0.06, h * 0.8, w * 0.74, h * 0.82], fill=(40, 170, 190))
    im.convert("RGB").save(path)


# Each hack's mark on the game's quickhack sheet: its cell's left and top, 64 px square.
HACK_MARK = {"Optics": (192, 64), "Sonic": (0, 192), "Contagion": (128, 256), "Cyberware": (128, 64),
             "Short": (384, 0), "Cripple": (0, 64), "Overheat": (64, 64), "Glitch": (64, 128),
             "Burnout": (256, 192), "Psycho": (64, 0), "Grenade": (128, 0)}


def hack_mark(stem, px):
    """The hack's mark as a mask of px by px, sharpened back up out of its small cell."""
    x, y = HACK_MARK[stem]
    a = Image.open(TEX / "quickhacks_icons.png").convert("RGBA").getchannel("A").crop((x, y, x + 64, y + 64))
    a = a.resize((px, px), Image.BICUBIC).filter(ImageFilter.GaussianBlur(px / 300))
    return a.point(lambda v: max(0, min(255, (v - 90) * 6)))


def traces(dr, w, h, clear, colour, rng):
    """Circuit traces running in from the edge of the plate, stopping short of a circle `clear` wide."""
    step = h // 24
    width = max(2, h // 280)
    for _ in range(46):
        x, y = rng.randrange(1, w // step) * step, rng.randrange(1, h // step) * step
        pts = [(x, y)]
        for _ in range(rng.randint(2, 5)):
            dx, dy = rng.choice([(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, 1), (1, -1), (-1, -1)])
            n = rng.randint(1, 4) * step
            x, y = x + dx * n, y + dy * n
            if math.hypot(x - w / 2, y - h / 2) < clear or not (step < x < w - step and step < y < h - step):
                break
            pts.append((x, y))
        if len(pts) > 1:
            dr.line(pts, fill=colour, width=width, joint="curve")
            r = width * 2
            px, py = pts[-1]
            dr.ellipse([px - r, py - r, px + r, py + r], outline=colour, width=width)


def hack_lid(path, w, h, stem, colour, name, seed):
    """The cartridge's lid: a dark circuit board with a keyline in the rarity's colour, corner
    brackets and small print, the hack's mark lit in a clear patch."""
    im = Image.new("RGBA", (w, h), (13, 15, 19, 255))
    dr = ImageDraw.Draw(im)
    rng = random.Random(seed)
    dim = tuple(round(c * 0.62) for c in colour)
    traces(dr, w, h, h * 0.44, dim, rng)
    keyline(dr, w, h, h // 24, colour, max(4, h // 60))
    arm, ink = h // 9, max(5, h // 48)
    for cx, sx in ((h // 12, 1), (w - h // 12, -1)):
        for cy, sy in ((h // 12, 1), (h - h // 12, -1)):
            dr.line([(cx + sx * arm, cy), (cx, cy), (cx, cy + sy * arm)], fill=colour, width=ink)
    stamp(im, lettered("QUICKHACK", w * 0.13, spacing=8), colour, w * 0.2, h * 0.13)
    stamp(im, lettered(name, w * 0.2, TYPED), dim, w * 0.8, h * 0.87)
    mark = hack_mark(stem, round(h * 0.76))
    stamp(im, mark, colour, w / 2, h / 2)
    im.convert("RGB").save(path)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    stamp(glow, mark, colour, w / 2, h / 2)
    glow.convert("RGB").save(str(path).replace(".png", "-glow.png"))


def hack_tag(path, w, h, colour, name, seed):
    """The cartridge's front sticker: a stripe in the rarity's colour, the hack's name, a barcode."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (214, 212, 202, 255))
    dr = ImageDraw.Draw(im)
    dr.rectangle([0, 0, w * 0.1, h], fill=colour)
    stamp(im, lettered(name, w * 0.8), (22, 22, 26), w * 0.55, h * 0.3)
    x = round(w * 0.16)
    while x < w * 0.94:
        bar = rng.randint(2, 7) * w // 500
        dr.rectangle([x, h * 0.58, x + bar, h * 0.9], fill=(22, 22, 26))
        x += bar + rng.randint(2, 6) * w // 500
    im.convert("RGB").save(path)


def hack_core(path, px, stem, colour):
    """The Legendary reader's window: the hack's mark, lit, on black."""
    im = Image.new("RGBA", (px, px), (20, 20, 22, 255))
    mark = hack_mark(stem, round(px * 0.9))
    stamp(im, mark, colour, px / 2, px / 2)
    im.convert("RGB").save(path)
    glow = Image.new("RGBA", (px, px), (0, 0, 0, 255))
    stamp(glow, mark, colour, px / 2, px / 2)
    glow.convert("RGB").save(str(path).replace(".png", "-glow.png"))


def nusa_lid(path, w, h, seed):
    """The document box's lid: grey card, a typed file number, and CLASSIFIED stamped on crooked."""
    rng = random.Random(seed)
    im = Image.new("RGBA", (w, h), (168, 168, 164, 255))
    dr = ImageDraw.Draw(im)
    m = lettered("CLASSIFIED", w * 0.66, spacing=6)
    box = Image.new("L", (m.width + w // 12, m.height + h // 8))
    bd = ImageDraw.Draw(box)
    bd.rectangle([0, 0, box.width - 1, box.height - 1], outline=255, width=max(6, h // 50))
    box.paste(m, ((box.width - m.width) // 2, (box.height - m.height) // 2))
    box = wear(box.rotate(rng.uniform(5, 9), expand=True, resample=Image.BICUBIC), rng, 300)
    stamp(im, box, (150, 20, 22), w / 2, h * 0.56)
    t = lettered("NUSA FILE 77-0  LOT: N/A", w * 0.56, TYPED)
    stamp(im, t, (30, 30, 32), w * 0.04 + t.width / 2, h * 0.12)
    dr.line([(w * 0.04, h * 0.2), (w * 0.96, h * 0.2)], fill=(30, 30, 32), width=max(2, h // 120))
    im.convert("RGB").save(path)
