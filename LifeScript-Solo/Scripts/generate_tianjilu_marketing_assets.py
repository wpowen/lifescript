from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path("/Users/owen/Documents/workspace/lifescript/LifeScript-Solo")
PIC_DIR = ROOT / "pic"
ASSETS_DIR = ROOT / "Sources/LifeScriptSolo/Resources/Assets.xcassets"
OUT_DIR = PIC_DIR / "designed_assets"

FONT_SERIF = "/System/Library/Fonts/Supplemental/Songti.ttc"
FONT_SANS = "/System/Library/Fonts/Hiragino Sans GB.ttc"


def rgba(color: tuple[int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return color + (alpha,)


INK = (7, 15, 20)
DEEP_TEAL = (8, 44, 49)
JADE = (66, 184, 171)
GOLD = (233, 194, 112)
IVORY = (245, 240, 229)
MIST = (184, 220, 212)
PLUM = (71, 39, 83)


@dataclass(frozen=True)
class StoreShot:
    filename: str
    eyebrow: str
    title: str
    subtitle: str
    proof_points: tuple[str, ...]
    detail_copy: str
    screenshot: str
    accent: tuple[int, int, int]
    glow: tuple[int, int, int]
    background_art: str
    side_art: str | None = None
    support_screenshots: tuple[str, ...] = ()
    screenshot_align: str = "left"


STORE_SHOTS: tuple[StoreShot, ...] = (
    StoreShot(
        filename="01_volume_free.png",
        eyebrow="沉浸入局",
        title="不是看别人修仙\n是你亲自入局",
        subtitle="这是一部互动式小说。从开场开始，你的选择就会推动人物、局势和命途一起变化。",
        proof_points=("互动式小说", "1200 章节长线内容", "5 个结局分支"),
        detail_copy="你不是站在外面看一卷故事，而是直接走进局里。1200 章节会把你的选择一路放大，最后走向不同结局。",
        screenshot="IMG_5763.PNG",
        accent=GOLD,
        glow=JADE,
        background_art="tianjilu_tianqing_sect_overview.imageset/tianjilu_tianqing_sect_overview.png",
        side_art="cover_tianjilu.imageset/cover_tianjilu.png",
        support_screenshots=("IMG_5768.PNG",),
        screenshot_align="left",
    ),
    StoreShot(
        filename="02_immersive_reading.png",
        eyebrow="互动剧情",
        title="一句话的分寸\n会改掉后面走向",
        subtitle="试探、摊牌、压住不说，人物当场就会换态度，剧情也会顺着拐弯。",
        proof_points=("对话不是过场", "人物会实时反应", "互动结果继续生效"),
        detail_copy="互动式小说最重要的不是选项数量，而是选择有没有后果。这里你的回应会立刻改变关系温度和后面的推进方向。",
        screenshot="IMG_5764.PNG",
        accent=JADE,
        glow=GOLD,
        background_art="tianjilu_outer_sect_arena.imageset/tianjilu_outer_sect_arena.png",
        side_art="tianjilu_key_arena_humiliation.imageset/tianjilu_key_arena_humiliation.png",
        support_screenshots=("IMG_5771.PNG",),
        screenshot_align="left",
    ),
    StoreShot(
        filename="03_character_dossier.png",
        eyebrow="人物关系",
        title="人物不是卡面\n他们会一直记得你",
        subtitle="谁信你，谁防你，谁被你打动，都会沉淀成后面的剧情关系。",
        proof_points=("不止一条好感线", "态度变化可追踪", "后续见面会承接"),
        detail_copy="这里的人物不是收集页里的静态资料。你帮过谁、得罪过谁、让谁开始动摇，都会在下一次见面时直接带出来。",
        screenshot="IMG_5765.PNG",
        accent=(164, 213, 208),
        glow=(126, 84, 156),
        background_art="tianjilu_inner_sect_jade_hall.imageset/tianjilu_inner_sect_jade_hall.png",
        side_art="tianjilu_su_qingyao_portrait.imageset/tianjilu_su_qingyao_portrait.png",
        support_screenshots=("IMG_5769.PNG",),
        screenshot_align="right",
    ),
    StoreShot(
        filename="04_route_map.png",
        eyebrow="命途分支",
        title="主线看得见\n暗线要自己打出来",
        subtitle="明线推进清楚，暗线和隐藏节点要靠你的判断一步步撬开。",
        proof_points=("主线节点清楚", "暗线会逐步浮出", "关键命途可回看"),
        detail_copy="你能清楚知道主线走到哪一步，也能看见哪些暗线正在浮出水面。真正高价值的变化，不会自动送到你面前。",
        screenshot="IMG_5767.PNG",
        accent=(117, 181, 229),
        glow=JADE,
        background_art="tianjilu_artifact_dragon_vein_map.imageset/tianjilu_artifact_dragon_vein_map.png",
        side_art="tianjilu_key_shadow_mastermind.imageset/tianjilu_key_shadow_mastermind.png",
        support_screenshots=("IMG_5770.PNG",),
        screenshot_align="left",
    ),
    StoreShot(
        filename="05_relation_atlas.png",
        eyebrow="长线体验",
        title="不怕内容长\n你的推进一直看得见",
        subtitle="1200 章节不是堆长度。章节、命局和探索状态都会持续记录，长线阅读也不会丢线。",
        proof_points=("1200 章节可追更", "阶段状态可追踪", "探索进度会累计"),
        detail_copy="长篇内容最怕读着读着断线，这里会把你的章节推进、阶段状态和探索记录持续留住，方便你随时接上继续读。",
        screenshot="IMG_5768.PNG",
        accent=(214, 196, 142),
        glow=(74, 133, 131),
        background_art="tianjilu_three_sect_battle.imageset/tianjilu_three_sect_battle.png",
        side_art="tianjilu_chen_nian_portrait.imageset/tianjilu_chen_nian_portrait.png",
        support_screenshots=("IMG_5766.PNG",),
        screenshot_align="right",
    ),
    StoreShot(
        filename="06_choice_feedback.png",
        eyebrow="即时反馈",
        title="不是选完就过去\n后果当场看得见",
        subtitle="关系、属性和后续章节会立刻变化，你能清楚看到这一步改了什么。",
        proof_points=("选完马上提示", "关系属性会变", "5 个结局会被推向不同方向"),
        detail_copy="很多互动产品把后果埋到最后才揭晓，这里不是。你刚做完决定，关系、状态和结局方向就会开始改变。",
        screenshot="IMG_5771.PNG",
        accent=(194, 158, 230),
        glow=(83, 198, 182),
        background_art="tianjilu_home_hero_master.imageset/tianjilu_home_hero_master.png",
        side_art="tianjilu_key_ye_qing_rescue.imageset/tianjilu_key_ye_qing_rescue.png",
        support_screenshots=("IMG_5764.PNG",),
        screenshot_align="left",
    ),
)


def font(path: str, size: int, *, index: int = 0) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size, index=index)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            pixels[x, y] = color + (255,)
    return image


def add_glow(base: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    bbox = (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius)
    draw.ellipse(bbox, fill=rgba(color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(radius=radius // 2))
    base.alpha_composite(layer)


def load_image_ref(ref: str) -> Image.Image:
    if ref.startswith("IMG_"):
        return Image.open(PIC_DIR / ref).convert("RGBA")
    return Image.open(ASSETS_DIR / ref).convert("RGBA")


def apply_blurred_art(
    base: Image.Image,
    art_ref: str,
    *,
    box: tuple[int, int, int, int],
    opacity: int,
    tint: tuple[int, int, int] | None = None,
) -> None:
    art = load_image_ref(art_ref)
    fitted = ImageOps.fit(art, (box[2] - box[0], box[3] - box[1]), method=Image.Resampling.LANCZOS)
    fitted = fitted.filter(ImageFilter.GaussianBlur(radius=18))
    if tint is not None:
        tint_layer = Image.new("RGBA", fitted.size, rgba(tint, 72))
        fitted = ImageChops.screen(fitted, tint_layer)
    fitted.putalpha(opacity)
    mask = Image.new("L", fitted.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rectangle((0, 0, mask.width, mask.height), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=60))
    base.paste(fitted, box[:2], mask)


def shadowed_card(image: Image.Image, radius: int, shadow_opacity: int, shadow_blur: int) -> Image.Image:
    mask = rounded_mask(image.size, radius)
    framed = Image.new("RGBA", image.size, (0, 0, 0, 0))
    framed.paste(image, (0, 0), mask)

    shadow = Image.new("RGBA", (image.width + shadow_blur * 2, image.height + shadow_blur * 2), (0, 0, 0, 0))
    shadow_mask = rounded_mask(image.size, radius)
    shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, shadow_opacity))
    shadow.paste(shadow_layer, (shadow_blur, shadow_blur), shadow_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=shadow_blur))

    output = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    output.alpha_composite(shadow)
    output.alpha_composite(framed, (shadow_blur, shadow_blur))
    return output


def wrap_text(draw: ImageDraw.ImageDraw, text: str, body_font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    lines: list[str] = []
    for paragraph in text.split("\n"):
        if not paragraph:
            lines.append("")
            continue
        current = ""
        for char in paragraph:
            candidate = f"{current}{char}"
            if current and draw.textlength(candidate, font=body_font) > max_width:
                lines.append(current)
                current = char
            else:
                current = candidate
        if current:
            lines.append(current)
    return lines


def draw_multiline(
    draw: ImageDraw.ImageDraw,
    text: str,
    xy: tuple[int, int],
    *,
    body_font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    max_width: int,
    line_gap: int,
) -> int:
    lines = wrap_text(draw, text, body_font, max_width)
    y = xy[1]
    bbox = draw.textbbox((0, 0), "天机录", font=body_font)
    height = bbox[3] - bbox[1]
    for line in lines:
        draw.text((xy[0], y), line, font=body_font, fill=fill)
        y += height + line_gap
    return y


def draw_pill(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, *, pill_font: ImageFont.FreeTypeFont, fill: tuple[int, int, int], text_fill: tuple[int, int, int]) -> int:
    text_bbox = draw.textbbox((0, 0), text, font=pill_font)
    pad_x = 26
    pad_y = 16
    width = (text_bbox[2] - text_bbox[0]) + pad_x * 2
    height = (text_bbox[3] - text_bbox[1]) + pad_y * 2
    x, y = xy
    draw.rounded_rectangle((x, y, x + width, y + height), radius=height // 2, fill=fill)
    draw.text((x + pad_x, y + pad_y - 2), text, font=pill_font, fill=text_fill)
    return width


def make_rotated_text(
    text: str,
    *,
    text_font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
    padding: tuple[int, int] = (12, 12),
) -> Image.Image:
    dummy = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
    draw = ImageDraw.Draw(dummy)
    bbox = draw.textbbox((0, 0), text, font=text_font)
    width = bbox[2] - bbox[0] + padding[0] * 2
    height = bbox[3] - bbox[1] + padding[1] * 2
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    text_draw = ImageDraw.Draw(image)
    text_draw.text((padding[0], padding[1]), text, font=text_font, fill=fill)
    return image.rotate(90, expand=True)


def flatten_to_rgb(image: Image.Image, background: tuple[int, int, int] = INK) -> Image.Image:
    if image.mode == "RGB":
        return image
    base = Image.new("RGB", image.size, background)
    base.paste(image, mask=image.getchannel("A") if "A" in image.getbands() else None)
    return base


def fit_screenshot(path: Path, box: tuple[int, int], radius: int, border: tuple[int, int, int]) -> Image.Image:
    shot = Image.open(path).convert("RGBA")
    fitted = ImageOps.contain(shot, box, method=Image.Resampling.LANCZOS)
    container = Image.new("RGBA", box, (0, 0, 0, 0))
    inner_x = (box[0] - fitted.width) // 2
    inner_y = (box[1] - fitted.height) // 2
    container.paste(fitted, (inner_x, inner_y))

    frame = Image.new("RGBA", box, rgba(border, 64))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle((0, 0, box[0] - 1, box[1] - 1), radius=radius, outline=rgba((255, 255, 255), 84), width=2)
    container = Image.alpha_composite(frame, container)
    return shadowed_card(container, radius=radius, shadow_opacity=120, shadow_blur=36)


def fit_image_card(image: Image.Image, box: tuple[int, int], radius: int, border: tuple[int, int, int]) -> Image.Image:
    fitted = ImageOps.fit(image.convert("RGBA"), box, method=Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", box, rgba(border, 22))
    frame.alpha_composite(fitted)
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle((0, 0, box[0] - 1, box[1] - 1), radius=radius, outline=rgba((255, 255, 255), 72), width=2)
    return shadowed_card(frame, radius=radius, shadow_opacity=108, shadow_blur=28)


def decorate_background(size: tuple[int, int], accent: tuple[int, int, int], glow: tuple[int, int, int]) -> Image.Image:
    base = gradient(size, INK, DEEP_TEAL)
    add_glow(base, (int(size[0] * 0.20), int(size[1] * 0.18)), int(size[0] * 0.22), accent, 120)
    add_glow(base, (int(size[0] * 0.84), int(size[1] * 0.12)), int(size[0] * 0.20), glow, 110)
    add_glow(base, (int(size[0] * 0.68), int(size[1] * 0.86)), int(size[0] * 0.28), PLUM, 90)

    lines = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(lines)
    for offset in (0.20, 0.34, 0.48):
        x1 = int(size[0] * offset)
        draw.arc((x1 - 260, int(size[1] * 0.56), x1 + 980, int(size[1] * 1.18)), start=232, end=304, fill=rgba(accent, 34), width=3)
    lines = lines.filter(ImageFilter.GaussianBlur(radius=1))
    base.alpha_composite(lines)
    return base


def make_store_image(spec_name: str, size: tuple[int, int], shot: StoreShot) -> Image.Image:
    scale_x = size[0] / 1320
    scale_y = size[1] / 2868
    scale = min(scale_x, scale_y)

    canvas = decorate_background(size, shot.accent, shot.glow)

    bg = load_image_ref(shot.background_art)
    bg = ImageOps.fit(bg, size, method=Image.Resampling.LANCZOS).filter(ImageFilter.GaussianBlur(radius=int(18 * scale)))
    bg.putalpha(188)
    canvas.alpha_composite(bg)

    darken = Image.new("RGBA", size, rgba((4, 10, 14), 118))
    canvas.alpha_composite(darken)

    vignette_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette_layer)
    vignette_draw.rectangle((0, 0, int(size[0] * 0.58), size[1]), fill=rgba((5, 11, 16), 124))
    vignette_draw.rectangle((0, int(size[1] * 0.72), size[0], size[1]), fill=rgba((5, 11, 16), 92))
    canvas.alpha_composite(vignette_layer)

    if shot.side_art is not None:
        side = load_image_ref(shot.side_art)
        side = ImageOps.fit(side, (int(size[0] * 0.40), int(size[1] * 0.56)), method=Image.Resampling.LANCZOS)
        side.putalpha(232)
        side_x = int(size[0] * 0.57)
        side_y = int(size[1] * 0.18)
        glow_layer = Image.new("RGBA", size, (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_layer)
        glow_draw.ellipse(
            (side_x - int(90 * scale), side_y + int(120 * scale), side_x + side.width + int(90 * scale), side_y + side.height + int(120 * scale)),
            fill=rgba(shot.glow, 56),
        )
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=int(42 * scale)))
        canvas.alpha_composite(glow_layer)
        side_shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        side_shadow_draw = ImageDraw.Draw(side_shadow)
        side_shadow_draw.rectangle((side_x - int(24 * scale), side_y, side_x + side.width, side_y + side.height), fill=rgba((0, 0, 0), 28))
        side_shadow = side_shadow.filter(ImageFilter.GaussianBlur(radius=int(22 * scale)))
        canvas.alpha_composite(side_shadow)
        canvas.alpha_composite(side, (side_x, side_y))

    draw = ImageDraw.Draw(canvas)
    title_font = font(FONT_SERIF, int(112 * scale))
    subtitle_font = font(FONT_SANS, int(40 * scale))
    feature_font = font(FONT_SANS, int(38 * scale))
    feature_label_font = font(FONT_SANS, int(24 * scale))
    feature_body_font = font(FONT_SANS, int(30 * scale))
    brand_font = font(FONT_SANS, int(34 * scale))

    margin_x = int(84 * scale)
    current_y = int(118 * scale)
    current_y = draw_multiline(
        draw,
        shot.title,
        (margin_x, current_y),
        body_font=title_font,
        fill=IVORY,
        max_width=int(size[0] * 0.78),
        line_gap=int(6 * scale),
    )

    current_y += int(30 * scale)
    current_y = draw_multiline(
        draw,
        shot.subtitle,
        (margin_x, current_y),
        body_font=subtitle_font,
        fill=rgba(MIST, 232),
        max_width=int(size[0] * 0.46),
        line_gap=int(10 * scale),
    )

    panel_x = margin_x
    panel_y = current_y + int(72 * scale)
    panel_w = int(size[0] * 0.45)
    panel_h = int(size[1] * 0.29)
    panel = Image.new("RGBA", (panel_w, panel_h), rgba((8, 17, 24), 158))
    panel_draw = ImageDraw.Draw(panel)
    panel_draw.rounded_rectangle((0, 0, panel_w - 1, panel_h - 1), radius=int(28 * scale), outline=rgba((255, 255, 255), 48), width=2)
    row_y = int(24 * scale)
    row_gap = int(18 * scale)
    row_h = int(66 * scale)
    for index, point in enumerate(shot.proof_points[:3], start=1):
        if index > 1:
            panel_draw.line(
                (int(24 * scale), row_y - int(8 * scale), panel_w - int(24 * scale), row_y - int(8 * scale)),
                fill=rgba((255, 255, 255), 26),
                width=1,
            )
        badge_x = int(24 * scale)
        badge_y = row_y + int(2 * scale)
        badge_w = int(78 * scale)
        panel_draw.rounded_rectangle(
            (badge_x, badge_y, badge_x + badge_w, badge_y + row_h - int(8 * scale)),
            radius=int(18 * scale),
            fill=rgba(shot.accent, 180),
        )
        panel_draw.text(
            (badge_x + int(18 * scale), badge_y + int(2 * scale)),
            f"0{index}",
            font=feature_font,
            fill=INK,
        )
        panel_draw.text(
            (badge_x + badge_w + int(22 * scale), row_y),
            point,
            font=feature_font,
            fill=IVORY,
        )
        panel_draw.text(
            (badge_x + badge_w + int(22 * scale), row_y + int(36 * scale)),
            shot.eyebrow,
            font=feature_label_font,
            fill=rgba(MIST, 176),
        )
        row_y += row_h + row_gap
    divider_y = row_y + int(2 * scale)
    panel_draw.line(
        (int(24 * scale), divider_y, panel_w - int(24 * scale), divider_y),
        fill=rgba((255, 255, 255), 30),
        width=1,
    )
    body_y = divider_y + int(28 * scale)
    body_x = int(30 * scale)
    body_max_w = panel_w - int(60 * scale)
    body_lines = wrap_text(panel_draw, shot.detail_copy, feature_body_font, body_max_w)
    body_bbox = panel_draw.textbbox((0, 0), "命途会回应你", font=feature_body_font)
    body_h = body_bbox[3] - body_bbox[1]
    for line in body_lines[:6]:
        panel_draw.text((body_x, body_y), line, font=feature_body_font, fill=rgba(IVORY, 214))
        body_y += body_h + int(8 * scale)
    canvas.alpha_composite(panel, (panel_x, panel_y))

    screenshot_box = (int(size[0] * 0.42), int(size[1] * 0.42))
    screenshot = fit_screenshot(PIC_DIR / shot.screenshot, screenshot_box, radius=int(48 * scale), border=shot.accent)
    shot_y = panel_y + panel_h - int(size[1] * 0.01)
    shot_x = int(size[0] * 0.06)
    canvas.alpha_composite(screenshot, (shot_x, shot_y))

    support_x = shot_x + int(size[0] * 0.27)
    support_y = shot_y + int(size[1] * 0.10)
    if shot.support_screenshots:
        support_box = (int(size[0] * 0.19), int(size[1] * 0.22))
        support = fit_screenshot(PIC_DIR / shot.support_screenshots[0], support_box, radius=int(38 * scale), border=shot.glow)
        canvas.alpha_composite(support, (support_x, support_y))

    brand_x = int(size[0] * 0.86)
    brand_y = int(size[1] * 0.70)
    brand_w = int(size[0] * 0.11)
    brand_h = int(size[1] * 0.24)
    seal_red = (141, 30, 24)
    brand_panel = Image.new("RGBA", (brand_w, brand_h), rgba(seal_red, 210))
    brand_draw = ImageDraw.Draw(brand_panel)
    brand_draw.rounded_rectangle((0, 0, brand_w - 1, brand_h - 1), radius=int(20 * scale), outline=rgba((255, 244, 224), 96), width=2)
    brand_draw.rounded_rectangle(
        (int(8 * scale), int(8 * scale), brand_w - int(8 * scale), brand_h - int(8 * scale)),
        radius=int(16 * scale),
        outline=rgba((255, 244, 224), 72),
        width=1,
    )
    icon = load_image_ref("AppIconTianjilu.appiconset/AppIconTianjilu.png")
    icon = ImageOps.contain(icon, (int(46 * scale), int(46 * scale)), method=Image.Resampling.LANCZOS)
    icon.putalpha(190)
    brand_panel.alpha_composite(icon, ((brand_w - icon.width) // 2, int(16 * scale)))

    vertical_title = "天\n机\n录"
    brand_draw.text(
        (int(brand_w * 0.29), int(84 * scale)),
        vertical_title,
        font=font(FONT_SERIF, int(60 * scale)),
        fill=(255, 247, 234, 255),
        spacing=int(10 * scale),
        align="center",
    )
    english = make_rotated_text(
        "LifeScript Solo",
        text_font=font(FONT_SANS, int(26 * scale)),
        fill=rgba((255, 244, 224), 200),
        padding=(6, 6),
    )
    brand_panel.alpha_composite(english, ((brand_w - english.width) // 2, brand_h - english.height - int(12 * scale)))
    canvas.alpha_composite(brand_panel, (brand_x, brand_y))
    return canvas


def mask_top_fade(image: Image.Image, fade_from: float = 0.0, fade_to: float = 0.65) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    px = mask.load()
    start = int(image.height * fade_from)
    end = int(image.height * fade_to)
    for y in range(image.height):
        if y < start:
            alpha = 0
        elif y > end:
            alpha = 255
        else:
            alpha = int(255 * (y - start) / max(1, end - start))
        for x in range(image.width):
            px[x, y] = alpha
    result = image.copy()
    result.putalpha(mask)
    return result


def poster_kv(size: tuple[int, int]) -> Image.Image:
    canvas = gradient(size, (6, 14, 17), (15, 55, 61))
    cover = Image.open(ASSETS_DIR / "cover_tianjilu.imageset/cover_tianjilu.png").convert("RGBA")
    cover_bg = ImageOps.fit(cover, size, method=Image.Resampling.LANCZOS).filter(ImageFilter.GaussianBlur(radius=12))
    cover_bg.putalpha(170)
    canvas.alpha_composite(cover_bg)
    add_glow(canvas, (int(size[0] * 0.16), int(size[1] * 0.14)), int(size[0] * 0.18), GOLD, 120)
    add_glow(canvas, (int(size[0] * 0.84), int(size[1] * 0.18)), int(size[0] * 0.22), JADE, 120)

    figure = Image.open(ASSETS_DIR / "cover_tianjilu.imageset/cover_tianjilu.png").convert("RGBA")
    figure = ImageOps.contain(figure, (int(size[0] * 0.52), int(size[1] * 0.70)), method=Image.Resampling.LANCZOS)
    figure = mask_top_fade(figure, fade_from=0.0, fade_to=0.08)
    canvas.alpha_composite(figure, (int(size[0] * 0.47), int(size[1] * 0.23)))

    draw = ImageDraw.Draw(canvas)
    title_font = font(FONT_SERIF, 142)
    subtitle_font = font(FONT_SANS, 48)
    pill_font = font(FONT_SANS, 32)

    draw_pill(draw, (96, 88), "首发主视觉", pill_font=pill_font, fill=rgba((255, 255, 255), 38), text_fill=IVORY)
    draw.text((96, 230), "你不是在看别人布局", font=title_font, fill=IVORY)
    draw.text((96, 386), "你是在亲手改命", font=title_font, fill=IVORY)
    draw_multiline(
        draw,
        "长篇互动修仙故事。人物态度、分支命途与关键因果，都会随着你的回应持续偏转。",
        (96, 580),
        body_font=subtitle_font,
        fill=MIST,
        max_width=740,
        line_gap=10,
    )

    icon = Image.open(ASSETS_DIR / "AppIconTianjilu.appiconset/AppIconTianjilu.png").convert("RGBA")
    icon = ImageOps.contain(icon, (168, 168), method=Image.Resampling.LANCZOS)
    icon_card = shadowed_card(icon, radius=42, shadow_opacity=110, shadow_blur=30)
    canvas.alpha_composite(icon_card, (96, 820))

    shot = fit_screenshot(PIC_DIR / "IMG_5764.PNG", (462, 996), radius=42, border=GOLD)
    canvas.alpha_composite(shot, (96, 1038))
    shot2 = fit_screenshot(PIC_DIR / "IMG_5767.PNG", (390, 836), radius=40, border=JADE)
    canvas.alpha_composite(shot2, (588, 1142))

    draw.text((288, 860), "天机录", font=font(FONT_SERIF, 86), fill=IVORY)
    draw.text((290, 950), "卷一全免 · 前 120 章免费", font=font(FONT_SANS, 44), fill=rgba(IVORY, 228))
    return canvas


def poster_relationship(size: tuple[int, int]) -> Image.Image:
    canvas = gradient(size, (11, 16, 25), (22, 53, 55))
    add_glow(canvas, (int(size[0] * 0.22), int(size[1] * 0.18)), 260, GOLD, 100)
    add_glow(canvas, (int(size[0] * 0.78), int(size[1] * 0.12)), 220, JADE, 100)
    add_glow(canvas, (int(size[0] * 0.50), int(size[1] * 0.86)), 300, PLUM, 100)

    draw = ImageDraw.Draw(canvas)
    title_font = font(FONT_SERIF, 126)
    subtitle_font = font(FONT_SANS, 46)
    pill_font = font(FONT_SANS, 30)

    draw_pill(draw, (96, 88), "角色关系海报", pill_font=pill_font, fill=rgba((255, 255, 255), 34), text_fill=IVORY)
    draw.text((96, 230), "谁信你", font=title_font, fill=IVORY)
    draw.text((96, 376), "谁防你", font=title_font, fill=IVORY)
    draw.text((96, 522), "都会把命途拧向另一边", font=title_font, fill=IVORY)
    draw_multiline(
        draw,
        "苏青瑶、夜清、凌渊等关键人物，会带着各自的立场和记忆，持续影响你后面的每一步。",
        (96, 706),
        body_font=subtitle_font,
        fill=MIST,
        max_width=1408,
        line_gap=10,
    )

    portraits = [
        ("tianjilu_su_qingyao_portrait.imageset/tianjilu_su_qingyao_portrait.png", (92, 980), (398, 520), GOLD, "苏青瑶"),
        ("tianjilu_ye_qing_portrait.imageset/tianjilu_ye_qing_portrait.png", (512, 896), (576, 680), (180, 150, 220), "夜清"),
        ("tianjilu_ling_yuan_portrait.imageset/tianjilu_ling_yuan_portrait.png", (1148, 1034), (356, 468), JADE, "凌渊"),
    ]

    for asset, pos, box, tint, name in portraits:
        art = Image.open(ASSETS_DIR / asset).convert("RGBA")
        art = ImageOps.fit(art, box, method=Image.Resampling.LANCZOS)
        card = fit_portrait_card(art, box, tint)
        canvas.alpha_composite(card, pos)
        text_y = pos[1] + card.height + 24
        draw.text((pos[0] + 12, text_y), name, font=font(FONT_SERIF, 62), fill=IVORY)

    line_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    line_draw = ImageDraw.Draw(line_layer)
    line_draw.line((420, 1236, 804, 1188), fill=rgba(GOLD, 140), width=5)
    line_draw.line((1088, 1286, 960, 1222), fill=rgba(JADE, 140), width=5)
    line_layer = line_layer.filter(ImageFilter.GaussianBlur(radius=2))
    canvas.alpha_composite(line_layer)

    chips_y = 1848
    chip_x = 96
    for text in ("人物卷", "关系张力", "长期发酵", "多结局"):
        chip_x += draw_pill(draw, (chip_x, chips_y), text, pill_font=pill_font, fill=rgba((255, 255, 255), 24), text_fill=IVORY) + 18

    return canvas


def fit_portrait_card(image: Image.Image, box: tuple[int, int], tint: tuple[int, int, int]) -> Image.Image:
    border = Image.new("RGBA", box, rgba(tint, 24))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle((0, 0, box[0] - 1, box[1] - 1), radius=42, outline=rgba((255, 255, 255), 86), width=2)
    border.alpha_composite(image)
    return shadowed_card(border, radius=42, shadow_opacity=105, shadow_blur=24)


def poster_free_volume(size: tuple[int, int]) -> Image.Image:
    canvas = gradient(size, (8, 20, 23), (18, 63, 69))
    add_glow(canvas, (int(size[0] * 0.16), int(size[1] * 0.12)), 260, GOLD, 120)
    add_glow(canvas, (int(size[0] * 0.76), int(size[1] * 0.18)), 260, JADE, 120)

    hero = Image.open(ASSETS_DIR / "cover_tianjilu.imageset/cover_tianjilu.png").convert("RGBA")
    hero = ImageOps.contain(hero, (780, 1510), method=Image.Resampling.LANCZOS)
    hero = mask_top_fade(hero, fade_from=0.0, fade_to=0.08)
    canvas.alpha_composite(hero, (842, 350))

    draw = ImageDraw.Draw(canvas)
    title_font = font(FONT_SERIF, 148)
    subtitle_font = font(FONT_SANS, 50)
    pill_font = font(FONT_SANS, 34)

    draw_pill(draw, (96, 88), "转化海报", pill_font=pill_font, fill=rgba((255, 255, 255), 36), text_fill=IVORY)
    draw.text((96, 238), "卷一全免", font=title_font, fill=IVORY)
    draw.text((96, 404), "前 120 章免费入局", font=title_font, fill=IVORY)
    draw_multiline(
        draw,
        "先把第一卷读进去，再决定要不要继续追更。不是样章试玩，而是一整卷完整体验。",
        (96, 608),
        body_font=subtitle_font,
        fill=MIST,
        max_width=760,
        line_gap=10,
    )

    stat_y = 862
    for stat in ("9 卷长线规划", "多分支因果回响", "角色关系持续变化"):
        stat_w = draw_pill(draw, (96, stat_y), stat, pill_font=pill_font, fill=rgba(GOLD, 150), text_fill=INK)
        stat_y += 88
        if stat_w < 0:
            break

    shot = fit_screenshot(PIC_DIR / "IMG_5763.PNG", (456, 988), radius=44, border=GOLD)
    canvas.alpha_composite(shot, (108, 1120))

    draw.text((96, 1598), "进入天机局", font=font(FONT_SERIF, 88), fill=IVORY)
    draw.text((96, 1704), "LifeScript Solo · 天机录", font=font(FONT_SANS, 46), fill=rgba(IVORY, 228))
    return canvas


def save_contact_sheet(images: Iterable[Path], output: Path) -> None:
    pics = [Image.open(path).convert("RGB") for path in images]
    thumbs: list[Image.Image] = []
    thumb_w = 230
    pad = 28
    label_h = 50
    f = font(FONT_SANS, 20)

    for path, image in zip(images, pics):
        thumb = ImageOps.contain(image, (thumb_w, 360), method=Image.Resampling.LANCZOS)
        card = Image.new("RGB", (thumb_w, thumb.height + label_h), (244, 245, 246))
        card.paste(thumb, ((thumb_w - thumb.width) // 2, 0))
        draw = ImageDraw.Draw(card)
        draw.text((8, thumb.height + 12), path.name, font=f, fill=(28, 32, 36))
        thumbs.append(card)

    cols = 3
    rows = (len(thumbs) + cols - 1) // cols
    card_h = max(card.height for card in thumbs)
    sheet = Image.new("RGB", (cols * thumb_w + (cols + 1) * pad, rows * card_h + (rows + 1) * pad), (228, 231, 236))
    for index, thumb in enumerate(thumbs):
        x = pad + (index % cols) * (thumb_w + pad)
        y = pad + (index // cols) * (card_h + pad)
        sheet.paste(thumb, (x, y))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def main() -> None:
    (OUT_DIR / "app_store_6_9").mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "app_store_6_5").mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "promo").mkdir(parents=True, exist_ok=True)

    store_paths: list[Path] = []
    for shot in STORE_SHOTS:
        img_69 = make_store_image('6.9" · 1320×2868', (1320, 2868), shot)
        path_69 = OUT_DIR / "app_store_6_9" / shot.filename
        flatten_to_rgb(img_69).save(path_69)
        store_paths.append(path_69)

        img_65 = make_store_image('6.5" · 1242×2688', (1242, 2688), shot)
        path_65 = OUT_DIR / "app_store_6_5" / shot.filename
        flatten_to_rgb(img_65).save(path_65)

    poster1 = poster_kv((1600, 2000))
    poster2 = poster_relationship((1600, 2000))
    poster3 = poster_free_volume((1600, 2000))
    poster_paths = [
        OUT_DIR / "promo" / "promo_kv_main.png",
        OUT_DIR / "promo" / "promo_relationships.png",
        OUT_DIR / "promo" / "promo_volume_free.png",
    ]
    for poster, path in zip((poster1, poster2, poster3), poster_paths):
        flatten_to_rgb(poster).save(path)

    save_contact_sheet(store_paths, OUT_DIR / "previews" / "app_store_contact.png")
    save_contact_sheet(poster_paths, OUT_DIR / "previews" / "promo_contact.png")
    print(f"Generated assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
