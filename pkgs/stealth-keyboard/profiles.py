"""Validated, atomic profile storage, including migration of earlier versions."""

import copy
import json
import os
from pathlib import Path
import re
import tempfile

import effects
import keyboard


DIRECTORY = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "stealth-keyboard"
CURRENT = DIRECTORY / "profile.json"
SAVED = DIRECTORY / "profiles"
MAX_BYTES = 512 * 1024


def key_code(value):
    if type(value) is int or isinstance(value, str) and re.fullmatch(r"[0-9]+", value):
        return int(value)
    raise ValueError("Invalid key address.")


def default():
    return {"version": 4, "colors": {code: "#FFFFFF" for code in keyboard.REPORT_KEYS},
            "brightness": 100, "enabled": True, "effect": effects.settings("reactive"),
            "key_effects": {}}


def profile_effect(value, version):
    if version < 4 and isinstance(value, dict) and value.get("mode") in effects.REMOVED_MODES:
        # Keep the old base colors and the native fallback; never resume streaming.
        value = dict(value, mode="reactive" if value.get("restore_reactive", False) else "static")
    if version < 4 and isinstance(value, dict) and value.get("mode") in effects.ANIMATED:
        period = value.get("period_ms", 3000)
        if type(period) is not int or not 100 <= period <= 120000:
            raise ValueError("Invalid legacy effect period.")
        value = dict(value, speed=round(max(1, min(100, 30000 / period))))
        if isinstance(value.get("palette"), list):
            value["palette"] = value["palette"][:effects.palette_limit(value["mode"])]
        if value["mode"] == "wave" and value.get("direction") in ("clockwise", "counterclockwise"):
            value["direction"] = "outward"
    return effects.normalize(value)


def validate(data):
    if not isinstance(data, dict) or not isinstance(data.get("colors"), dict):
        raise ValueError("The profile must contain a colors object.")
    if type(data.get("version", 1)) is not int or not 1 <= data.get("version", 1) <= 4:
        raise ValueError("Unsupported profile version.")
    try:
        colors = {key_code(code): effects.color(value) for code, value in data["colors"].items()}
    except (ValueError, TypeError) as exc:
        raise ValueError("The profile has an invalid key or color.") from exc
    if len(colors) != len(data["colors"]) or set(colors) != set(keyboard.REPORT_KEYS):
        raise ValueError("The profile must contain all known keyboard keys.")
    brightness = data.get("brightness")
    if type(brightness) is not int or not 0 <= brightness <= 100:
        raise ValueError("Brightness must be between 0 and 100.")
    if type(data.get("enabled")) is not bool:
        raise ValueError("enabled must be true or false.")
    if "effect" in data:
        spec = profile_effect(data["effect"], data.get("version", 1))
    else:
        mode = data.get("animation", "none")
        if mode not in ("none", "wave", "breathing"):
            raise ValueError("Unknown legacy timed effect.")
        if type(data.get("reactive", False)) is not bool:
            raise ValueError("Reactive must be true or false.")
        spec = effects.settings("reactive" if mode == "none" and data.get("reactive") else "static" if mode == "none" else mode)
        spec.update(fade_ms=data.get("fade_ms", 750), restore_reactive=data.get("reactive", False), period_ms=data.get("period_ms", 3000))
        spec = profile_effect(spec, 1)
    overrides = data.get("key_effects", {})
    if not isinstance(overrides, dict) or len(overrides) > len(colors):
        raise ValueError("Invalid per-key effects.")
    key_effects = {}
    for value, entry in overrides.items():
        try:
            code = key_code(value)
        except (TypeError, ValueError) as exc:
            raise ValueError("Invalid effect key.") from exc
        if code not in colors or code in key_effects:
            raise ValueError("An effect refers to an unknown or duplicate key.")
        key_effects[code] = profile_effect(entry, data.get("version", 1))
    return {"version": 4, "colors": colors, "brightness": brightness, "enabled": data["enabled"],
            "effect": spec, "key_effects": key_effects}


def load(path=CURRENT):
    path = Path(path)
    with path.open("rb") as file:
        raw = file.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise ValueError("The profile is too large.")
    return validate(json.loads(raw))


def current():
    try:
        return load()
    except FileNotFoundError:
        return default()


def save(profile, path=CURRENT):
    data = validate(profile)
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile("w", dir=path.parent, prefix=".profile-", delete=False) as file:
            temporary = Path(file.name)
            json.dump(data, file, indent=2)
            file.write("\n")
            file.flush()
            os.fsync(file.fileno())
        temporary.replace(path)
    finally:
        if temporary and temporary.exists():
            temporary.unlink()


def named_path(name, directory=SAVED):
    name = name.strip()
    if not re.fullmatch(r"[\w][\w .-]{0,63}", name):
        raise ValueError("Use a profile name of 1 to 64 letters, numbers, spaces, dots, or hyphens.")
    return Path(directory) / (name + ".json")


def names(directory=SAVED):
    return sorted(path.stem for path in Path(directory).glob("*.json"))


def set_effect(profile, spec, keys=()):
    spec = effects.normalize(spec)
    if keys:
        if not set(keys) <= set(profile["colors"]):
            raise ValueError("Unknown effect key.")
        for code in keys:
            profile["key_effects"][code] = copy.deepcopy(spec)
    else:
        profile["effect"] = spec
