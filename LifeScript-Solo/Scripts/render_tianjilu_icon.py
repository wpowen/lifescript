#!/usr/bin/env python3

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


SIZE = 1024
CENTER = SIZE // 2


def clamp(value: float) -> int:
    return max(0, min(255, int(value)))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def gradient_background() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    pixels = image.load()

    top_left = (7, 19, 29)
    top_right = (11, 54, 52)
    bottom_left = (12, 18, 16)
    bottom_right = (16, 74, 60)

    for y in range(SIZE):
        ty = y / (SIZE - 1)
        for x in range(SIZE):
            tx = x / (SIZE - 1)
            top = tuple(lerp(top_left[i], top_right[i], tx) for i in range(3))
            bottom = tuple(lerp(bottom_left[i], bottom_right[i], tx) for i in range(3))
            color = tuple(clamp(lerp(top[i], bottom[i], ty)) for i in range(3))
            pixels[x, y] = color + (255,)

    return image


def add_glow(base: Image.Image, bbox: tuple[int, int, int, int], color: tuple[int, int, int, int], blur: int) -> Image.Image:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse(bbox, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(base, layer)


def draw_line(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, int, int, int], width: int) -> None:
    draw.line(points, fill=fill, width=width, joint="curve")


def render_icon(output_path: Path) -> None:
    image = gradient_background()
    image = add_glow(image, (-140, -180, 560, 440), (255, 193, 94, 54), 90)
    image = add_glow(image, (480, -60, 1150, 580), (49, 197, 177, 62), 110)
    image = add_glow(image, (180, 560, 860, 1180), (0, 0, 0, 120), 120)

    vignette = Image.new("L", (SIZE, SIZE), 0)
    vignette_draw = ImageDraw.Draw(vignette)
    vignette_draw.ellipse((-80, -40, 1100, 1140), fill=255)
    vignette = ImageChops.invert(vignette.filter(ImageFilter.GaussianBlur(110)))
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow.putalpha(vignette)
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 66)).copy()
    shadow.putalpha(vignette)
    image = Image.alpha_composite(image, shadow)

    emblem_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(emblem_shadow)
    shadow_draw.ellipse((252, 252, 772, 772), fill=(0, 0, 0, 110))
    shadow_draw.ellipse((306, 306, 718, 718), fill=(0, 0, 0, 120))
    emblem_shadow = emblem_shadow.filter(ImageFilter.GaussianBlur(26))
    image = Image.alpha_composite(image, emblem_shadow)

    plaque = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    plaque_draw = ImageDraw.Draw(plaque)
    plaque_draw.ellipse((246, 228, 778, 760), fill=(8, 30, 36, 205), outline=(255, 255, 255, 16), width=2)
    plaque_draw.ellipse((284, 266, 740, 722), outline=(255, 211, 134, 28), width=2)
    gloss = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gloss_draw = ImageDraw.Draw(gloss)
    gloss_draw.ellipse((262, 214, 742, 480), fill=(255, 255, 255, 34))
    gloss = gloss.filter(ImageFilter.GaussianBlur(36))
    plaque = Image.alpha_composite(plaque, gloss)
    image = Image.alpha_composite(image, plaque)

    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    halo_draw.ellipse((296, 278, 728, 710), outline=(255, 196, 97, 186), width=12)
    halo_draw.ellipse((338, 320, 686, 668), outline=(58, 192, 180, 120), width=8)
    halo = halo.filter(ImageFilter.GaussianBlur(0.4))
    image = Image.alpha_composite(image, halo)

    emblem_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(emblem_shadow)
    gold_shadow = (0, 0, 0, 110)
    jade_shadow = (0, 0, 0, 88)
    draw_line(shadow_draw, [(CENTER + 8, 294 + 18), (346 + 8, 678 + 18), (678 + 8, 678 + 18), (CENTER + 8, 294 + 18)], gold_shadow, 26)
    draw_line(shadow_draw, [(CENTER + 8, 390 + 14), (CENTER + 8, 618 + 14)], gold_shadow, 18)
    emblem_shadow = emblem_shadow.filter(ImageFilter.GaussianBlur(18))
    image = Image.alpha_composite(image, emblem_shadow)

    emblem = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(emblem)

    gold = (204, 165, 92, 255)
    jade = (55, 162, 155, 255)
    jade_bright = (116, 224, 211, 255)
    ivory = (245, 236, 214, 255)

    draw.polygon(
        [(CENTER, 330), (388, 650), (636, 650)],
        fill=(15, 55, 61, 214),
        outline=None,
    )
    draw_line(draw, [(CENTER, 294), (346, 678), (678, 678), (CENTER, 294)], gold, 24)
    draw_line(draw, [(CENTER, 390), (CENTER, 618)], gold, 16)
    draw_line(draw, [(CENTER, 338), (405, 640)], (103, 235, 220, 66), 5)

    eye_glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    eye_glow_draw = ImageDraw.Draw(eye_glow)
    eye_glow_draw.ellipse((432, 394, 592, 606), fill=(96, 246, 232, 54))
    eye_glow = eye_glow.filter(ImageFilter.GaussianBlur(18))
    emblem = Image.alpha_composite(emblem, eye_glow)
    draw = ImageDraw.Draw(emblem)

    draw.ellipse((458, 420, 566, 580), outline=jade_bright, width=18)
    draw.ellipse((481, 446, 543, 554), fill=(17, 75, 77, 255))
    draw.rounded_rectangle((503, 410, 521, 590), radius=9, fill=gold)
    draw.rounded_rectangle((507, 424, 513, 576), radius=3, fill=ivory)

    for x, y, r, alpha in [
        (260, 214, 7, 180),
        (724, 238, 6, 164),
        (774, 370, 8, 150),
        (250, 742, 6, 110),
        (714, 790, 7, 130),
    ]:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(255, 235, 203, alpha))

    emblem = emblem.filter(ImageFilter.GaussianBlur(0.1))
    image = Image.alpha_composite(image, emblem)

    crisp = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    crisp_draw = ImageDraw.Draw(crisp)
    crisp_draw.ellipse((458, 420, 566, 580), outline=(187, 255, 244, 220), width=4)
    crisp_draw.line((CENTER, 302, CENTER, 370), fill=(255, 234, 184, 196), width=6)
    image = Image.alpha_composite(image, crisp)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


if __name__ == "__main__":
    render_icon(
        Path(
            "/Users/owen/Documents/workspace/lifescript/LifeScript-Solo/Sources/LifeScriptSolo/Resources/Assets.xcassets/AppIconTianjilu.appiconset/AppIconTianjilu.png"
        )
    )
