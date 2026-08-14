#!/usr/bin/env python3
"""Generate Noctalia Kvantum templates from Catppuccin macchiato-blue sources.

Reads upstream .kvconfig + .svg, replaces Catppuccin (and leftover Arc) hexes
with Noctalia TemplateEngine expressions aligned to the qtct ColorScheme map,
and applies translucency settings Kvantum actually honors.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# qtct.conf ColorScheme roles (active_colors order):
#   windowText/text     → on_background
#   button              → surface
#   buttonText          → on_surface
#   base / window       → background
#   shadow              → shadow
#   highlight           → primary_container
#   highlightedText     → on_primary_container
#   link                → secondary
#   linkVisited         → primary
#   alternateBase /
#     toolTipBase       → surface_variant
#   toolTipText         → on_surface
#   accent              → primary
#
# Longest hex keys first so 8-digit accents win over their 6-digit base.
# (hex_without_#, token, svg_alpha) — svg_alpha rarely used; window opacity
# is forced via reduce_window_opacity (see patch_kvconfig).
HEX_MAP: list[tuple[str, str, str]] = [
    ("8AADF44D", "primary_container", "4d"),
    ("8AADF4", "primary", ""),
    ("809FE1", "primary_container", ""),  # muted blue (SVG-only)
    ("96B4F4", "primary", ""),  # visited-link blue
    ("C6A0F6", "tertiary", ""),  # mauve
    ("ED8796", "error", ""),  # red
    ("CAD3F5", "on_surface", ""),  # UI chrome text; GeneralColors uses on_background for palette text
    ("A5ADCB", "on_surface_variant", ""),  # subtext0
    ("939AB7", "on_surface_variant", ""),  # overlay2
    ("6E738D", "outline_variant", ""),  # overlay0
    ("5B6078", "outline", ""),  # surface2
    ("494D64", "surface_variant", ""),  # surface1
    ("363A4F", "surface", ""),  # surface0 → button
    ("24273A", "background", ""),  # ctp base → window/base
    ("1E2030", "background", ""),  # ctp mantle → darker panels (same role as base)
    ("31363B", "background", ""),
    ("141414", "shadow", ""),
    ("000000", "shadow", ""),
    # Arc gray leftovers
    ("EAEAEA", "on_surface", ""),
    ("DCDCDC", "on_surface", ""),
    ("D6D6D6", "on_surface", ""),
    ("D2D2D2", "on_surface", ""),
    ("BFBFBF", "on_surface_variant", ""),
    ("BEBEBE", "on_surface_variant", ""),
    ("B6B6B6", "on_surface_variant", ""),
    ("B4B4B4", "on_surface_variant", ""),
    ("A6A6A6", "on_surface_variant", ""),
    ("999999", "outline", ""),
    ("919191", "outline", ""),
    ("7F7F7F", "outline", ""),
]

# Explicit GeneralColors block matching qtct roles.
# #RRGGBBAA is supported for these keys; cc ≈ 80% opacity (204/255).
#
# Item views: translucent alt.base is composited OVER base.color. A near-black
# base at high opacity reads as fully opaque even with an alpha byte — keep base
# and alt.base on the same alpha so zebra rows both show the wallpaper, while
# surface_variant stays the lighter stripe.
GENERAL_COLORS = """
[GeneralColors]
window.color=#{{ colors.background.default.hex_stripped }}
inactive.window.color=#{{ colors.background.default.hex_stripped }}
base.color=#{{ colors.background.default.hex_stripped }}
alt.base.color=#{{ colors.surface_variant.default.hex_stripped }}
button.color=#{{ colors.surface.default.hex_stripped }}
light.color=#ffffff
mid.light.color=#cacaca
dark.color=#9f9f9f
mid.color=#b8b8b8
highlight.color=#{{ colors.primary_container.default.hex_stripped }}
inactive.highlight.color=#{{ colors.surface_variant.default.hex_stripped }}
tooltip.base.color=#{{ colors.surface_variant.default.hex_stripped }}
text.color=#{{ colors.on_background.default.hex_stripped }}
window.text.color=#{{ colors.on_background.default.hex_stripped }}
button.text.color=#{{ colors.on_surface.default.hex_stripped }}
disabled.text.color=#{{ colors.on_surface_variant.default.hex_stripped }}
tooltip.text.color=#{{ colors.on_surface.default.hex_stripped }}
highlight.text.color=#{{ colors.on_primary_container.default.hex_stripped }}
link.color=#{{ colors.secondary.default.hex_stripped }}
link.visited.color=#{{ colors.primary.default.hex_stripped }}
""".lstrip()


def token_expr(token: str, alpha: str = "") -> str:
    return f"#{{{{ colors.{token}.default.hex_stripped }}}}{alpha}"


def replace_hexes(text: str, *, for_svg: bool) -> str:
    out = text
    for hex_digits, token, svg_alpha in HEX_MAP:
        # Keep baked-in alpha only for 8-digit sources (e.g. selection).
        alpha = svg_alpha if (for_svg or len(hex_digits) == 8) else ""
        if not for_svg and len(hex_digits) == 6:
            alpha = ""
        replacement = token_expr(token, alpha)
        out = re.sub(re.escape("#" + hex_digits), replacement, out, flags=re.IGNORECASE)
    return out


def patch_kvconfig(text: str) -> str:
    text = text.replace("translucent_windows=false", "translucent_windows=true")
    text = text.replace("transparent_dolphin_view=false", "transparent_dolphin_view=true")
    text = text.replace("blur_translucent=true", "blur_translucent=false")
    text = text.replace("popup_blurring=true", "popup_blurring=false")
    text = text.replace("blur_konsole=true", "blur_konsole=false")
    text = text.replace("opaque=kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,smplayer,smplayer2,avidemux,avidemux2_qt4,avidemux3_qt4,avidemux3_qt5,kamoso,QtCreator,VirtualBox,trojita,dragon,digikam,qmplay2", "")

    #using niri blur so dont need kvantum blur
    #text = text.replace("blurring=false", "blurring=true")

    #the 20% is applied on top of the hex opacity so not needed
    text = re.sub(
        r"^reduce_window_opacity=\d+",
        "reduce_window_opacity=0",
        text,
        flags=re.MULTILINE,
    )
    text = re.sub(
        r"^reduce_menu_opacity=\d+",
        "reduce_menu_opacity=0",
        text,
        flags=re.MULTILINE,
    )
    text = text.replace(
        "comment=Catppuccin-Macchiato-Blue",
        "comment=Noctalia (from Catppuccin Macchiato Blue)",
    )

    # Replace entire [GeneralColors] with qtct-aligned roles.
    text = re.sub(
        r"\[GeneralColors\]\n(?:.*\n)*?(?=\[|\Z)",
        GENERAL_COLORS + "\n",
        text,
        count=1,
    )

    return text


def patch_svg(text: str) -> str:
    """Make SVG paints translucent in a way Kvantum/Qt actually honor.

    fill-opacity alone is not enough for button/item chrome — bake cc (~80%)
    into every #{{ ... hex_stripped }} that does not already have an alpha
    suffix (and is not an on_* text color). Also set fill-opacity:0.8 on every
    style that does not already define fill-opacity.
    """

    # #{{ colors.foo.default.hex_stripped }} → …cc  (skip on_* and existing AA)
    text = re.sub(
        r"#\{\{\s*colors\.(?!on_)([a-z0-9_]+)\.default\.hex_stripped\s*\}\}(?![0-9A-Fa-f]{2})",
        r"#{{ colors.\1.default.hex_stripped }}",
        text,
    )

    def _style(m: re.Match[str]) -> str:
        style = m.group(1)
        if re.search(r"(?:^|;)\s*fill-opacity\s*:", style):
            return m.group(0)
        return f'style="{style};fill-opacity:0.2"'

    return text #re.sub(r'style="([^"]*)"', _style, text)


def assert_no_raw_hexes(text: str, path: Path) -> None:
    # Allow qtct's hardcoded light/midlight/dark/mid grays in kvconfig.
    allowed = {"#FFFFFF", "#CACACA", "#9F9F9F", "#B8B8B8"}
    raw = sorted(
        {
            m.group(0).upper()
            for m in re.finditer(r"#[0-9A-Fa-f]{6,8}", text)
            if m.group(0).upper() not in allowed
        }
    )
    if raw:
        raise SystemExit(f"{path.name}: leftover hex colors after replace: {raw}")


def main() -> None:
    if len(sys.argv) != 4:
        print(
            f"usage: {sys.argv[0]} <in.kvconfig> <in.svg> <out-dir>",
            file=sys.stderr,
        )
        sys.exit(2)

    kv_in = Path(sys.argv[1])
    svg_in = Path(sys.argv[2])
    out_dir = Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)

    kv = patch_kvconfig(replace_hexes(kv_in.read_text(), for_svg=False))
    svg = patch_svg(replace_hexes(svg_in.read_text(), for_svg=True))

    kv_out = out_dir / "kvantum.kvconfig"
    svg_out = out_dir / "kvantum.svg"
    kv_out.write_text(kv)
    svg_out.write_text(svg)

    assert_no_raw_hexes(kv, kv_out)
    assert_no_raw_hexes(svg, svg_out)

    print(f"wrote {kv_out}")
    print(f"wrote {svg_out}")


if __name__ == "__main__":
    main()
