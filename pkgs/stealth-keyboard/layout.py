"""Physical key positions, in units of a normal key, for the Stealth 14."""

from typing import NamedTuple


class Key(NamedTuple):
    label: str
    code: int
    x: float
    y: float
    width: float = 1
    height: float = 1


WIDTH, HEIGHT = 15, 5.5
UNIT, GAP, PADDING = 48, 4, 12
NATURAL_WIDTH = WIDTH * UNIT + 2 * PADDING
NATURAL_HEIGHT = HEIGHT * UNIT + 2 * PADDING


def row(y, entries):
    x = 0
    keys = []
    for label, code, width in entries:
        keys.append(Key(label, code, x, y, width))
        x += width
    assert x <= WIDTH
    return keys


function_keys = [("Esc", 41)] + [(f"F{i + 1}", 58 + i) for i in range(12)]
function_keys += [("PrtSc", 70), ("Del", 76), ("Power", 102)]
KEYS = [Key(label, code, i * WIDTH / len(function_keys), 0, WIDTH / len(function_keys), 0.5)
        for i, (label, code) in enumerate(function_keys)]
KEYS += row(0.5, [("`", 53, 1)] + [(str((i + 1) % 10), 30 + i, 1) for i in range(10)]
            + [("−", 45, 1), ("=", 46, 1), ("Backspace", 42, 2)])
KEYS += row(1.5, [("Tab", 43, 1.5)]
            + [(label, code, 1) for label, code in zip("QWERTYUIOP", [20, 26, 8, 21, 23, 28, 24, 12, 18, 19])]
            + [("[", 47, 1), ("]", 48, 1), ("\\", 49, 1.5)])
KEYS += row(2.5, [("Caps", 57, 1.75)]
            + [(label, code, 1) for label, code in zip("ASDFGHJKL", [4, 22, 7, 9, 10, 11, 13, 14, 15])]
            + [(";", 51, 1), ("'", 52, 1), ("Enter", 40, 2.25)])
KEYS += row(3.5, [("Shift", 225, 2)]
            + [(label, code, 1) for label, code in zip("ZXCVBNM", [29, 27, 6, 25, 5, 17, 16])]
            + [(",", 54, 1), (".", 55, 1), ("/", 56, 1), ("Shift", 229, 3)])
KEYS += row(4.5, [("Ctrl", 224, 1), ("Fn", 240, 1), ("Super", 227, 1), ("Alt", 226, 1),
                 ("Space", 44, 5), ("AltGr", 230, 1), ("\\", 100, 1), ("Ctrl", 228, 1)])
KEYS += [Key("PgUp\nHome", 75, 12, 4.5, 1, 0.5), Key("↑", 82, 13, 4.5, 1, 0.5),
         Key("PgDn\nEnd", 78, 14, 4.5, 1, 0.5), Key("←", 80, 12, 5, 1, 0.5),
         Key("↓", 81, 13, 5, 1, 0.5), Key("→", 79, 14, 5, 1, 0.5)]
BY_CODE = {key.code: key for key in KEYS}


def rectangles(width, height):
    """One common scale, including gaps and padding; never stretch a row."""
    scale = min(width / NATURAL_WIDTH, height / NATURAL_HEIGHT)
    x0 = (width - NATURAL_WIDTH * scale) / 2
    y0 = (height - NATURAL_HEIGHT * scale) / 2
    return {key.code: ((PADDING + key.x * UNIT + GAP * min(1, key.width) / 2) * scale + x0,
                       (PADDING + key.y * UNIT + GAP * min(1, key.height) / 2) * scale + y0,
                       (key.width * UNIT - GAP * min(1, key.width)) * scale,
                       (key.height * UNIT - GAP * min(1, key.height)) * scale)
            for key in KEYS}


def text_color(rgb):
    channels = [c / 255 for c in rgb]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    luminance = sum(c * weight for c, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
    return "#000000" if (luminance + 0.05) / 0.05 >= 1.05 / (luminance + 0.05) else "#FFFFFF"
