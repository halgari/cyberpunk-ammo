"""The mod's title, BRASSMARKET, as extruded metal letters on a transparent ground, for banner.py:

  blender -b -P tools/render/title.py -- OUT.png [--size 7680x4320] [--samples 128] [--cpu] [--brass BRA€$]

BRASS is polished brass, MARKET dark gunmetal, over a thin cyan neon bar. The font is Orbitron Black
(OFL, google/fonts), a static 900 instance of the variable font in ~/.cache/ammo-overhaul/fonts
(fontTools: python -m fontTools.varLib.instancer Orbitron[wght].ttf wght=900). The lighting and
studio HDRI are the ones the round art uses (scene.py), so the letters match the boxes.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:]
OUT = os.path.abspath(ARGS[0])
SIZE = tuple(int(v) for v in (ARGS[ARGS.index("--size") + 1] if "--size" in ARGS else "7680x4320").split("x"))
SAMPLES = int(ARGS[ARGS.index("--samples") + 1]) if "--samples" in ARGS else 128
CPU = "--cpu" in ARGS
# The brass half of the title. BRA€$ (the eddie sign) was tried: in this font the € reads as an E.
BRASS = ARGS[ARGS.index("--brass") + 1] if "--brass" in ARGS else "BRASS"
FONT = os.path.expanduser("~/.cache/ammo-overhaul/fonts/Orbitron-Black.ttf")
ASSETS = os.path.expanduser("~/.cache/ammo-overhaul/assets")
# Width of the title as a share of the frame.
SPAN = 0.78


def metal(name, color, rough):
    m = bpy.data.materials.new(name)
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Metallic"].default_value = 1.0
    p.inputs["Roughness"].default_value = rough
    return m


def neon(name, color, strength):
    m = bpy.data.materials.new(name)
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Emission Color"].default_value = (*color, 1)
    p.inputs["Emission Strength"].default_value = strength
    return m


def word(text, mat, font):
    cu = bpy.data.curves.new(text, "FONT")
    cu.body, cu.font = text, font
    cu.extrude, cu.bevel_depth, cu.bevel_resolution = 0.07, 0.018, 4
    ob = bpy.data.objects.new(text, cu)
    ob.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def width(ob):
    bpy.context.view_layer.update()
    xs = [(ob.matrix_world @ Vector(c)).x for c in ob.bound_box]
    return min(xs), max(xs)


def area(name, loc, size, power, target, color=(1, 1, 1), strip=None):
    ld = bpy.data.lights.new(name, "AREA")
    ld.energy, ld.color = power, color
    if strip:
        ld.shape, ld.size, ld.size_y = "RECTANGLE", strip, size
    else:
        ld.size = size
    ob = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y")


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    font = bpy.data.fonts.load(FONT)
    brass = word(BRASS, metal("Brass", (0.85, 0.52, 0.18), 0.2), font)
    market = word("MARKET", metal("Gunmetal", (0.10, 0.11, 0.12), 0.3), font)
    # Lay the two words end to end, then centre the pair on the origin.
    lo, hi = width(brass)
    m_lo, _ = width(market)
    market.location.x = hi - m_lo + 0.06
    lo, _ = width(brass)
    _, hi = width(market)
    for ob in (brass, market):
        ob.location.x -= (lo + hi) / 2
        ob.location.y -= 0.36    # Orbitron's caps are ~0.72 high from the baseline
    total = hi - lo
    # The cyan bar under the title, inset a little from its ends.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.5, 0.02))
    bar = bpy.context.active_object
    bar.scale = (total * 0.96, 0.035, 0.03)
    bar.data.materials.append(neon("Neon", (0.0, 0.62, 1.0), 2.5))
    # Letters stand on the XY plane facing -Z by default; stand them up facing the camera on -Y.
    root = bpy.data.objects.new("Title", None)
    scene.collection.objects.link(root)
    for ob in (brass, market, bar):
        ob.parent = root
    root.rotation_euler = (math.radians(90), 0, 0)
    # Orthographic camera, a little below and in front, so the top bevels catch the key light.
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = total / SPAN
    cam.location = (0, -20, -1.2)
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = (Vector((0, 0, 0)) - cam.location).to_track_quat("-Z", "Y")
    scene.camera = cam
    s = total / 2
    area("Key", (-s * 0.6, -s * 1.2, s * 1.4), s * 0.5, 900 * s, (0, 0, 0), strip=s * 5)
    area("Rim", (s * 0.8, s * 0.6, s * 1.0), s * 0.4, 700 * s, (0, 0, 0), strip=s * 4)
    area("Fill", (s * 1.2, -s * 1.6, -s * 0.2), s * 4, 60 * s, (0, 0, 0), (0.85, 0.9, 1.0))
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    wn = world.node_tree
    env = wn.nodes.new("ShaderNodeTexEnvironment")
    env.image = bpy.data.images.load(os.path.join(ASSETS, "photo_studio_01.hdr"))
    wn.links.new(env.outputs["Color"], wn.nodes["Background"].inputs["Color"])
    wn.nodes["Background"].inputs["Strength"].default_value = 0.12
    scene.world = world
    scene.render.engine = "CYCLES"
    if not CPU:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        for dv in prefs.devices:
            dv.use = dv.type == "OPTIX"
        scene.cycles.device = "GPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.cycles.sample_clamp_indirect = 4.0
    scene.render.film_transparent = True
    scene.render.resolution_x, scene.render.resolution_y = SIZE
    scene.view_settings.view_transform = "AgX"
    try:
        scene.view_settings.look = "AgX - Punchy"
    except TypeError:
        pass
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)


main()
