#!/usr/bin/env python3

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


WIDTH = 1400
HEIGHT = 1120
CENTER = (WIDTH // 2, HEIGHT // 2)
RNG = random.Random(42)


def clamp(value: float) -> int:
    return max(0, min(255, int(value)))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def organic_shell_points(cx: float, cy: float, width: float, height: float) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    a = width / 2.0
    b = height / 2.0
    for step in range(160):
        theta = math.tau * step / 160.0
        distortion = 1.0 - 0.08 * math.sin(theta * 2.0) ** 2 + 0.03 * math.cos(theta * 5.0)
        vertical_bias = 1.0 + 0.10 * math.cos(theta)
        x = cx + math.cos(theta) * a * distortion
        y = cy + math.sin(theta) * b * vertical_bias
        points.append((x, y))
    return points


def polygon_mask(size: tuple[int, int], points: list[tuple[float, float]]) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon(points, fill=255)
    return mask


def gradient_fill(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", size)
    pixels = image.load()
    width, height = size
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(clamp(lerp(top[i], bottom[i], t)) for i in range(3))
        for x in range(width):
            pixels[x, y] = color + (255,)
    return image


def add_soft_glow(base: Image.Image, ellipse: tuple[int, int, int, int], color: tuple[int, int, int, int], blur: int) -> Image.Image:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse(ellipse, fill=color)
    return Image.alpha_composite(base, layer.filter(ImageFilter.GaussianBlur(blur)))


def draw_scute(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int], width: int = 4) -> None:
    draw.polygon(points, fill=fill, outline=outline)
    for index in range(len(points)):
        a = points[index]
        b = points[(index + 1) % len(points)]
        draw.line((a, b), fill=outline, width=width)


def erode_shell_mask(mask: Image.Image, shell_points: list[tuple[float, float]]) -> Image.Image:
    damage = Image.new("L", mask.size, 0)
    damage_draw = ImageDraw.Draw(damage)

    point_count = len(shell_points)
    for _ in range(64):
        point = shell_points[RNG.randrange(point_count)]
        radius = RNG.randint(10, 30)
        offset_x = RNG.randint(-18, 18)
        offset_y = RNG.randint(-18, 18)
        damage_draw.ellipse(
            (
                point[0] - radius + offset_x,
                point[1] - radius + offset_y,
                point[0] + radius + offset_x,
                point[1] + radius + offset_y,
            ),
            fill=255,
        )

    softened = damage.filter(ImageFilter.GaussianBlur(1.6))
    return ImageChops.subtract(mask, softened)


def add_shell_speckles(base: Image.Image, mask: Image.Image) -> Image.Image:
    speckles = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(speckles)

    for _ in range(380):
        x = RNG.randint(220, 1180)
        y = RNG.randint(180, 980)
        radius = RNG.randint(2, 9)
        warm = 110 + RNG.randint(-16, 26)
        alpha = RNG.randint(12, 34)
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            fill=(warm, int(warm * 0.82), int(warm * 0.58), alpha),
        )

    speckles.putalpha(ImageChops.multiply(speckles.getchannel("A"), mask))
    return Image.alpha_composite(base, speckles.filter(ImageFilter.GaussianBlur(0.4)))


def render_shell(output_path: Path) -> None:
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))

    shell_points = organic_shell_points(CENTER[0], CENTER[1] + 8, 920, 780)
    shell_mask = polygon_mask((WIDTH, HEIGHT), shell_points)
    shell_mask = erode_shell_mask(shell_mask, shell_points)

    shell_gradient = gradient_fill((WIDTH, HEIGHT), (113, 80, 48), (28, 17, 8))
    shell_base = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shell_base.paste(shell_gradient, mask=shell_mask)

    shell_base = add_soft_glow(shell_base, (150, 100, 1260, 1040), (0, 0, 0, 152), 56)
    shell_base = add_soft_glow(shell_base, (290, 180, 1020, 680), (255, 224, 188, 34), 84)
    shell_base = add_soft_glow(shell_base, (300, 520, 1080, 1120), (10, 6, 4, 134), 96)
    shell_base = add_shell_speckles(shell_base, shell_mask)

    detail = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(detail)

    outline = [(int(x), int(y)) for x, y in shell_points]
    draw.line(outline + [outline[0]], fill=(162, 126, 84, 238), width=12, joint="curve")
    draw.line(outline + [outline[0]], fill=(36, 22, 10, 255), width=4, joint="curve")

    scute_fill = (89, 62, 33, 226)
    scute_outline = (156, 122, 81, 232)
    dark_outline = (44, 28, 13, 226)

    central = [(700, 290), (860, 382), (826, 582), (700, 666), (574, 582), (540, 382)]
    top_left = [(534, 206), (680, 280), (614, 392), (466, 342), (434, 252)]
    top_right = [(866, 206), (966, 252), (934, 342), (786, 392), (720, 280)]
    mid_left = [(404, 396), (526, 438), (548, 596), (430, 650), (332, 548), (334, 446)]
    mid_right = [(874, 438), (996, 396), (1066, 446), (1068, 548), (970, 650), (852, 596)]
    low_left = [(472, 664), (620, 628), (666, 806), (560, 910), (418, 846), (386, 742)]
    low_right = [(734, 628), (882, 664), (968, 742), (936, 846), (794, 910), (688, 806)]

    for points in [central, top_left, top_right, mid_left, mid_right, low_left, low_right]:
        draw_scute(draw, points, scute_fill, scute_outline)
        draw.polygon(points, outline=dark_outline)

    for points in [central, top_left, top_right, mid_left, mid_right, low_left, low_right]:
        cx = sum(point[0] for point in points) / len(points)
        cy = sum(point[1] for point in points) / len(points)
        draw.ellipse((cx - 28, cy - 20, cx + 28, cy + 20), fill=(255, 230, 182, 30))
        draw.ellipse((cx - 14, cy - 9, cx + 14, cy + 9), fill=(255, 244, 220, 20))

    fissures = [
        [(708, 276), (680, 358), (682, 420)],
        [(520, 286), (480, 356), (470, 428)],
        [(886, 288), (930, 350), (944, 430)],
        [(636, 710), (620, 790), (590, 848)],
        [(764, 708), (782, 788), (816, 856)],
        [(420, 524), (382, 566), (366, 628)],
        [(982, 514), (1022, 564), (1040, 626)],
    ]
    for points in fissures:
        draw.line(points, fill=(18, 10, 5, 110), width=4, joint="curve")
        draw.line(points, fill=(180, 136, 82, 36), width=1, joint="curve")

    detail_shadow = detail.filter(ImageFilter.GaussianBlur(10))
    canvas = Image.alpha_composite(canvas, detail_shadow)
    canvas = Image.alpha_composite(canvas, shell_base)
    canvas = Image.alpha_composite(canvas, detail)

    engraving = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    engraving_draw = ImageDraw.Draw(engraving)
    strokes = [
        [(700, 252), (690, 340), (708, 420)],
        [(548, 250), (490, 340), (476, 456)],
        [(852, 250), (918, 340), (938, 460)],
        [(620, 694), (602, 776), (560, 850)],
        [(782, 694), (804, 776), (846, 850)],
        [(430, 516), (376, 554), (350, 620)],
        [(970, 516), (1026, 554), (1052, 620)],
    ]
    for points in strokes:
        engraving_draw.line(points, fill=(205, 166, 118, 52), width=6, joint="curve")
        engraving_draw.line(points, fill=(25, 16, 9, 78), width=2, joint="curve")
    canvas = Image.alpha_composite(canvas, engraving.filter(ImageFilter.GaussianBlur(0.5)))

    highlights = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    highlights_draw = ImageDraw.Draw(highlights)
    highlights_draw.ellipse((355, 172, 990, 482), fill=(255, 245, 223, 46))
    highlights_draw.ellipse((492, 270, 892, 500), fill=(255, 232, 188, 30))
    highlights_draw.ellipse((330, 560, 560, 900), fill=(255, 216, 160, 16))
    highlights = highlights.filter(ImageFilter.GaussianBlur(42))
    highlights.putalpha(ImageChops.multiply(highlights.getchannel("A"), shell_mask))
    canvas = Image.alpha_composite(canvas, highlights)

    soot = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    soot_draw = ImageDraw.Draw(soot)
    for _ in range(32):
        x = RNG.randint(280, 1080)
        y = RNG.randint(220, 920)
        rx = RNG.randint(24, 70)
        ry = RNG.randint(14, 42)
        alpha = RNG.randint(8, 20)
        soot_draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(28, 18, 10, alpha))
    soot = soot.filter(ImageFilter.GaussianBlur(20))
    soot.putalpha(ImageChops.multiply(soot.getchannel("A"), shell_mask))
    canvas = Image.alpha_composite(canvas, soot)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path)


if __name__ == "__main__":
    render_shell(
        Path(
            "/Users/owen/Documents/workspace/lifescript/LifeScript-Solo/Sources/LifeScriptSolo/Resources/Assets.xcassets/tianjilu_oracle_shell_closed.imageset/tianjilu_oracle_shell_closed.png"
        )
    )
