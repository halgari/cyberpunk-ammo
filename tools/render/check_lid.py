"""Checks the Legendary case's lid art isn't stretched in a render: the liner's corners (AO_LID_DUMP
from scene.py) straighten the lid back to its true shape, and the crest's ring has to come out as
wide as it's tall. Perspective is taken out by the straightening.

  AO_LID_DUMP=/tmp/lid.json python3 tools/render/render.py --only <name> --samples 64 --out /tmp/x
  python3 tools/render/check_lid.py /tmp/x/<name>.png /tmp/lid.json W D
"""
import json
import sys

from PIL import Image


def solve(m, b):
    """Gaussian elimination."""
    n = len(m)
    m = [row[:] + [v] for row, v in zip(m, b)]
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(m[r][i]))
        m[i], m[p] = m[p], m[i]
        for r in range(n):
            if r != i:
                f = m[r][i] / m[i][i]
                m[r] = [x - f * y for x, y in zip(m[r], m[i])]
    return [m[i][n] / m[i][i] for i in range(n)]


def coefficients(dst, src):
    """PIL perspective coefficients sending each dst point to its src point."""
    rows, rhs = [], []
    for (x, y), (u, v) in zip(dst, src):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); rhs.append(u)
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y]); rhs.append(v)
    return solve(rows, rhs)


def main():
    path, dump, W, D = sys.argv[1], json.load(open(sys.argv[2])), float(sys.argv[3]), float(sys.argv[4])
    im = Image.open(path).convert("RGB")
    h = 700
    w = round(h * W / D)
    # Plane vertices by their local sign; the art's top is the side that sits higher in the render.
    pts = {(c[0] > 0, c[1] > 0): p for c, p in zip(dump["uv"], dump["image"])}
    side = [pts[(False, True)], pts[(True, True)], pts[(True, False)], pts[(False, False)]]
    if side[0][1] > side[3][1]:
        side = [side[3], side[2], side[1], side[0]]
    src = [(x * im.width, y * im.height) for x, y in side]
    flat = im.transform((w, h), Image.PERSPECTIVE, coefficients([(0, 0), (w, 0), (w, h), (0, h)], src), Image.BICUBIC)
    flat.save(path.replace(".png", "-lid-flat.png"))
    px = flat.load()
    def gold(x, y):
        r, g, b = px[x, y]
        return r > 90 and g > r * 0.45 and b < r * 0.72
    # The ring is one connected shape: flood it from its top, in the middle of the lid (clear of the
    # keyline and of the caliber in the corner).
    start = next((x, y) for y in range(int(h * 0.06), h) for x in range(int(w * 0.45), int(w * 0.55)) if gold(x, y))
    seen, stack = {start}, [start]
    while stack:
        x, y = stack.pop()
        for nx in (x - 1, x, x + 1):
            for ny in (y - 1, y, y + 1):
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and gold(nx, ny):
                    seen.add((nx, ny))
                    stack.append((nx, ny))
    bw = max(x for x, _ in seen) - min(x for x, _ in seen) + 1
    bh = max(y for _, y in seen) - min(y for _, y in seen) + 1
    print(f"{path.split('/')[-1]}: crest {bw} x {bh} px, ratio {bw / bh:.3f}")


if __name__ == "__main__":
    main()
