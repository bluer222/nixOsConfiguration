"""Colors for settings that continue running on the keyboard after Apply."""

import colorsys
import math
import re
import struct

import layout


MODES = ("static", "reactive", "gradient", "cycle", "breathing", "wave")
LABELS = ("Static", "Keypress fade", "Gradient", "Color cycle", "Breathing", "Wave")
ANIMATED = {"cycle", "breathing", "wave"}
MAX_PROGRAMS = 14
DIRECTIONS = ("right", "left", "down", "up", "outward", "inward", "clockwise", "counterclockwise")
DIRECTION_LABELS = ("Right", "Left", "Down", "Up", "Outward", "Inward", "Clockwise", "Counterclockwise")
RAINBOW = ["#FF0000", "#FFAA00", "#FFFF00", "#00FF00", "#00FFFF", "#0055FF", "#AA00FF"]
REMOVED_MODES = {"pulse", "blink", "twinkle", "scanner"}


def color(value):
    if not isinstance(value, str) or not re.fullmatch(r"#?[0-9a-fA-F]{6}", value):
        raise ValueError("Enter six hex digits, such as #FF8040.")
    return "#" + value.lstrip("#").upper()


def settings(mode="static"):
    return {"mode": mode, "palette": [], "direction": "right", "spacing": 100,
            "phase": 0, "origin_x": 50, "origin_y": 50, "maximum": 100,
            "fade_ms": 750, "hit_color": "#000000", "speed": 50, "minimum": 0}


def normalize(value):
    if not isinstance(value, dict):
        raise ValueError("An effect must be an object.")
    result = settings()
    result.update({key: val for key, val in value.items() if key in result})
    if result["mode"] not in MODES:
        raise ValueError("Choose a supported onboard effect.")
    if result["direction"] not in DIRECTIONS:
        raise ValueError("Unknown gradient direction.")
    if result["mode"] == "wave" and result["direction"] not in DIRECTIONS[:6]:
        raise ValueError("Onboard waves support horizontal, vertical, or radial directions.")
    for key, (low, high) in {"spacing": (5, 400), "phase": (0, 100), "origin_x": (0, 100),
                              "origin_y": (0, 100), "maximum": (0, 100), "fade_ms": (50, 2000), "speed": (1, 100), "minimum": (0, 100)}.items():
        val = result[key]
        if type(val) not in (int, float) or not math.isfinite(val) or not low <= val <= high:
            raise ValueError(f"{key} must be between {low} and {high}.")
    for name in ("fade_ms", "speed"):
        if result[name] != int(result[name]):
            raise ValueError(f"{name} must be a whole number.")
        result[name] = int(result[name])
    if not isinstance(result["palette"], list) or len(result["palette"]) > 16:
        raise ValueError("A gradient palette can contain up to 16 colors.")
    limit = palette_limit(result["mode"])
    if len(result["palette"]) > limit:
        raise ValueError(f"This effect supports up to {limit} colors.")
    result["palette"] = [color(c) for c in result["palette"]]
    result["hit_color"] = color(result["hit_color"])
    return result


def resolved(profile, code):
    return profile["key_effects"].get(code, profile["effect"])


def rgb(value):
    return tuple(bytes.fromhex(value[1:]))


def hex_rgb(channels):
    return "#" + "".join(f"{max(0, min(255, round(c + 1e-9))):02X}" for c in channels)


def palette_color(palette, phase):
    if not palette:
        return tuple(c * 255 for c in colorsys.hsv_to_rgb(phase % 1, 1, 1))
    position = ((phase % 1) * len(palette)) % len(palette)
    index = math.floor(position)
    fraction = position - index
    return tuple(a + (b - a) * fraction for a, b in zip(rgb(palette[index]), rgb(palette[(index + 1) % len(palette)])))


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


def base_frame(profile):
    output = {}
    for code, base in profile["colors"].items():
        spec = resolved(profile, code)
        if spec["mode"] == "gradient":
            channels = palette_color(spec["palette"], position(code, spec) * 100 / spec["spacing"] - spec["phase"] / 100)
        elif spec["mode"] in ANIMATED:
            initial = struct.unpack_from("<HHH", program(code, dict(profile, brightness=100)), 128)
            output[code] = hex_rgb(c / 16 for c in initial)
            continue
        else:
            channels = rgb(base)
        output[code] = hex_rgb(c * spec["maximum"] / 100 for c in channels)
    return output


def reactive_configs(profile):
    return {code: {"fade_ms": spec["fade_ms"],
                   "hit_color": hex_rgb(c * spec["maximum"] / 100 for c in rgb(spec["hit_color"]))}
            for code in profile["colors"] if (spec := resolved(profile, code))["mode"] == "reactive"}


def palette_limit(mode):
    return 7 if mode == "breathing" else 14 if mode in ANIMATED else 16


def program(code, profile):
    """Build the 151-byte onboard ramp program, using fixed-point channel deltas."""
    spec = resolved(profile, code)
    palette = spec["palette"] or ([profile["colors"][code]] if spec["mode"] == "breathing" else RAINBOW)
    scale = profile["brightness"] * spec["maximum"] / 10000
    colors = [tuple(round(c * scale) for c in rgb(value)) for value in palette]
    ticks = round(10000 / spec["speed"])
    points = []
    for i, first in enumerate(colors):
        if spec["mode"] == "breathing":
            low = tuple(round(c * spec["minimum"] / 100) for c in first)
            points.extend([(first, low), (low, colors[(i + 1) % len(colors)])])
        else:
            points.append((first, colors[(i + 1) % len(colors)]))
    duration = max(33, ticks // len(points))
    sections = [(first, final, duration) for first, final in points]
    # Shift the start within a ramp. One split section keeps the loop continuous.
    shift = round(spec["phase"] / 100 * duration * len(sections)) % (duration * len(sections))
    index, offset = divmod(shift, duration)
    if offset:
        first, final, length = sections[index]
        initial = tuple(round(a + (b - a) * offset / length) for a, b in zip(first, final))
        sections = [(initial, final, length - offset)] + sections[index + 1:] + sections[:index] + [(first, initial, offset)]
    else:
        sections = sections[index:] + sections[:index]
    data = bytearray(151)
    for i, (first, final, length) in enumerate(sections):
        # Firmware's signed channel step is fixed-point /16, at most 127 per tick.
        length = max(33, length)
        delta = [int((b - a) * 16 / length) & 255 for a, b in zip(first, final)]
        data[8*i:8*i+8] = bytes(delta + [0]) + struct.pack("<HBB", length, (i + 1) % len(sections), 0)
    direction = spec["direction"]
    wave = spec["mode"] == "wave"
    x_scale = int(wave and direction not in ("up", "down"))
    y_scale = int(wave and direction not in ("left", "right"))
    # The firmware uses its own physical key-position table for propagation.
    data[128:] = struct.pack("<HHHBBHHHHHHHB", *(c * 16 for c in sections[0][0]), 255, 0,
                            0, 0,
                            x_scale, y_scale, round(spec["spacing"]) if wave else 0,
                            len(sections), sum(max(33, s[2]) for s in sections),
                            int(direction in ("left", "up", "inward", "counterclockwise")))
    return bytes(data)


def onboard_programs(profile):
    programs, assigned = [], {}
    if not profile["enabled"] or not profile["brightness"]:
        return programs, assigned
    slots = {}
    for code in profile["colors"]:
        if resolved(profile, code)["mode"] not in ANIMATED:
            continue
        data = program(code, profile)
        if data not in slots:
            if len(slots) == MAX_PROGRAMS:
                raise ValueError("The keyboard supports 14 different animated settings at once. Share settings between keys or groups.")
            slots[data] = len(slots)
            report = bytearray(525)
            # Direct KLC command, verified on this Stealth 14. The older nested
            # [0,12,0,11,...] header did not upload a program on this controller.
            report[:5] = bytes([0, 11, 0, slots[data], 0])
            report[5:156] = data
            programs.append(report)
        assigned[code] = slots[data]
    return programs, assigned
