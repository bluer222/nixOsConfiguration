"""Static RGB control for the Stealth 14 Studio's SteelSeries KLC, interface 0.

Packet format follows OpenRGB's MSILaptopController and the protocol notes at
https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/tree/master/keyboard-rgb
Only RAM lighting settings and effect programs are sent. No firmware or flash writes.
"""

import argparse
import fcntl
import os
from pathlib import Path
import re
import time



# Include all addresses from the successful whole-keyboard test, including
# regional-layout keys which may not have a button in the US preview.
KEY_GROUPS = [
    [41, 43, 53, 57, 101, 224, 225, 240, 74, 77, 4, 20, 22, 26, 29, 30, 31, 58, 59],
    [226, 6, 7, 8, 9, 10, 21, 23, 25, 27, 32, 33, 34, 60, 61, 62],
    [44, 5, 11, 12, 13, 14, 16, 17, 24, 28, 35, 36, 37, 63, 64, 65, 66],
    [45, 47, 51, 52, 54, 55, 56, 227, 230, 100, 15, 18, 19, 38, 39, 67, 68, 69],
    [42, 46, 48, 228, 229, 40, 49, 70, 71, 72, 80, 81, 82],
    [73, 75, 76, 78, 79, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 102],
]
REPORT_KEYS = sorted({key for group in KEY_GROUPS for key in group} | {50})


def color(value):
    if not isinstance(value, str) or not re.fullmatch(r"#?[0-9a-fA-F]{6}", value):
        raise ValueError("Enter six hex digits, such as #FF8040.")
    return "#" + value.lstrip("#").upper()


def find_device(sysfs=Path("/sys/class/hidraw"), devices=Path("/dev")):
    for entry in sorted(sysfs.glob("hidraw*")):
        try:
            hid = entry / "device"
            if "HID_ID=0003:00001038:0000113A" not in (hid / "uevent").read_text().splitlines():
                continue
            if (hid.resolve().parent / "bInterfaceNumber").read_text().strip() == "00":
                return devices / entry.name
        except OSError:
            continue
    raise FileNotFoundError("The SteelSeries KLC keyboard is not connected.")


def make_report(colors, brightness, enabled=True, partial=False):
    if type(brightness) is not int or not 0 <= brightness <= 100:
        raise ValueError("Brightness must be between 0 and 100.")
    if type(enabled) is not bool:
        raise ValueError("Lighting must be on or off.")
    if not colors or not set(colors) <= set(REPORT_KEYS) or not partial and set(colors) != set(REPORT_KEYS):
        raise ValueError("The profile must contain every keyboard key.")
    report = bytearray(525)
    # The leading zero is the HID report ID; the 524-byte payload follows.
    report[1:5] = bytes([0x0C, 0, len(colors), 0])
    for i in range(130):
        report[5 + 4 * i] = 0xFF
    scale = brightness / 100 if enabled else 0
    for i, code in enumerate(sorted(colors)):
        rgb = bytes.fromhex(color(colors[code])[1:])
        report[5 + 4 * i:9 + 4 * i] = bytes([code, *(round(channel * scale) for channel in rgb)])
    return report


def make_group_reports(colors, brightness, enabled=True, reactive=False, fade_ms=750, key_reactive=None, key_effects=None):
    make_report(colors, brightness, enabled)
    if type(reactive) is not bool or type(fade_ms) is not int or not 50 <= fade_ms <= 2000:
        raise ValueError("Fade time must be between 50 and 2000 ms.")
    key_reactive = key_reactive or {}
    if not isinstance(key_reactive, dict) or not set(key_reactive) <= set(REPORT_KEYS):
        raise ValueError("Unknown reactive key.")
    for entry in key_reactive.values():
        if not isinstance(entry, dict) or type(entry.get("fade_ms")) is not int or not 50 <= entry["fade_ms"] <= 2000:
            raise ValueError("Invalid per-key fade time.")
        color(entry.get("hit_color"))
    key_effects = {} if key_effects is None else key_effects
    if not isinstance(key_effects, dict) or not set(key_effects) <= set(REPORT_KEYS):
        raise ValueError("Unknown onboard effect key.")
    if set(key_reactive) & set(key_effects) or any(type(slot) is not int or not 0 <= slot < 14 for slot in key_effects.values()):
        raise ValueError("Invalid onboard effect slot or overlapping key assignments.")
    reports = []
    scale = brightness / 100 if enabled else 0
    # Each entry contains base RGB, hit RGB, fade time, effect index, mask,
    # lock mask, and HID usage. The keyboard handles keypresses itself.
    for group in KEY_GROUPS + [[50]]:
        report = bytearray(525)
        report[1], report[3] = 0x0E, len(group)
        for i, code in enumerate(group):
            base = 5 + 12 * i
            rgb = bytes.fromhex(color(colors[code])[1:])
            report[base:base + 3] = bytes(round(channel * scale) for channel in rgb)
            entry = key_reactive.get(code)
            hit = bytes.fromhex(color(entry["hit_color"])[1:]) if entry else (0, 0, 0)
            report[base + 3:base + 6] = bytes(round(channel * scale) for channel in hit)
            report[base + 6:base + 8] = (entry["fade_ms"] if entry else fade_ms).to_bytes(2, "little")
            report[base + 8] = key_effects.get(code, 0)
            report[base + 9] = 0 if code in key_effects and enabled else 8 if (entry or reactive) and enabled else 1
            report[base + 11] = code
        reports.append(report)
    return reports


def apply(colors, brightness, enabled=True, reactive=False, fade_ms=750, key_reactive=None, key_effects=None, effect_reports=()):
    groups = make_group_reports(colors, brightness, enabled, reactive, fade_ms, key_reactive, key_effects)
    for report in effect_reports:
        if len(report) != 525 or report[:3] != bytes([0, 11, 0]) or not 0 <= report[3] < 14 or report[4] != 0:
            raise ValueError("Invalid onboard effect upload.")
    if len(effect_reports) > 14:
        raise ValueError("Too many onboard effect programs.")
    reports = [*effect_reports, *groups]
    device = find_device()
    try:
        fd = os.open(device, os.O_RDWR | os.O_CLOEXEC)
    except PermissionError as exc:
        raise PermissionError(f"Keyboard access is needed. Run: sudo setfacl -m u:{os.getuid()}:rw {device}") from exc
    try:
        for report in reports:
            request = (3 << 30) | (len(report) << 16) | (ord("H") << 8) | 6
            if fcntl.ioctl(fd, request, report, True) != len(report):
                raise OSError("The controller did not accept the complete color report.")
            time.sleep(0.01)
        commit = bytes([0, 0x0D, 0, 2]) + bytes(60)
        if os.write(fd, commit) != len(commit):
            raise OSError("The controller did not accept the apply command.")
    finally:
        os.close(fd)
    return device



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Set the Stealth 14 keyboard lighting.")
    parser.add_argument("--color", required=True, type=color)
    parser.add_argument("--brightness", type=int, default=70)
    parser.add_argument("--reactive", action="store_true", help="Go dark on keypress, then fade back")
    parser.add_argument("--fade-ms", type=int, default=750)
    args = parser.parse_args()
    try:
        print("Applied to", apply({code: args.color for code in REPORT_KEYS}, args.brightness,
                                  reactive=args.reactive, fade_ms=args.fade_ms))
    except (OSError, ValueError) as exc:
        parser.exit(1, f"{exc}\n")
