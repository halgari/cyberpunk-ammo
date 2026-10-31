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
FONT = "/usr/share/fonts/gsfonts/NimbusSansNarrow-Bold.otf"
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
    """The lid's label: white card, a red keyline, the red crest over the black wordmark."""
    im = Image.new("RGB", (w, h), (226, 224, 218))
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
    im.paste((16, 16, 18), ((w - wm.width) // 2, top + c + wm.height // 4), wm)
    im.save(path)


def ara_print(path, L, R, u_center=0.5):
    """What's printed on a round, wrapped round it: green is the red crest (scene.py engrave). The
    crest is sized to the round's width and sits on the case, turned to read along the lying round."""
    h = 1024
    w = round(h * 2 * math.pi * R / L)
    im = Image.new("L", (w, h))
    c = round(min(R * 1.5 / L * h, w * 0.4))
    m = emblem(c).rotate(-90)
    im.paste(255, (round(w * u_center - c / 2), round(h * 0.28 - c / 2)), m)
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


def marker(path, w, h, lines, seed):
    """Kraft card with black marker scrawled on it, each letter a little off. image_mat lays the
    card's own grain over this."""
    rng = random.Random(seed)
    im = Image.new("RGB", (w, h), (120, 86, 52))
    size = round(h * (0.9 if len(lines) == 1 else 0.42))
    f = ImageFont.truetype(FONT, size)
    y = h * (0.5 - 0.5 * (len(lines) - 1) * 0.95)
    for line in lines:
        x = w * 0.5 - ImageDraw.Draw(im).textlength(line, font=f) / 2
        for ch in line:
            cw = max(8, round(ImageDraw.Draw(im).textlength(ch, font=f)))
            g = Image.new("L", (cw * 2 + 8, size * 2))
            ImageDraw.Draw(g).text((g.width / 2, g.height / 2), ch, font=f, fill=255, anchor="mm")
            g = g.filter(ImageFilter.GaussianBlur(1.2)).point(lambda v: 255 if v > 70 else 0)
            g = g.rotate(rng.uniform(-8, 8), resample=Image.BICUBIC)
            im.paste((14, 13, 12), (round(x + cw / 2 - g.width / 2), round(y + rng.uniform(-0.04, 0.04) * h - g.height / 2)), g)
            x += cw * 1.04
        y += h * 0.46
    im.save(path)
