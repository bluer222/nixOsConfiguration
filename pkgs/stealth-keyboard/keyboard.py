"""Static RGB control for the Stealth 14 Studio's SteelSeries KLC, interface 0.

Packet format follows OpenRGB's MSILaptopController and the protocol notes at
https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/tree/master/keyboard-rgb
Only RAM color reports are sent. No firmware, effect-program, or flash writes.
"""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import time


# Labels use the US layout. HID usages remain the same on other layouts.
ROWS = [
    [("Esc", 41, 1)] + [(f"F{i + 1}", 58 + i, 1) for i in range(12)]
    + [("Del", 76, 1), ("Power", 102, 1)],
    [("`", 53, 1)] + [(str((i + 1) % 10), 30 + i, 1) for i in range(10)]
    + [("−", 45, 1), ("=", 46, 1), ("Backspace", 42, 2), ("Ins", 73, 1)],
    [("Tab", 43, 1.5)]
    + [(label, code, 1) for label, code in zip("QWERTYUIOP", [20, 26, 8, 21, 23, 28, 24, 12, 18, 19])]
    + [("[", 47, 1), ("]", 48, 1), ("\\", 49, 1.5), ("PgUp", 75, 1)],
    [("Caps", 57, 1.75)]
    + [(label, code, 1) for label, code in zip("ASDFGHJKL", [4, 22, 7, 9, 10, 11, 13, 14, 15])]
    + [(";", 51, 1), ("'", 52, 1), ("Enter", 40, 2.25), ("PgDn", 78, 1)],
    [("Shift", 225, 2)]
    + [(label, code, 1) for label, code in zip("ZXCVBNM", [29, 27, 6, 25, 5, 17, 16])]
    + [(",", 54, 1), (".", 55, 1), ("/", 56, 1), ("Shift", 229, 2), ("↑", 82, 1), ("End", 77, 1)],
    [("Ctrl", 224, 1.5), ("Super", 227, 1.25), ("Alt", 226, 1.25), ("Space", 44, 6),
     ("Alt", 230, 1), ("Fn", 240, 1), ("Ctrl", 228, 1), ("←", 80, 1), ("↓", 81, 1), ("→", 79, 1)],
]
VISIBLE_KEYS = {code for row in ROWS for _, code, _ in row}
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
CONFIG_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "stealth-keyboard/profile.json"


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


def make_report(colors, brightness, enabled=True):
    if type(brightness) is not int or not 0 <= brightness <= 100:
        raise ValueError("Brightness must be between 0 and 100.")
    if type(enabled) is not bool:
        raise ValueError("Lighting must be on or off.")
    if set(colors) != set(REPORT_KEYS):
        raise ValueError("The profile must contain every keyboard key.")
    report = bytearray(525)
    # The leading zero is the HID report ID; the 524-byte payload follows.
    report[1:5] = bytes([0x0C, 0, len(REPORT_KEYS), 0])
    for i in range(130):
        report[5 + 4 * i] = 0xFF
    scale = brightness / 100 if enabled else 0
    for i, code in enumerate(REPORT_KEYS):
        rgb = bytes.fromhex(color(colors[code])[1:])
        report[5 + 4 * i:9 + 4 * i] = bytes([code, *(round(channel * scale) for channel in rgb)])
    return report


def make_group_reports(colors, brightness, enabled=True, reactive=False, fade_ms=750):
    make_report(colors, brightness, enabled)
    if type(reactive) is not bool or type(fade_ms) is not int or not 50 <= fade_ms <= 2000:
        raise ValueError("Fade time must be between 50 and 2000 ms.")
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
            report[base + 6:base + 8] = fade_ms.to_bytes(2, "little")
            report[base + 9] = 8 if reactive and enabled else 1
            report[base + 11] = code
        reports.append(report)
    return reports


def apply(colors, brightness, enabled=True, reactive=False, fade_ms=750):
    reports = make_group_reports(colors, brightness, enabled, reactive, fade_ms)
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


def load_profile(path=CONFIG_PATH):
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        return {code: "#FFFFFF" for code in REPORT_KEYS}, 100, True, True, 750
    if not isinstance(data, dict) or not isinstance(data.get("colors"), dict):
        raise ValueError("The saved keyboard profile is invalid.")
    colors = {int(code): color(value) for code, value in data["colors"].items()}
    brightness, enabled = data.get("brightness"), data.get("enabled")
    reactive, fade_ms = data.get("reactive", False), data.get("fade_ms", 750)
    make_group_reports(colors, brightness, enabled, reactive, fade_ms)
    return colors, brightness, enabled, reactive, fade_ms


def save_profile(colors, brightness, enabled, reactive=False, fade_ms=750, path=CONFIG_PATH):
    make_group_reports(colors, brightness, enabled, reactive, fade_ms)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps({"colors": colors, "brightness": brightness, "enabled": enabled,
                                     "reactive": reactive, "fade_ms": fade_ms}, indent=2) + "\n")
    temporary.replace(path)


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
