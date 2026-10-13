"""Timed frames use the tested RAM color report; no effect-program uploads."""

import colorsys
import math

import layout


NAMES = ("none", "wave", "breathing")


def validate(effect, period_ms):
    if effect not in NAMES or type(period_ms) is not int or not 500 <= period_ms <= 30000:
        raise ValueError("Choose a known effect and a period from 0.5 to 30 seconds.")


def frame(colors, effect, phase):
    if effect not in NAMES:
        raise ValueError("Unknown timed effect.")
    if effect == "none":
        return dict(colors)
    phase %= 1
    output = {}
    for code, value in colors.items():
        if effect == "wave":
            key = layout.BY_CODE.get(code)
            x = key.x + key.width / 2 if key else 0
            rgb = colorsys.hsv_to_rgb((x / layout.WIDTH - phase) % 1, 1, 1)
            rgb = [round(channel * 255) for channel in rgb]
        else:
            scale = (1 + math.cos(2 * math.pi * phase)) / 2
            rgb = [round(channel * scale) for channel in bytes.fromhex(value[1:])]
        output[code] = "#" + "".join(f"{channel:02X}" for channel in rgb)
    return output
