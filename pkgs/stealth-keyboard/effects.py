"""Per-key lighting patterns rendered through the tested RAM color reports."""

import colorsys
import math
import re

import layout


MODES = ("static", "reactive", "breathing", "cycle", "wave", "gradient", "pulse", "blink", "twinkle", "scanner")
LABELS = ("Static", "Keypress fade", "Breathing", "Color cycle", "Wave", "Gradient", "Pulse", "Blink", "Twinkle", "Scanner")
TIMED = set(MODES) - {"static", "reactive", "gradient"}
DIRECTIONS = ("right", "left", "down", "up", "outward", "inward", "clockwise", "counterclockwise")
DIRECTION_LABELS = ("Right", "Left", "Down", "Up", "Outward", "Inward", "Clockwise", "Counterclockwise")
EASINGS = ("sine", "linear", "smooth", "in", "out")
EASING_LABELS = ("Sine", "Linear", "Smooth", "Ease in", "Ease out")
RAINBOW = ["#FF0000", "#FFAA00", "#FFFF00", "#00FF00", "#00FFFF", "#0055FF", "#AA00FF"]


def color(value):
    if not isinstance(value, str) or not re.fullmatch(r"#?[0-9a-fA-F]{6}", value):
        raise ValueError("Enter six hex digits, such as #FF8040.")
    return "#" + value.lstrip("#").upper()


def settings(mode="static"):
    return {"mode": mode, "period_ms": 3000, "phase": 0, "delay_ms": 0, "cycles": 0,
            "palette": [], "direction": "right", "spacing": 20 if mode == "scanner" else 100,
            "origin_x": 50, "origin_y": 50, "minimum": 0, "maximum": 100,
            "easing": "sine", "duty": 50, "fade_ms": 750, "hit_color": "#000000",
            "restore_reactive": False}


def normalize(value):
    if not isinstance(value, dict):
        raise ValueError("An effect must be an object.")
    result = settings()
    result.update({key: val for key, val in value.items() if key in result})
    if result["mode"] not in MODES or result["direction"] not in DIRECTIONS or result["easing"] not in EASINGS:
        raise ValueError("Unknown effect, direction, or easing curve.")
    ranges = {"period_ms": (100, 120000), "phase": (0, 100), "delay_ms": (0, 60000),
              "cycles": (0, 1000), "spacing": (5, 400), "origin_x": (0, 100), "origin_y": (0, 100),
              "minimum": (0, 100), "maximum": (0, 100), "duty": (1, 99), "fade_ms": (50, 2000)}
    for key, (low, high) in ranges.items():
        val = result[key]
        if type(val) not in (int, float) or not math.isfinite(val) or not low <= val <= high:
            raise ValueError(f"{key} must be between {low} and {high}.")
    for key in ("period_ms", "delay_ms", "cycles", "fade_ms"):
        if result[key] != int(result[key]):
            raise ValueError(f"{key} must be a whole number.")
        result[key] = int(result[key])
    if result["minimum"] > result["maximum"]:
        raise ValueError("Minimum brightness cannot exceed maximum brightness.")
    palette = result["palette"]
    if not isinstance(palette, list) or len(palette) > 16:
        raise ValueError("A palette can contain up to 16 colors.")
    result["palette"] = [color(c) for c in palette]
    result["hit_color"] = color(result["hit_color"])
    if type(result["restore_reactive"]) is not bool:
        raise ValueError("Restore keypress fade must be true or false.")
    return result


def resolved(profile, code):
    return profile["key_effects"].get(code, profile["effect"])


def rgb(value):
    return tuple(bytes.fromhex(value[1:]))


def hex_rgb(channels):
    # Keep mathematical half steps stable across floating-point easing curves.
    return "#" + "".join(f"{max(0, min(255, round(c + 1e-9))):02X}" for c in channels)


def mix(first, second, amount):
    return tuple(a + (b - a) * amount for a, b in zip(first, second))


def palette_color(palette, phase, base=None):
    if not palette:
        return base if base is not None else tuple(c * 255 for c in colorsys.hsv_to_rgb(phase % 1, 1, 1))
    position = ((phase % 1) * len(palette)) % len(palette)
    index = math.floor(position)
    return mix(rgb(palette[index]), rgb(palette[(index + 1) % len(palette)]), position - index)


def ease(value, curve):
    value = max(0, min(1, value))
    if curve == "sine":
        return (1 - math.cos(math.pi * value)) / 2
    if curve == "smooth":
        return value * value * (3 - 2 * value)
    if curve == "in":
        return value * value
    if curve == "out":
        return 1 - (1 - value) ** 2
    return value


def position(code, spec):
    key = layout.BY_CODE.get(code)
    x = (key.x + key.width / 2) / layout.WIDTH if key else 0
    y = (key.y + key.height / 2) / layout.HEIGHT if key else 0
    direction = spec["direction"]
    if direction in ("right", "left"):
        return x if direction == "right" else 1 - x
    if direction in ("down", "up"):
        return y if direction == "down" else 1 - y
    dx, dy = x - spec["origin_x"] / 100, y - spec["origin_y"] / 100
    if direction in ("outward", "inward"):
        distance = math.hypot(dx, dy)
        return distance if direction == "outward" else -distance
    angle = math.atan2(dy, dx) / (2 * math.pi)
    return angle if direction == "clockwise" else -angle


def one(code, base, spec, elapsed, preview_hit=None):
    mode = spec["mode"]
    base_rgb = rgb(base)
    maximum = spec["maximum"] / 100
    if mode == "reactive" and preview_hit is not None:
        progress = max(0, min(1, (elapsed - preview_hit) * 1000 / spec["fade_ms"]))
        return hex_rgb(c * maximum for c in mix(rgb(spec["hit_color"]), base_rgb, progress))
    if mode in ("static", "reactive"):
        return hex_rgb(c * maximum for c in base_rgb)
    time = elapsed - spec["delay_ms"] / 1000
    if mode in TIMED and (time < 0 or spec["cycles"] and time >= spec["cycles"] * spec["period_ms"] / 1000):
        return hex_rgb(c * maximum for c in base_rgb)
    phase = ((time * 1000 / spec["period_ms"] if mode in TIMED else 0) + spec["phase"] / 100) % 1
    palette = spec["palette"]
    intensity = 1
    channels = palette_color(palette, phase, base_rgb)
    if mode in ("wave", "gradient"):
        offset = position(code, spec) * 100 / spec["spacing"] - phase
        channels = palette_color(palette, offset)
    elif mode == "cycle":
        channels = palette_color(palette, phase)
    elif mode == "breathing":
        intensity = ease(abs(2 * phase - 1), spec["easing"])
    elif mode == "pulse":
        duty = spec["duty"] / 100
        intensity = ease(1 - abs(2 * phase / duty - 1), spec["easing"]) if phase < duty else 0
    elif mode == "blink":
        intensity = float(phase < spec["duty"] / 100)
    elif mode == "twinkle":
        offset = ((code * 2654435761) % 1000) / 1000
        intensity = max(0, math.cos(2 * math.pi * (phase + offset))) ** 4
        channels = palette_color(palette, phase + offset, base_rgb)
    elif mode == "scanner":
        center = ease(1 - abs(2 * phase - 1), spec["easing"])
        distance = abs(position(code, spec) - center)
        intensity = max(0, 1 - distance / (spec["spacing"] / 100))
    minimum = spec["minimum"] / 100
    scale = minimum + (maximum - minimum) * intensity
    return hex_rgb(c * scale for c in channels)


def render(profile, elapsed, hits=None):
    hits = hits or {}
    return {code: one(code, base, resolved(profile, code), elapsed, hits.get(code))
            for code, base in profile["colors"].items()}


def base_frame(profile):
    output = {}
    for code, base in profile["colors"].items():
        spec = resolved(profile, code)
        if spec["mode"] == "gradient":
            output[code] = one(code, base, spec, 0)
        else:
            output[code] = hex_rgb(c * spec["maximum"] / 100 for c in rgb(base))
    return output


def timed_codes(profile):
    return {code for code in profile["colors"] if resolved(profile, code)["mode"] in TIMED}


def active_codes(profile, elapsed):
    return {code for code in timed_codes(profile)
            if not (spec := resolved(profile, code))["cycles"]
            or elapsed < (spec["delay_ms"] + spec["period_ms"] * spec["cycles"]) / 1000}


def running(profile, elapsed):
    return bool(active_codes(profile, elapsed))


def reactive_configs(profile, restoring=False):
    return {code: {"fade_ms": spec["fade_ms"],
                   "hit_color": hex_rgb(c * spec["maximum"] / 100 for c in rgb(spec["hit_color"]))}
            for code in profile["colors"] if (spec := resolved(profile, code))["mode"] == "reactive"
            or restoring and spec["mode"] in TIMED and spec["restore_reactive"]}


# Retain the simple renderer for CLI users of the first package version.
def validate(effect, period_ms):
    if effect not in ("none", "wave", "breathing") or type(period_ms) is not int or not 500 <= period_ms <= 30000:
        raise ValueError("Choose a known effect and a period from 0.5 to 30 seconds.")


def frame(colors, effect, phase):
    validate(effect, 3000)
    spec = settings("static" if effect == "none" else effect)
    return render({"colors": colors, "effect": spec, "key_effects": {}}, phase * 3)
