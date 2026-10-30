"""Blender side of the icon renders: builds one round (or a box of them) from a spec and renders it.

Run by tools/render/render.py, not by hand:
  blender -b -P tools/render/scene.py -- SPEC.json

SPEC: {"mode": "round"|"box", "out": PNG, "round": {...}, "box": {"front": PNG, "side": PNG}}.
Units are centimetres. Every round is modelled standing on z = 0 along +Z, tip up.
"""
import json
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Quaternion, Vector

SPEC = json.load(open(sys.argv[sys.argv.index("--") + 1]))
SEG = 160
MATS = {}
ASSETS = os.environ.get("AO_ASSETS", os.path.expanduser("~/.cache/ammo-overhaul/assets"))


def scan_tex(nt, asset, kind, vector, colorspace="Non-Color"):
    """Image node for one map of an ambientCG set (Color, Roughness, NormalGL), box-projected."""
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = bpy.data.images.load(os.path.join(ASSETS, asset, f"{asset}_2K-JPG_{kind}.jpg"), check_existing=True)
    t.image.colorspace_settings.name = colorspace
    t.projection = "BOX"
    t.projection_blend = 0.25
    nt.links.new(vector, t.inputs["Vector"])
    return t


# ---------------------------------------------------------------- materials

def _socket(sockets, name, kind):
    return next(s for s in sockets if s.name == name and s.type == kind)


def principled(name, color, metallic=0.0, rough=0.4, wear=0.1, bump=0.08, grime=0.75, scratch=0.0, edge=None,
               scan=None, tile=4.0, **extra):
    """Worn surface. All noise runs in object space (centimetres), so grain is the same size on every
    part and doesn't stretch along long rounds. Layers: fine roughness and bump grain; coarse grime
    patches; ambient-occlusion dirt in crevices; optional fine scratches along the axis (metal);
    optional edge wear where paint is chipped off high edges to the metal colour `edge`."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    N, link = nt.nodes.new, nt.links.new
    bsdf = nt.nodes["Principled BSDF"]
    for k, v in extra.items():
        bsdf.inputs[k].default_value = v
    co = N("ShaderNodeTexCoord").outputs["Object"]

    def noise(scale, detail=8, src=co):
        n = N("ShaderNodeTexNoise")
        n.inputs["Scale"].default_value = scale
        n.inputs["Detail"].default_value = detail
        link(src, n.inputs["Vector"])
        return n.outputs["Fac"]

    def remap(x, a0, a1, b0, b1, clamp=True):
        r = N("ShaderNodeMapRange")
        r.clamp = clamp
        for k, v in (("From Min", a0), ("From Max", a1), ("To Min", b0), ("To Max", b1)):
            r.inputs[k].default_value = v
        link(x, r.inputs["Value"])
        return r.outputs["Result"]

    def mix(fac, a, b):
        mx = N("ShaderNodeMix")
        mx.data_type = "RGBA"
        for sock, v in (("A", a), ("B", b)):
            if isinstance(v, tuple):
                _socket(mx.inputs, sock, "RGBA").default_value = (*v, 1)
            else:
                link(v, _socket(mx.inputs, sock, "RGBA"))
        if isinstance(fac, float):
            _socket(mx.inputs, "Factor", "VALUE").default_value = fac
        else:
            link(fac, _socket(mx.inputs, "Factor", "VALUE"))
        return mx, _socket(mx.outputs, "Result", "RGBA")

    def math_op(op, a, b):
        m_ = N("ShaderNodeMath")
        m_.operation = op
        for i, v in enumerate((a, b)):
            if isinstance(v, float):
                m_.inputs[i].default_value = v
            else:
                link(v, m_.inputs[i])
        return m_.outputs[0]

    def mixf(fac, a, b):
        mx = N("ShaderNodeMix")
        mx.data_type = "FLOAT"
        for sock, v in (("A", a), ("B", b)):
            if isinstance(v, float):
                _socket(mx.inputs, sock, "VALUE").default_value = v
            else:
                link(v, _socket(mx.inputs, sock, "VALUE"))
        link(fac, _socket(mx.inputs, "Factor", "VALUE"))
        return _socket(mx.outputs, "Result", "VALUE")

    geo = N("ShaderNodeNewGeometry")
    # Convex edges: where a wide bevel normal leans away from the true normal.
    bw = N("ShaderNodeBevel")
    bw.samples, bw.inputs["Radius"].default_value = 8, 0.05
    dp = N("ShaderNodeVectorMath")
    dp.operation = "DOT_PRODUCT"
    link(bw.outputs["Normal"], dp.inputs[0])
    link(geo.outputs["Normal"], dp.inputs[1])
    edge_mask = remap(dp.outputs["Value"], 0.995, 0.93, 0, 1)
    # Dust settles on faces that look up.
    sep = N("ShaderNodeSeparateXYZ")
    link(geo.outputs["Normal"], sep.inputs[0])
    dust = math_op("MULTIPLY", remap(sep.outputs["Z"], 0.45, 0.95, 0, 1), remap(noise(2.5, 6), 0.35, 0.7, 0.03, 0.16))

    fine, coarse = noise(30), noise(0.7, 3)
    # Colour: grime patches, then dirt in crevices.
    _, col = mix(remap(coarse, 0.4, 0.75, 0, 0.35), tuple(color), tuple(c * grime for c in color))
    if metallic > 0.5:
        # Tarnish: blotches of dull brown-grey oxide, and rougher there.
        tarn = remap(noise(3.5, 6), 0.52, 0.72, 0, 0.55)
        _, col = mix(tarn, col, tuple(c * 0.45 + d for c, d in zip(color, (0.05, 0.04, 0.03))))
    # Fine tarnish speckle.
    _, col = mix(remap(noise(60, 4), 0.64, 0.7, 0, 0.18), col, tuple(c * 0.7 for c in color))
    ao = N("ShaderNodeAmbientOcclusion")
    ao.only_local = True
    ao.inputs["Distance"].default_value = 0.15
    # Crevices hold dark oily dirt, browner than the surface.
    mx, col = mix(remap(ao.outputs["AO"], 0.2, 1.0, 0.85, 0.0), col,
                  tuple(c * 0.35 + d for c, d in zip(color, (0.03, 0.022, 0.012))))
    if scan:
        # Scanned surface (ambientCG): its roughness, normal and colour variation, tinted to `color`.
        mp = N("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (1 / tile,) * 3
        link(co, mp.inputs["Vector"])
        sv = mp.outputs["Vector"]
        rough_out = remap(scan_tex(nt, scan, "Roughness", sv).outputs["Color"], 0.0, 1.0,
                          max(0.0, rough - wear), rough + wear)
        lum = N("ShaderNodeRGBToBW")
        link(scan_tex(nt, scan, "Color", sv, "sRGB").outputs["Color"], lum.inputs["Color"])
        _, col = mix(remap(lum.outputs["Val"], 0.1, 0.7, 0.6, 0.0), col, tuple(c * 0.55 for c in color))
    else:
        rough_out = remap(fine, 0.3, 0.7, max(0.0, rough - wear), rough + wear)
    # Handling smudges: broad patches a little glossier or duller.
    # (Kept faint on metal: glossy patches break a highlight line into blobs.)
    sm = 0.02 if metallic > 0.5 else 0.07
    rough_out = math_op("ADD", rough_out, remap(noise(1.6, 4), 0.3, 0.7, -sm, sm))
    if metallic > 0.5:
        rough_out = math_op("ADD", rough_out, math_op("MULTIPLY", tarn, 0.08))
    # Worn edges: rubbed brighter and smoother.
    _, col = mix(math_op("MULTIPLY", edge_mask, 0.5), col, tuple(min(1.0, c * 1.35 + 0.03) for c in color))
    rough_out = math_op("SUBTRACT", rough_out, math_op("MULTIPLY", edge_mask, 0.08))
    # Dust: pale, matte.
    if metallic > 0.5:
        dust = math_op("MULTIPLY", dust, 0.3)   # bare metal is handled and wiped; dust would read as plastic
    _, col = mix(dust, col, (0.34, 0.32, 0.29))
    rough_out = mixf(dust, rough_out, 0.85)
    metal_out = None
    if edge is not None:
        # Chipped paint: convex edges, broken up by noise, show bare metal.
        chip = math_op("MULTIPLY", edge_mask, remap(noise(8), 0.4, 0.6, 0, 1))
        _, col = mix(chip, col, tuple(edge))
        mm = N("ShaderNodeMix")
        _socket(mm.inputs, "A", "VALUE").default_value = metallic
        _socket(mm.inputs, "B", "VALUE").default_value = 1.0
        link(chip, _socket(mm.inputs, "Factor", "VALUE"))
        metal_out = _socket(mm.outputs, "Result", "VALUE")
    link(col, bsdf.inputs["Base Color"])
    link(rough_out, bsdf.inputs["Roughness"])
    if metal_out:
        link(metal_out, bsdf.inputs["Metallic"])
    else:
        bsdf.inputs["Metallic"].default_value = metallic
    if scan:
        nm = N("ShaderNodeNormalMap")
        # Drawn metal is smooth: strong scan normals read as dents under strip lights.
        nm.inputs["Strength"].default_value = 0.12 if metallic > 0.5 else 0.6
        link(scan_tex(nt, scan, "NormalGL", sv).outputs["Color"], nm.inputs["Color"])
        normal = nm.outputs["Normal"]
    else:
        b = N("ShaderNodeBump")
        b.inputs["Strength"].default_value = bump
        b.inputs["Distance"].default_value = 0.01
        link(fine, b.inputs["Height"])
        normal = b.outputs["Normal"]
    if scratch and not scan:
        # Fine scratches: noise stretched along the round's axis (Z), thresholded into thin lines.
        mp = N("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (220, 220, 5)
        link(co, mp.inputs["Vector"])
        lines = remap(noise(1.0, 2, mp.outputs["Vector"]), 0.64, 0.66, 0, 1)
        b2 = N("ShaderNodeBump")
        b2.invert = True
        b2.inputs["Strength"].default_value = scratch
        b2.inputs["Distance"].default_value = 0.005
        link(lines, b2.inputs["Height"])
        link(normal, b2.inputs["Normal"])
        normal = b2.outputs["Normal"]
    # Rounded edges in the shading, so hard edges catch a thin line of light.
    bv = N("ShaderNodeBevel")
    bv.samples, bv.inputs["Radius"].default_value = 8, 0.012
    link(normal, bv.inputs["Normal"])
    link(bv.outputs["Normal"], bsdf.inputs["Normal"])
    if metallic > 0.5:
        # Drawing leaves fine grain along the round's axis: highlights stretch around the case.
        tg = N("ShaderNodeTangent")
        tg.direction_type, tg.axis = "RADIAL", "Z"
        bsdf.inputs["Anisotropic"].default_value = 0.35
        link(tg.outputs["Tangent"], bsdf.inputs["Tangent"])
    MATS[name] = m
    return m


def glass(name, color, rough=0.05, transmission=1.0, ior=1.45):
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Transmission Weight"].default_value = transmission
    b.inputs["Roughness"].default_value = rough
    b.inputs["IOR"].default_value = ior
    MATS[name] = m
    return m


def emission(name, color, strength):
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Emission Color"].default_value = (*color, 1)
    b.inputs["Emission Strength"].default_value = strength
    MATS[name] = m
    return m


def hazard(name, scale):
    """Yellow and black diagonal tape, in the object's own coordinates."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.5
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Rotation"].default_value = (0, math.radians(45), 0)
    mp.inputs["Scale"].default_value = (1 / scale,) * 3
    w = nt.nodes.new("ShaderNodeTexWave")
    w.wave_type = "BANDS"
    w.bands_direction = "X"
    w.inputs["Scale"].default_value = 1.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    ramp.color_ramp.elements[0].color = (0.02, 0.02, 0.02, 1)
    ramp.color_ramp.elements[1].position = 0.5
    ramp.color_ramp.elements[1].color = (0.85, 0.6, 0.02, 1)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], w.inputs["Vector"])
    nt.links.new(w.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    MATS[name] = m
    return m


def image_mat(name, path, rough=0.8, color=(0.47, 0.33, 0.2), lacquer=None):
    """Printed card: the panel art multiplied over scanned cardboard (Cardboard004), with its normal
    and roughness. The print is mapped by the panel's UVs; the card repeats every few centimetres.
    With no path it is bare unprinted kraft card of `color`."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    if path:
        art = nt.nodes.new("ShaderNodeTexImage")
        art.image = bpy.data.images.load(path)
    else:
        art = nt.nodes.new("ShaderNodeRGB")
        art.outputs["Color"].default_value = (*color, 1)
    co = nt.nodes.new("ShaderNodeTexCoord").outputs["Object"]
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1 / 12,) * 3
    nt.links.new(co, mp.inputs["Vector"])
    card = scan_tex(nt, "Cardboard004", "Color", mp.outputs["Vector"], "sRGB")
    lum = nt.nodes.new("ShaderNodeRGBToBW")
    nt.links.new(card.outputs["Color"], lum.inputs["Color"])
    k = nt.nodes.new("ShaderNodeMapRange")
    k.inputs["From Min"].default_value, k.inputs["From Max"].default_value = 0.3, 0.7
    k.inputs["To Min"].default_value, k.inputs["To Max"].default_value = 0.75, 1.05
    nt.links.new(lum.outputs["Val"], k.inputs["Value"])
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type, mul.blend_type = "RGBA", "MULTIPLY"
    _socket(mul.inputs, "Factor", "VALUE").default_value = 1.0
    nt.links.new(art.outputs[0], _socket(mul.inputs, "A", "RGBA"))
    comb = nt.nodes.new("ShaderNodeCombineColor")
    for ch in ("Red", "Green", "Blue"):
        nt.links.new(k.outputs["Result"], comb.inputs[ch])
    nt.links.new(comb.outputs["Color"], _socket(mul.inputs, "B", "RGBA"))
    nt.links.new(_socket(mul.outputs, "Result", "RGBA"), bsdf.inputs["Base Color"])
    if lacquer:
        # Legendary boxes (lacquer = {metal, rough, glow}): a glossy clear coat over the print, which
        # can be metal foil, little card texture, and glowing lines (the art's "-glow" image).
        bsdf.inputs["Metallic"].default_value = lacquer.get("metal", 0.0)
        bsdf.inputs["Roughness"].default_value = lacquer.get("rough", 0.5)
        bsdf.inputs["Coat Weight"].default_value = 1.0
        bsdf.inputs["Coat Roughness"].default_value = 0.08
        glow = path and path.replace(".png", "-glow.png")
        if glow and os.path.exists(glow):
            g = nt.nodes.new("ShaderNodeTexImage")
            g.image = bpy.data.images.load(glow)
            nt.links.new(g.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = lacquer.get("glow", 6.0)
    else:
        r = scan_tex(nt, "Cardboard004", "Roughness", mp.outputs["Vector"])
        nt.links.new(r.outputs["Color"], bsdf.inputs["Roughness"])
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nm.inputs["Strength"].default_value = 0.15 if lacquer else 0.8
    nt.links.new(scan_tex(nt, "Cardboard004", "NormalGL", mp.outputs["Vector"]).outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m


BRASS = lambda: principled("Brass", (0.84, 0.55, 0.2), 1.0, 0.22, wear=0.03, grime=0.75, scan="Metal011", tile=1.5)
COPPER = lambda: principled("Copper", (0.76, 0.38, 0.20), 1.0, 0.25, wear=0.03, grime=0.8, scan="Metal011", tile=3.0)
LEAD = lambda: principled("Lead", (0.36, 0.36, 0.38), 0.4, 0.55, bump=0.1)
STEEL = lambda: principled("Steel", (0.58, 0.58, 0.60), 1.0, 0.24, wear=0.08, grime=0.8, scan="Metal009")
GUNMETAL = lambda: principled("Gunmetal", (0.26, 0.26, 0.28), 1.0, 0.4, wear=0.12, grime=0.8, scan="Metal009")
NICKEL = lambda: principled("Nickel", (0.66, 0.64, 0.60), 1.0, 0.4, bump=0.02, grime=0.7)
# Legendary cases: polished, nearly unworn.
POLISHED_GOLD = lambda: principled("PolishedGold", (1.0, 0.7, 0.26), 1.0, 0.12, wear=0.0, bump=0.01, grime=0.95)
CHROME = lambda: principled("Chrome", (0.86, 0.86, 0.9), 1.0, 0.07, wear=0.0, bump=0.005, grime=0.97)
GREEN_LACQUER = lambda: principled("GreenLacquer", (0.13, 0.17, 0.07), 0.2, 0.42, bump=0.004)
WHITE_PAINT = lambda: principled("WhitePaint", (0.78, 0.77, 0.72), 0.0, 0.5, bump=0.02, edge=(0.4, 0.4, 0.42))


# ---------------------------------------------------------------- geometry

# Paint colours (linear RGB) for tips, bands, hulls and ID bands, by name.
PAINTS = {"black": (0.012, 0.012, 0.014), "blue": (0.02, 0.09, 0.42), "green": (0.05, 0.3, 0.06),
          "yellow": (0.8, 0.55, 0.02), "red": (0.6, 0.03, 0.02), "orange": (0.85, 0.22, 0.02),
          "white": (0.78, 0.77, 0.72), "silver": (0.6, 0.6, 0.62), "teal": (0.02, 0.42, 0.45),
          "gold": (0.8, 0.55, 0.15), "grey": (0.22, 0.23, 0.25), "olive": (0.17, 0.19, 0.07),
          "darkred": (0.22, 0.01, 0.01), "pink": (0.7, 0.12, 0.25)}


def paint(name, gloss=False):
    """Painted or lacquered colour: tip paint, bands, ID bands."""
    return principled("Paint" + name + ("G" if gloss else ""), PAINTS[name], 0.0, 0.18 if gloss else 0.4,
                      bump=0.006, wear=0.06, grime=0.8)


def revolve(name, profile, perturb=None):
    """Mesh from a list of (r, z, material) points revolved around Z. The material of a point
    covers the band up to the next point. perturb(theta, i, r, z) -> (dr, dz)."""
    mats = []
    for p in profile:
        if p[2] not in mats:
            mats.append(p[2])
    # Split long segments: smooth shading blends normals across a whole face, so a long face next to a
    # crease would shade bent along its length.
    dense = [profile[0]]
    for (r0, z0, m0), (r1, z1, m1) in zip(profile, profile[1:]):
        n = max(1, int(math.hypot(r1 - r0, z1 - z0) / 0.08))
        dense += [(r0 + (r1 - r0) * k / n, z0 + (z1 - z0) * k / n, m0 if k < n else m1) for k in range(1, n + 1)]
    pidx = [0]   # perturb gets the index of the original profile point a dense point came from
    for i, ((r0, z0, _), (r1, z1, _)) in enumerate(zip(profile, profile[1:])):
        n = max(1, int(math.hypot(r1 - r0, z1 - z0) / 0.08))
        pidx += [i if k < n else i + 1 for k in range(1, n + 1)]
    profile = dense
    th = [2 * math.pi * k / SEG for k in range(SEG)]
    verts, faces, fmat = [], [], []
    for i, (r, z, _) in enumerate(profile):
        for t in th:
            dr, dz = perturb(t, pidx[i], r, z) if perturb else (0.0, 0.0)
            verts.append(((r + dr) * math.cos(t), (r + dr) * math.sin(t), z + dz))
    for i in range(len(profile) - 1):
        a, b = i * SEG, (i + 1) * SEG
        for k in range(SEG):
            j = (k + 1) % SEG
            faces.append((a + k, a + j, b + j, b + k))
            fmat.append(mats.index(profile[i][2]))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    for poly, mi in zip(me.polygons, fmat):
        poly.material_index = mi
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    me.shade_smooth()
    me.set_sharp_from_angle(angle=math.radians(35))   # real creases (shoulders, rims, grooves) stay crisp
    for m in mats:
        me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def arc(cx, cz, rad, a0, a1, n, mat):
    return [(cx + rad * math.cos(a), cz + rad * math.sin(a), mat)
            for a in (a0 + (a1 - a0) * k / n for k in range(n + 1))]


def head_profile(rc, rim, rimmed, mat):
    """Case head from the axis outward: primer pocket, rim, extractor groove (rimless only)."""
    p = [(0, 0.004, NICKEL()), (rc * 0.32, 0.004, mat), (rc * 0.35, 0, mat)]
    if rimmed:
        p += [(rim * 0.98, 0, mat), (rim, rc * 0.03, mat), (rim, rc * 0.12, mat), (rim * 0.97, rc * 0.15, mat),
              (rc, rc * 0.16, mat)]
    else:
        p += [(rc * 0.97, 0, mat), (rc, rc * 0.04, mat), (rc, rc * 0.16, mat), (rc * 0.98, rc * 0.18, mat),
              (rc * 0.82, rc * 0.24, mat), (rc * 0.82, rc * 0.32, mat), (rc, rc * 0.42, mat)]
    return p


def tip_profile(rb, z0, length, shape, hp, mat):
    """Bullet from the case mouth (rb at z0) to the tip. shape: round | flat | spitzer."""
    p = [(rb, z0, mat)]
    if shape == "spitzer":
        bear = length * 0.28
        p.append((rb, z0 + bear, mat))
        n = 16
        stop = 0.82 if hp else 1.0
        for k in range(1, n + 1):
            t = stop * k / n
            p.append((rb * (1 - t ** 1.7) ** 0.8, z0 + bear + (length - bear) * t, mat))
    else:
        bear = length * 0.3
        p.append((rb, z0 + bear, mat))
        stop = math.radians(55 if hp else (62 if shape == "flat" else 90))
        n = 14
        for k in range(1, n + 1):
            a = stop * k / n
            p.append((rb * math.cos(a), z0 + bear + (length - bear) * math.sin(a), mat))
    top = p[-1][1]
    if hp:
        ro = p[-1][0]
        p += [(ro * 0.82, top + length * 0.01, mat), (ro * 0.62, top - length * 0.08, LEAD()),
              (ro * 0.35, top - length * 0.2, LEAD()), (0, top - length * 0.24, LEAD())]
    elif p[-1][0] > 1e-4:
        p.append((0, top + length * 0.01, mat))
    return p


def notches(profile, hp):
    """Six notches around a hollow point's mouth (the two points nearest the rim)."""
    if not hp:
        return None
    rim = len(profile) - 4

    def f(t, i, r, z):
        if i in (rim - 1, rim, rim + 1):
            d = (t * 6 / (2 * math.pi)) % 1.0
            d = min(d, 1 - d)
            return (0.0, -r * 0.35 * math.exp(-(d / 0.06) ** 2))
        return (0.0, 0.0)
    return f


JACKETS = {
    "copper": COPPER,
    "lead": LEAD,
    "steel": STEEL,
    "dark": lambda: principled("DarkJacket", (0.08, 0.085, 0.1), 0.6, 0.45, wear=0.08, grime=0.8),
    "rubber": lambda: principled("Rubber", (0.025, 0.025, 0.027), 0.0, 0.75, bump=0.02, wear=0.02, grime=0.6),
}


BLACK_CASE = lambda: principled("BlackCase", (0.03, 0.03, 0.035), 0.7, 0.35, wear=0.1, grime=0.8,
                                edge=(0.84, 0.55, 0.2))


def case_mat(s, default):
    c = s.get("case_mat")
    return {"green": GREEN_LACQUER, "nickel": NICKEL, "black": BLACK_CASE, "gold": POLISHED_GOLD,
            "chrome": CHROME}.get(c, lambda: default)()


def bullet(s, rb, z0, length, shape):
    """The bullet's profile, with the round's jacket, painted tip (s["tip"], over the last
    s["tipfrac"] of its length) and nose length (s["nose_mult"])."""
    length *= s.get("nose_mult", 1.0)
    mat = JACKETS[s.get("jacket", "copper")]()
    p = tip_profile(rb, z0, length, shape, s.get("hp", False), mat)
    if s.get("tip"):
        tm = emission("TipGlow" + s["tip"], PAINTS[s["tip"]], 6.0) if s.get("tipglow") else \
            paint(s["tip"], gloss=s.get("tipfrac", 0.0) >= 0.3)
        z1 = z0 + length * (1 - s.get("tipfrac", 0.22))
        p = [(r, z, tm if z >= z1 and m is mat else m) for r, z, m in p]
    return p, z0 + length


def scored(s, start, prev):
    """Shredders: six slits down the nose, from profile point `start` on (combined with `prev`)."""
    if not s.get("scored"):
        return prev

    def f(t, i, r, z):
        dr, dz = prev(t, i, r, z) if prev else (0.0, 0.0)
        if i > start + 2:
            d = (t * 6 / (2 * math.pi)) % 1.0
            d = min(d, 1 - d)
            dr -= r * 0.16 * math.exp(-(d / 0.035) ** 2)
        return (dr, dz)
    return f


def pistol(s):
    rc, rb = s["d"] / 2 * 1.04, s["d"] / 2
    case = case_mat(s, BRASS())
    p = head_profile(rc, s.get("rim", rc) / 1.0 if s.get("rimmed") else rc, s.get("rimmed", False), case)
    p += [(rc, s["case"] * 0.5, case), (rc * 0.995, s["case"], case)]
    start = len(p)
    tip, oal = bullet(s, rb, s["case"], s["oal"] - s["case"], s.get("nose", "round"))
    p += tip
    ob = revolve("Round", p, scored(s, start, notches(p, s.get("hp", False))))
    seal_ring(s, ob, rc * 0.995, s["case"])
    return ob, oal, s.get("rim", rc)


RED_SEAL = lambda: principled("RedSeal", (0.55, 0.02, 0.02), 0.0, 0.3, bump=0.004)


def seal_ring(s, parent, r, z):
    """+P marking: a red lacquer ring round the case mouth; with s["glow"], a glowing one (Legendary)."""
    if not s.get("seal") and not s.get("glow"):
        return
    m = emission("Glow" + s["glow"], PAINTS[s["glow"]], 8.0) if s.get("glow") else RED_SEAL()
    q = [(r * 0.98, z - 0.07, m), (r * 1.012, z - 0.06, m), (r * 1.012, z + 0.005, m), (r * 0.98, z + 0.01, m)]
    revolve("Seal", q).parent = parent


def rifle(s):
    rc, rn, rb = s["base"] / 2, s["neck"] / 2, s["neck"] / 2 * 0.93
    case = case_mat(s, BRASS())
    p = head_profile(rc, rc, False, case)
    sh0, sh1 = s["shoulder"]
    p += [(rc * 0.985, sh0, case), (rc * 0.95, sh0 + (sh1 - sh0) * 0.25, case), (rn * 1.05, sh1, case),
          (rn, sh1 + 0.04, case), (rn, s["case"], case)]
    start = len(p)
    tip, oal = bullet(s, rb, s["case"], s["oal"] - s["case"], s.get("nose", "spitzer"))
    p += tip
    ob = revolve("Round", p, scored(s, start, notches(p, s.get("hp", False))))
    seal_ring(s, ob, rn, s["case"])
    return ob, oal, rc


def fold(t, n=6, w=0.07):
    d = (t * n / (2 * math.pi)) % 1.0
    d = min(d, 1 - d)
    return math.exp(-(d / w) ** 2)


def shell(s):
    R, L, H = s["R"], s["L"], s["head"]
    hulls = {"red": (0.42, 0.025, 0.02), "black": (0.03, 0.03, 0.032), "green": (0.2, 0.42, 0.14),
             "yellow": (0.75, 0.5, 0.03), "orange": (0.8, 0.2, 0.02), "grey": (0.32, 0.33, 0.35),
             "olive": (0.15, 0.17, 0.06), "darkred": (0.16, 0.01, 0.01), "white": (0.75, 0.74, 0.7),
             "blue": (0.03, 0.1, 0.4)}
    if s["color"] == "clear":
        # Clear hull: the load shows through.
        hullm = glass("HullClear", (0.85, 0.9, 0.92), 0.12, transmission=0.95, ior=1.5)
    else:
        hullm = principled("Hull" + s["color"], hulls[s["color"]], 0.0, 0.48, wear=0.12, grime=0.85, scan="Plastic006",
                           tile=6.0, **{"Coat Weight": 0.25, "Coat Roughness": 0.3})
    root = bpy.data.objects.new("Round", None)
    bpy.context.collection.objects.link(root)
    rim = R * 1.1
    hp = [(0, 0.004, NICKEL()), (R * 0.27, 0.004, BRASS()), (R * 0.3, 0, BRASS()), (rim * 0.98, 0, BRASS()),
          (rim, 0.02, BRASS()), (rim, 0.14 * R, BRASS()), (rim * 0.97, 0.16 * R, BRASS()), (R * 1.0, 0.18 * R, BRASS()),
          (R * 0.97, 0.24 * R, BRASS()), (R * 0.97, 0.3 * R, BRASS()), (R * 1.025, 0.4 * R, BRASS()),
          (R * 1.025, H - 0.03, BRASS()), (R * 1.015, H, BRASS()), (R * 1.003, H + 0.02, BRASS())]
    heads = {"steel": NICKEL, "gold": POLISHED_GOLD, "chrome": CHROME}
    revolve("Head", [(r, z, heads[s["head_mat"]]() if m is not hp[0][2] else m) for r, z, m in hp]
            if s.get("head_mat") in heads else hp).parent = root
    if s.get("band"):
        bm = paint(s["band"])
        zb = H + (L - H) * 0.45
        revolve("Band", [(R * 0.99, zb - 0.09 * L, bm), (R * 1.01, zb - 0.085 * L, bm), (R * 1.01, zb + 0.085 * L, bm),
                         (R * 0.99, zb + 0.09 * L, bm)]).parent = root
    if s.get("darts_inside"):
        # A bundle of steel darts down the hull, seen through a clear hull.
        for k in range(7):
            a, rr = k * 2 * math.pi / 6, (0.0 if k == 6 else R * 0.45)
            dart = revolve("Dart", [(0, H + 0.05, STEEL()), (R * 0.1, H + 0.1, STEEL()), (R * 0.1, L - 0.9 * R, STEEL()),
                                    (0, L - 0.3 * R, STEEL())])
            dart.location = (math.cos(a) * rr, math.sin(a) * rr, 0)
            dart.parent = root
    side = [(R, z, hullm) for z in [H - 0.05 + (L - 0.18 * R - H + 0.05) * k / 50 for k in range(51)]]
    if s["crimp"] == "star":
        r0 = R - 0.18 * R
        prof = side + arc(r0, L - 0.18 * R, 0.18 * R, 0, math.pi / 2, 10, hullm)[1:]
        ncap, n = len(prof), 26
        prof += [(r0 * (1 - k / n), L - 0.22 * R * (k / n) ** 0.7, hullm) for k in range(1, n + 1)]

        def pert(t, i, r, z):
            if i >= ncap:   # the star crimp: six folds sink in, the panels between bulge a little
                f, sf = fold(t), r / r0
                return (0.0, -0.24 * R * f * (1 - sf) ** 0.5 * sf ** 0.3 + 0.02 * R * (1 - f) * sf)
            if L - 0.25 * R > z > H + 0.05:
                return (R * 0.007 * math.cos(72 * t), 0.0)
            return (0.0, 0.0)
        revolve("Hull", prof, pert).parent = root
    else:
        ri = R * 0.8
        prof = side + arc(R - 0.15 * R, L - 0.15 * R, 0.15 * R, 0, math.pi * 0.95, 12, hullm)[1:]
        prof += [(ri, L - 0.2 * R, hullm), (ri, L - 0.6 * R, hullm)]

        def pert(t, i, r, z):
            if L - 0.25 * R > z > H + 0.05 and r >= R * 0.999:
                return (R * 0.007 * math.cos(72 * t), 0.0)
            return (0.0, 0.0)
        revolve("Hull", prof, pert).parent = root
        zt = L - 0.17 * R
        load = s.get("load", "lead")
        faces = {"lead": LEAD, "rubber": JACKETS["rubber"],
                 "bag": lambda: principled("Bag", (0.32, 0.26, 0.14), 0.0, 0.9, bump=0.15, wear=0.02),
                 "thermite": lambda: emission("Thermite", (1.0, 0.3, 0.04), 6.0),
                 "flare": lambda: paint("red", gloss=True), "darts": LEAD, "frag": LEAD}
        fm = faces[load]()
        lead = [(0, zt, fm)]
        for k, rr in enumerate([0.12, 0.2, 0.32, 0.42, 0.55, 0.66, 0.76]):
            lead += [(ri * rr, zt - (0.012 if k % 2 else 0.0) * R, fm)]
        lead += [(ri * 0.99, zt - 0.04 * R, fm), (ri * 0.99, zt - 0.4 * R, fm)]
        revolve("Load", lead).parent = root
        if load == "darts":
            # Flechette tips standing out of the mouth.
            for k in range(7):
                a, rr = k * 2 * math.pi / 6, (0.0 if k == 6 else ri * 0.55)
                dart = revolve("Dart", [(0, zt, STEEL()), (R * 0.07, zt, STEEL()), (R * 0.07, zt + 0.25 * R, STEEL()),
                                        (0, zt + 0.55 * R, STEEL())])
                dart.location = (math.cos(a) * rr, math.sin(a) * rr, 0)
                dart.parent = root
            L += 0.55 * R
        elif load == "frag":
            # A Frag-12's nose: an olive projectile with a yellow band standing out of the hull.
            ol, yb = paint("olive"), paint("yellow")
            nose = [(0, zt, ol), (ri * 0.9, zt, ol), (ri * 0.9, zt + 0.25 * R, yb), (ri * 0.9, zt + 0.4 * R, ol)]
            nose += [(ri * 0.9 * (1 - t ** 1.6) ** 0.8, zt + 0.4 * R + 0.9 * R * t, ol) for t in (0.2, 0.4, 0.6, 0.8, 0.95)]
            nose += [(0, zt + 1.32 * R, ol)]
            revolve("Frag", nose).parent = root
            L += 1.3 * R
    return root, L, rim


def rail(s):
    r, L = s["r"], s["L"]
    b = r * 0.12
    root = bpy.data.objects.new("Round", None)
    bpy.context.collection.objects.link(root)
    cores = {"steel": STEEL, "gunmetal": GUNMETAL,
             "du": lambda: principled("DU", (0.05, 0.05, 0.045), 0.8, 0.55, wear=0.05, grime=0.9),
             "frost": lambda: principled("Frost", (0.55, 0.72, 0.9), 0.9, 0.28, wear=0.04, grime=0.6),
             "gold": POLISHED_GOLD, "chrome": CHROME}
    core = GUNMETAL if s.get("gunmetal") else cores[s.get("core", "steel")]   # Bricks: dark gunmetal
    ringm = (lambda: emission("Coil" + s["coil"], PAINTS[s["coil"]], 8.0)) if s.get("coil") else COPPER
    p = [(0, 0, core()), (r - b, 0, core()), (r, b, core())]
    for zc in s["rings"]:
        z = zc * L
        p += [(r, z - 0.05 * L, ringm()), (r * 1.01, z - 0.04 * L, ringm()), (r * 1.01, z + 0.04 * L, core()),
              (r, z + 0.05 * L, core())]
    for zc in s.get("cuts", []):
        # Split Slugs: a deep dark cut where the slug comes apart.
        z = zc * L
        p += [(r, z - 0.02 * L, core()), (r * 0.7, z - 0.01 * L, GUNMETAL()), (r * 0.7, z + 0.01 * L, core()),
              (r, z + 0.02 * L, core())]
    if s.get("point"):
        # A long pointed penetrator nose.
        p += [(r, L * 0.75, core())] + [(r * (1 - t ** 1.4), L * 0.75 + L * 0.45 * t, core()) for t in (0.3, 0.6, 0.85, 1.0)]
        L = L * 1.2
    else:
        p += [(r, L - b, core()), (r - b, L, core()), (0, L, core())]
    revolve("Core", p).parent = root
    out = r
    if s.get("sleeve"):
        rs = r * 1.12
        # Frosted, faintly milky polymer wrap: cloudier and more refractive than clear glass, so a
        # Sleever reads differently from a bare rail slug.
        tint = {"green": (0.35, 0.8, 0.3)}.get(s.get("sleeve_color"), (0.82, 0.88, 0.92))
        sl = glass("Sleeve" + s.get("sleeve_color", ""), tint, 0.24, transmission=0.9, ior=1.6)
        q = [(0, -0.06 * L, sl)] + arc(rs - 0.3 * rs, -0.06 * L + 0.3 * rs, 0.3 * rs, -math.pi / 2, 0, 6, sl)[1:]
        q += arc(rs - 0.3 * rs, L * 1.06 - 0.3 * rs, 0.3 * rs, 0, math.pi / 2, 6, sl) + [(0, L * 1.06, sl)]
        revolve("Sleeve", q).parent = root
        out = rs
    return root, L * (1.06 if s.get("sleeve") else 1.0), out


def fin_mesh(r, span, cr, ct, z0, thick, mat):
    """One swept fin in the XZ plane: root chord cr on the body, tip chord ct, trailing edge at z0."""
    me = bpy.data.meshes.new("Fin")
    me.from_pydata([(r * 0.9, 0, z0), (r * 0.9, 0, z0 + cr), (r + span, 0, z0 + ct), (r + span, 0, z0)], [],
                   [(0, 1, 2, 3)])
    ob = bpy.data.objects.new("Fin", me)
    bpy.context.collection.objects.link(ob)
    sol = ob.modifiers.new("t", "SOLIDIFY")
    sol.thickness, sol.offset = thick, 0
    bev = ob.modifiers.new("b", "BEVEL")
    bev.width, bev.segments = thick * 0.4, 2
    me.materials.append(mat)
    return ob


GOLD = lambda: principled("Gold", (1.0, 0.76, 0.33), 1.0, 0.25, wear=0.05, grime=0.9)
# Blue-grey anodizing: dark, but light enough that the round's shape reads at icon size.
ANOD = lambda: principled("Anodized", (0.14, 0.17, 0.22), 0.85, 0.32, wear=0.1, grime=0.8, scan="Metal009", tile=2.0)
# Painted ID band per load (teal Seekers, red Short-Fuse), also on the cassette's rear band.
def id_paint(name):
    return principled("Id" + name, PAINTS[name], 0.0, 0.35, bump=0.01, wear=0.08, grime=0.8)


def nose_mat(s, default):
    """Smart nose: gold (Hunter's seeker head), copper (Shaped Charge's cone), else the body."""
    return {"gold": GOLD, "copper": COPPER, "chrome": CHROME}.get(s.get("nose_mat"), lambda: default)()


def sensor_glass(s):
    """The seeker's sensor: dark glass, or glowing green (Hack Carrier)."""
    if s.get("sensor") == "green":
        return emission("SensorGreen", (0.1, 0.9, 0.25), 5.0)
    return glass("SensorGlass", (0.04, 0.06, 0.09), 0.03)
# Moulded polymer: dark, slightly glossy under a thin clear coat.
POLY = lambda: principled("CassetteBody", (0.06, 0.07, 0.085), 0.0, 0.36, wear=0.1, grime=0.8,
                          scan="Plastic006", tile=1.5, **{"Coat Weight": 0.2, "Coat Roughness": 0.1,
                                                          "Specular IOR Level": 0.4})


def sensor_mat():
    return emission("Sensor", (0.1, 0.35, 0.9), 0.6) if "SensorGlass" in MATS else glass("SensorGlass", (0.05, 0.07, 0.1), 0.03)


def cube(name, size, loc, mat, bevel=0.0, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        bv = ob.modifiers.new("b", "BEVEL")
        bv.width, bv.segments = bevel, 2
    if mat:
        ob.data.materials.append(mat)
    return ob


def tip_profile_smart(r, z0, nl, seeker, body, g=None, tip=None):
    """Ogive nose from radius r at z0, length nl. Seekers end in a small dark glass sensor tip.
    tip: a paint colour over the front of the nose (the payload's colour)."""
    p, n = [], 20
    stop = 0.86 if seeker else 1.0
    tm = paint(tip, gloss=True) if tip else None
    for k in range(n + 1):
        t = stop * k / n
        p.append((r * (1 - t ** 1.8) ** 0.75 if t < 1 else 0.0, z0 + nl * t, tm if tm and t >= 0.45 else body))
    if seeker:
        g = g or glass("SensorGlass", (0.04, 0.06, 0.09), 0.03)
        rt, zt = p[-1][0], p[-1][1]
        p[-1] = (rt, zt, g)
        p += [(rt * 0.6, zt + nl * 0.1, g), (0, zt + nl * 0.13, g)]
    return p


def dian(s):
    """Kang Tao style smart round (after the game's Dian projectile): finless; base ring, tail with gold
    programming contacts, a helical twist-groove guidance band, a long ogive nose. Seekers carry a glass
    sensor tip; Dumbfires a steel tip and a hazard band on the tail."""
    r, L = s["r"], s["L"]
    dumb = s.get("dumbfire", False)
    root = bpy.data.objects.new("Round", None)
    bpy.context.collection.objects.link(root)
    body, band = ANOD(), STEEL()
    zb0, zb1 = 0.36 * L, 0.48 * L
    p = [(0, 0.004 * L, body), (r * 0.5, 0.0, body), (r * 0.92, 0.0, body), (r * 0.95, 0.03 * L, body),
         (r * 0.9, 0.045 * L, body), (r * 0.9, 0.06 * L, body), (r, 0.07 * L, body)]
    if dumb:
        hz = hazard("Hazard", r * 0.9)
        p += [(r, 0.2 * L, hz), (r * 1.004, 0.2 * L + 0.003, hz), (r * 1.004, 0.28 * L, body), (r, 0.281 * L, body)]
    p += [(r, zb0 - 0.01 * L, band)]
    nb = 30
    p += [(r, zb0 + (zb1 - zb0) * k / nb, band) for k in range(nb + 1)]
    if s.get("idband") and not dumb:
        idm = id_paint(s["idband"])
        p += [(r, zb1 + 0.005 * L, idm), (r * 1.004, zb1 + 0.008 * L, idm), (r * 1.004, zb1 + 0.07 * L, body)]
        zb1 += 0.07 * L
    p += [(r, zb1 + 0.005 * L, body), (r * 0.985, zb1 + 0.02 * L, body)]
    nose = tip_profile_smart(r * 0.985, zb1 + 0.02 * L, L - zb1 - 0.02 * L - (0.0 if dumb else 0.0),
                             not dumb and not s.get("noseeker"), STEEL() if dumb else nose_mat(s, body), sensor_glass(s),
                             s.get("tip"))
    p += nose[1:]
    first_band = next(i for i, q in enumerate(p) if q[2] is band)

    def pert(t, i, rr, z):
        if zb0 <= z <= zb1 and i >= first_band:
            ph = (t / (2 * math.pi)) * 6 + (z - zb0) / ((zb1 - zb0) * 0.9)
            d = ph % 1.0
            d = min(d, 1 - d)
            return (-0.07 * r * math.exp(-(d / 0.09) ** 2), 0.0)
        return (0.0, 0.0)
    revolve("Body", p, pert).parent = root
    # Gold programming contacts on the tail.
    for k in range(3):
        c = cube("Contact", (r * 0.22, r * 0.05, r * 0.3), (0, -r * 0.99, 0.11 * L + k * r * 0.42), GOLD(), r * 0.02)
        c.parent = root
    return root, L, r


def cassette(s):
    """Palica style square cassette: eight cells around a solid core, a micro smart round in each cell with
    its nose just below the front face; grooves along the sides, a band at the rear, a pin in the core."""
    cr, Lc = s["cell_r"], s["L"]
    pitch = cr * 2.35
    side = pitch * 3 + cr * 0.7
    root = bpy.data.objects.new("Round", None)
    bpy.context.collection.objects.link(root)
    blk = cube("Cassette", (side, side, Lc), (0, 0, Lc / 2), POLY(), side * 0.03)
    cutters = []
    for i in (-1, 0, 1):
        for j in (-1, 0, 1):
            if i == 0 and j == 0:
                continue
            bpy.ops.mesh.primitive_cylinder_add(radius=cr, depth=Lc * 0.9, location=(i * pitch, j * pitch, Lc * 0.55),
                                                vertices=32)
            cutters.append((bpy.context.active_object, i, j))
    # Grooves along each side.
    for k in range(4):
        a = k * math.pi / 2
        for off in (-0.22, 0.22):
            x, y = math.cos(a) * side / 2, math.sin(a) * side / 2
            ox, oy = -math.sin(a) * side * off, math.cos(a) * side * off
            g = cube("Groove", (side * 0.06, side * 0.06, Lc * 0.62), (x + ox, y + oy, Lc * 0.52), None, rot=(0, 0, a))
            cutters.append((g, None, None))
    for c, _, _ in cutters:
        m = blk.modifiers.new("cut", "BOOLEAN")
        m.object, m.operation, m.solver = c, "DIFFERENCE", "EXACT"
    bpy.context.view_layer.objects.active = blk
    for m in list(blk.modifiers):
        if m.type == "BOOLEAN":
            bpy.ops.object.modifier_apply(modifier=m.name)
    for c, _, _ in cutters:
        bpy.data.objects.remove(c)
    blk.parent = root
    # Rear band painted like the box stripe: hazard for Dumbfires, white for Seekers.
    band = cube("RearBand", (side * 1.04, side * 1.04, Lc * 0.12), (0, 0, Lc * 0.08),
                hazard("Hazard", side * 0.15) if s.get("dumbfire")
                else id_paint(s["idband"]) if s.get("idband") else WHITE_PAINT(), side * 0.02)
    band.parent = root
    if s.get("front"):
        # The payload's colour round the front, as four plates so the cells stay open.
        fm = paint(s["front"])
        for k in range(4):
            a = k * math.pi / 2
            plate = cube("FrontBand", (side * 1.04, side * 0.02, Lc * 0.1),
                         (-math.sin(a) * side * 0.51, math.cos(a) * side * 0.51, Lc * 0.88), fm, side * 0.005, rot=(0, 0, a))
            plate.parent = root
    bpy.ops.mesh.primitive_cylinder_add(radius=cr * 0.35, depth=cr * 0.4, location=(0, 0, Lc + cr * 0.1), vertices=24)
    pin = bpy.context.active_object
    pin.data.materials.append(GOLD())
    pin.parent = root
    rs = dict(kind="dian", r=cr * 0.86, L=Lc * 0.8, dumbfire=s.get("dumbfire", False), idband=s.get("idband"),
              **{k: s[k] for k in ("nose_mat", "sensor", "noseeker", "tip") if k in s})
    first = None
    for i in (-1, 0, 1):
        for j in (-1, 0, 1):
            if i == 0 and j == 0:
                continue
            rd = dian(rs)[0] if first is None else copy_tree(first)
            first = first or rd
            rd.location = (i * pitch, j * pitch, Lc * 0.3)   # noses stand just proud of the front face
            rd.rotation_euler = (0, 0, random.uniform(0, 6.28))
            rd.parent = root
    return root, Lc, side / 2


def ashura(s):
    """Tsunami Ashura style dart (after the game's Ashura round): base with six radial lugs and a cupped end,
    an open cage tail of six struts round a core, a forward body with ring grooves, a pointed nose with a
    sensor facet (Seekers) or a steel tip and hazard band (Dumbfires)."""
    R, L = s["R"], s["L"]
    dumb = s.get("dumbfire", False)
    root = bpy.data.objects.new("Round", None)
    bpy.context.collection.objects.link(root)
    body = ANOD()
    z0, z1 = 0.09 * L, 0.47 * L           # cage section
    base = [(0, 0.03 * L, body), (R * 0.4, 0.015 * L, body), (R * 0.55, 0, body), (R * 0.82, 0, body),
            (R * 0.85, 0.02 * L, body), (R * 0.85, z0, body), (R * 0.35, z0 + 0.005 * L, body),
            (R * 0.3, z0 + 0.01 * L, body), (R * 0.3, z1 - 0.01 * L, body), (R * 0.9, z1 - 0.005 * L, body),
            (R, z1, body)]
    zr = z1
    for k in range(4):     # ring grooves
        zr += 0.035 * L
        base += [(R, zr - 0.006 * L, body), (R * 0.95, zr - 0.003 * L, body), (R * 0.95, zr + 0.003 * L, body),
                 (R, zr + 0.006 * L, body)]
    zf = zr + 0.04 * L
    if dumb:
        hz = hazard("Hazard", R * 0.9)
        base += [(R, zf, hz), (R * 1.004, zf + 0.003, hz), (R * 1.004, zf + 0.07 * L, body), (R, zf + 0.071 * L, body)]
        zf += 0.08 * L
    elif s.get("idband"):
        idm = id_paint(s["idband"])
        base += [(R, zf, idm), (R * 1.004, zf + 0.003, idm), (R * 1.004, zf + 0.07 * L, body), (R, zf + 0.071 * L, body)]
        zf += 0.08 * L
    else:
        base += [(R, zf, body)]
    base += tip_profile_smart(R, zf, L - zf, False, STEEL() if dumb else nose_mat(s, body), tip=s.get("tip"))[1:]
    revolve("Body", base).parent = root
    # Cage struts and the base lugs.
    for k in range(6):
        a = k * math.pi / 3
        st = cube("Strut", (R * 0.16, R * 0.3, z1 - z0), (math.cos(a) * R * 0.72, math.sin(a) * R * 0.72, (z0 + z1) / 2),
                  body, R * 0.03, rot=(0, 0, a))
        st.parent = root
        lug = cube("Lug", (R * 0.32, R * 0.12, 0.06 * L), (math.cos(a + 0.5) * R * 0.95, math.sin(a + 0.5) * R * 0.95,
                   0.035 * L), body, R * 0.02, rot=(0, 0, a + 0.5))
        lug.parent = root
    if not dumb and not s.get("noseeker"):
        # Sensor facet: a dark glass window cut into one side of the nose near the tip.
        zt = L - (L - zf) * 0.28
        rn = R * (1 - 0.72 ** 1.8) ** 0.75
        w = cube("Facet", (rn * 1.1, rn * 0.12, (L - zf) * 0.2), (0, -rn * 0.92, zt), sensor_glass(s),
                 rn * 0.03, rot=(-0.12, 0, 0))
        w.parent = root
    for k in range(3):
        c = cube("Contact", (R * 0.18, R * 0.05, R * 0.24), (0, -R * 1.0, z1 + 0.012 * L + k * 0.035 * L), GOLD(), R * 0.02)
        c.parent = root
    return root, L, R


BUILD = {"pistol": pistol, "rifle": rifle, "shell": shell, "rail": rail, "dian": dian, "cassette": cassette,
         "ashura": ashura}


def make_round(spec):
    ob, length, rad = BUILD[spec["kind"]](spec)
    return ob, length, rad


def copy_tree(root):
    new = root.copy()
    if new.data:
        new.data = root.data
    bpy.context.collection.objects.link(new)
    for ch in root.children:
        c = copy_tree(ch)
        c.parent = new
        c.matrix_parent_inverse = ch.matrix_parent_inverse.copy()
    return new


# ---------------------------------------------------------------- box

def panel(name, w, h, mat, loc, rot, thick, inner=None, outward=None):
    """Card panel of thickness `thick`. With `inner`, the face pointing along `outward` gets `mat` (the
    print) and the other face and the cut edges get `inner` (bare card): boxes aren't printed inside."""
    bpy.ops.mesh.primitive_plane_add(size=1)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (w, h, 1)
    bpy.ops.object.transform_apply(scale=True)
    sol = ob.modifiers.new("t", "SOLIDIFY")
    sol.thickness = thick
    sol.offset = 0
    bev = ob.modifiers.new("b", "BEVEL")
    bev.width = thick * 0.4
    ob.location = loc
    ob.rotation_euler = rot
    if inner is None:
        ob.data.materials.append(mat)
        return ob
    # Solidify keeps the original faces (normal +Z, moved out by thick/2) and adds a flipped shell
    # with material_offset; rim faces get material_offset_rim.
    n = ob.rotation_euler.to_matrix() @ Vector((0, 0, 1))
    out_first = n.dot(Vector(outward)) > 0
    ob.data.materials.append(mat if out_first else inner)
    ob.data.materials.append(inner if out_first else mat)
    sol.material_offset = 1
    sol.material_offset_rim = 1 if out_first else 0
    return ob


def box(spec, roundspec):
    rnd, L, rad = make_round(roundspec)
    d, cols, rows, W, D, H = (spec[k] for k in ("d", "cols", "rows", "W", "D", "H"))
    t = max(W, D) * 0.012
    front = image_mat("Front", spec["front"], lacquer=spec.get("lacquer"))
    side = image_mat("Side", spec["side"], lacquer=spec.get("lacquer"))
    inner = image_mat("Kraft", None)
    root = bpy.data.objects.new("Box", None)
    bpy.context.collection.objects.link(root)
    parts = [
        panel("Front", W, H, front, (0, -D / 2, H / 2), (math.pi / 2, 0, 0), t, inner, (0, -1, 0)),
        panel("Back", W, H, side, (0, D / 2, H / 2), (math.pi / 2, 0, math.pi), t, inner, (0, 1, 0)),
        panel("Left", D, H, side, (-W / 2, 0, H / 2), (math.pi / 2, 0, -math.pi / 2), t, inner, (-1, 0, 0)),
        panel("Right", D, H, side, (W / 2, 0, H / 2), (math.pi / 2, 0, math.pi / 2), t, inner, (1, 0, 0)),
        panel("Bottom", W, D, inner, (0, 0, t / 2), (0, 0, 0), t),
    ]
    rng = random.Random(spec.get("seed", 1))
    fh = min(D, W) * 0.5
    # Flaps hinged on the top edges, folded outward and down at uneven angles (a = 0 is upright).
    for name, w, sign in (("FlapB", W, 1),):   # no front flap: it would hide the label
        a = math.radians(rng.uniform(105, 130))
        h = fh * (0.6 if sign < 0 else 1.0)
        ob = panel(name, w, h, side, (0, sign * D / 2 + sign * h / 2 * math.sin(a), H + h / 2 * math.cos(a)),
                   (math.pi / 2 - sign * a, 0, 0), t, inner, (0, 0, -1))
        parts.append(ob)
    for name, w, sign in (("FlapL", D, -1), ("FlapR", D, 1)):
        a = math.radians(rng.uniform(105, 130))
        ob = panel(name, fh, w, side, (sign * W / 2 + sign * fh / 2 * math.sin(a), 0, H + fh / 2 * math.cos(a)),
                   (0, a - math.pi / 2 if sign > 0 else -(math.pi / 2 + a), 0), t, inner, (0, 0, -1))
        parts.append(ob)
    for p in parts:
        p.parent = root
    # Fill: rows of rounds standing up, a little uneven.
    rounds = [rnd]
    for i in range(cols):
        for j in range(rows):
            c = rnd if (i, j) == (0, 0) else copy_tree(rnd)
            # Pulled in a little from the walls so tilted rounds don't poke through the card.
            c.location = (0.96 * (-W / 2 + d * (i + 0.5)) + rng.uniform(-0.03, 0.03) * d,
                          0.96 * (-D / 2 + d * (j + 0.5)) + rng.uniform(-0.03, 0.03) * d, t + rng.uniform(0, 0.03) * L)
            spin = rng.choice((0, 1, 2, 3)) * math.pi / 2 + rng.uniform(-0.04, 0.04) if roundspec["kind"] == "cassette" \
                else rng.uniform(0, 2 * math.pi)   # square cassettes sit square in the box
            c.rotation_euler = (rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03), spin)
            rounds.append(c)
    # Two loose rounds in front of the box, lying parallel to its front.
    loose = rnd
    for k in range(2):
        c = loose if (k == 0 and loose is not rnd) else copy_tree(loose)
        x = -L / 2 + W * (0.08 + 0.12 * k)
        if roundspec["kind"] == "shell":
            # Shells lie the other way, crimp toward the camera, so the brass head isn't the focus.
            c.rotation_euler = (0, math.radians(-90), math.radians(rng.uniform(-6, 6)))
            c.location = (x + L, -D / 2 - rad * (2.6 + 2.15 * k), rad)
        else:
            c.rotation_euler = (0, math.radians(90), math.radians(rng.uniform(-6, 6)))
            c.location = (x, -D / 2 - rad * (2.6 + 2.15 * k), rad)
        rounds.append(c)
    return [root] + rounds


# ---------------------------------------------------------------- scene

def look_at(ob, target):
    v = Vector(target) - ob.location
    ob.rotation_euler = v.to_track_quat("-Z", "Y").to_euler()


def bounds(objs):
    bpy.context.view_layer.update()
    pts = []
    for o in bpy.data.objects:
        if o.type in ("MESH",):
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def area(name, loc, size, power, target, color=(1, 1, 1), strip=None, along=None):
    """Area light aimed at target. A strip (size x strip) is rolled about its aim so its long side
    lies as near as it can to `along`: a strip parallel to a cylinder reflects as a streak down it."""
    d = bpy.data.lights.new(name, "AREA")
    d.size, d.energy, d.color = size, power, color
    if strip:
        d.shape, d.size_y = "RECTANGLE", strip
    ob = bpy.data.objects.new(name, d)
    ob.location = loc
    bpy.context.collection.objects.link(ob)
    q = (Vector(target) - ob.location).to_track_quat("-Z", "Y")
    if strip and along is not None:
        rolls = [math.radians(a) for a in range(0, 180, 3)]
        best = max(rolls, key=lambda r: abs((q @ Quaternion((0, 0, 1), r) @ Vector((0, 1, 0))).dot(Vector(along))))
        q = q @ Quaternion((0, 0, 1), best)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = q


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    if SPEC["mode"] == "round":
        root, L, rad = make_round(SPEC["round"])
        # Lying down, tip to the left, turned a little toward the camera.
        root.rotation_euler = (0, -math.pi / 2, math.radians(SPEC.get("turn", 20)))
        root.location = (0, 0, 0)
        view = Vector((-0.35, -1.0, 0.45))
        tr = math.radians(SPEC.get("turn", 20))
        axis = (math.cos(tr), math.sin(tr), 0)
    else:
        objs = box(SPEC["box"], SPEC["round"])
        objs[0].parent = None
        view = Vector((-0.5, -1.0, 0.55))
        axis = (0, 0, 1)
    lo, hi = bounds(None)
    centre = (lo + hi) / 2
    radius = (hi - lo).length / 2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    cam.data.lens = 85
    fov = cam.data.angle
    cam.location = centre + view.normalized() * radius / math.sin(fov / 2) * 1.02
    look_at(cam, centre)
    scene.camera = cam
    s = radius
    # Product-shot lighting for metal: two long narrow strip lights give crisp streaks down the
    # cartridges; the rest of the surroundings stay dark, so the metal reflects dark there and reads
    # as metal. A large dim fill keeps the shadows open.
    area("Key", centre + Vector((-1.2, -1.0, 1.4)) * s * 3, s * 1.2, 0.5 * 450 * s * s, centre, strip=s * 9, along=axis)
    # Legendary: a stronger coloured rim (SPEC rim = [r, g, b, power factor]).
    rim = SPEC.get("rim", [1, 1, 1, 1])
    area("Rim", centre + Vector((1.3, 1.4, 0.9)) * s * 3, s * 0.9, 0.45 * 450 * s * s * rim[3], centre, tuple(rim[:3]),
         strip=s * 8, along=axis)
    area("Fill", centre + Vector((1.6, -1.4, 0.4)) * s * 3, s * 14, 0.2 * 130 * s * s, centre, (0.85, 0.9, 1.0))
    # Floor that only catches shadows, so things sit on something.
    bpy.ops.mesh.primitive_plane_add(size=radius * 40, location=(centre.x, centre.y, lo.z))
    bpy.context.active_object.is_shadow_catcher = True
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    wn = world.node_tree
    env = wn.nodes.new("ShaderNodeTexEnvironment")
    env.image = bpy.data.images.load(os.path.join(ASSETS, "photo_studio_01.hdr"))
    wmp = wn.nodes.new("ShaderNodeMapping")
    wmp.inputs["Rotation"].default_value = (0, 0, math.radians(SPEC.get("hdri_turn", 60)))
    wn.links.new(wn.nodes.new("ShaderNodeTexCoord").outputs["Generated"], wmp.inputs["Vector"])
    wn.links.new(wmp.outputs["Vector"], env.inputs["Vector"])
    # Reflections don't see the HDRI (its round lamps turn into blobs on cylinders); they see a smooth
    # studio sweep, dark below and dim grey above, so the strip lights are the only bright reflections.
    lp = wn.nodes.new("ShaderNodeLightPath")
    sep = wn.nodes.new("ShaderNodeSeparateXYZ")
    wn.links.new(wn.nodes.new("ShaderNodeTexCoord").outputs["Generated"], sep.inputs[0])
    sweep = wn.nodes.new("ShaderNodeValToRGB")
    sweep.color_ramp.elements[0].position, sweep.color_ramp.elements[0].color = 0.45, (0.004, 0.004, 0.005, 1)
    sweep.color_ramp.elements[1].position, sweep.color_ramp.elements[1].color = 0.85, (0.11, 0.11, 0.12, 1)
    wn.links.new(sep.outputs["Z"], sweep.inputs["Fac"])
    sel = wn.nodes.new("ShaderNodeMix")
    sel.data_type = "RGBA"
    wn.links.new(lp.outputs["Is Glossy Ray"], sel.inputs[0])
    wn.links.new(env.outputs["Color"], sel.inputs[6])
    wn.links.new(sweep.outputs["Color"], sel.inputs[7])
    wn.links.new(sel.outputs[2], wn.nodes["Background"].inputs["Color"])
    wn.nodes["Background"].inputs["Strength"].default_value = 0.35
    scene.world = world
    scene.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "OPTIX"
    prefs.get_devices()
    for dv in prefs.devices:
        dv.use = dv.type == "OPTIX"
    scene.cycles.device = "GPU"
    scene.cycles.samples = SPEC.get("samples", 256)
    scene.cycles.use_denoising = True
    scene.cycles.sample_clamp_indirect = 4.0   # no fireflies from caustic paths off the metals
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = SPEC.get("size", 1024)
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.exposure = 0.0
    try:
        scene.view_settings.look = "AgX - Punchy"
    except TypeError:
        pass
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = SPEC["out"]
    bpy.ops.render.render(write_still=True)
    contact_shadows_only(SPEC["out"])


def contact_shadows_only(path):
    """The shadow catcher leaves a faint haze over the whole floor; an icon wants only the dark contact
    shadows. Pixels that are shadow alone (alpha < 1, no object) lose their faintest 25% of alpha."""
    import numpy as np
    img = bpy.data.images.load(path)
    px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
    a = px[:, 3]
    shadow = a < 0.999
    a[shadow] = np.clip((a[shadow] - 0.25) / 0.75, 0, 1) ** 1.2 * 0.85
    px[:, 3] = a
    img.pixels[:] = px.ravel()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()


main()
