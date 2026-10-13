import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import keyboard


class KeyboardTests(unittest.TestCase):
    def setUp(self):
        self.colors = {code: "#FF8040" for code in keyboard.REPORT_KEYS}

    def test_wire_format_and_brightness(self):
        report = keyboard.make_report(self.colors, 50)
        self.assertEqual(len(report), 525)
        self.assertEqual(report[:5], bytes([0, 12, 0, len(keyboard.REPORT_KEYS), 0]))
        for i, code in enumerate(keyboard.REPORT_KEYS):
            self.assertEqual(report[5 + 4 * i:9 + 4 * i], bytes([code, 128, 64, 32]))
        for i in range(len(keyboard.REPORT_KEYS), 130):
            self.assertEqual(report[5 + 4 * i:9 + 4 * i], bytes([255, 0, 0, 0]))

    def test_off_preserves_key_addresses(self):
        report = keyboard.make_report(self.colors, 80, False)
        for i, code in enumerate(keyboard.REPORT_KEYS):
            self.assertEqual(report[5 + 4 * i:9 + 4 * i], bytes([code, 0, 0, 0]))

    def test_invalid_values_never_open_device(self):
        with patch("keyboard.os.open") as opened:
            for brightness in (-1, 101, True):
                with self.assertRaises(ValueError):
                    keyboard.apply(self.colors, brightness)
            self.colors[4] = "#GGGGGG"
            with self.assertRaises(ValueError):
                keyboard.apply(self.colors, 70)
            opened.assert_not_called()

    def test_profile_roundtrip_and_reject_incomplete_profile(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "profile.json"
            keyboard.save_profile(self.colors, 42, False, True, 1200, path)
            self.assertEqual(keyboard.load_profile(path), (self.colors, 42, False, True, 1200))
            path.write_text(json.dumps({"colors": {}, "brightness": 70, "enabled": True}))
            with self.assertRaises(ValueError):
                keyboard.load_profile(path)

    def test_reactive_fields_and_static_reset(self):
        reports = keyboard.make_group_reports(self.colors, 50, reactive=True, fade_ms=750)
        actual = {}
        for report in reports:
            self.assertEqual(report[1], 14)
            for i in range(report[3]):
                entry = report[5 + 12 * i:17 + 12 * i]
                self.assertEqual(entry[:11], bytes([128, 64, 32, 0, 0, 0, 238, 2, 0, 8, 0]))
                actual[entry[11]] = True
        self.assertEqual(set(actual), set(keyboard.REPORT_KEYS))
        for report in keyboard.make_group_reports(self.colors, 100, reactive=False):
            for i in range(report[3]):
                self.assertEqual(report[14 + 12 * i], 1)

    def test_only_lighting_interface_is_detected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sysfs = root / "hidraw"
            for number, interface, identity in [(0, "01", "1038:113A"), (1, "00", "1038:113A"), (2, "00", "0001:0002")]:
                entry = sysfs / f"hidraw{number}"
                entry.mkdir(parents=True)
                parent = root / f"interface{number}"
                device = parent / "hid"
                device.mkdir(parents=True)
                (device / "uevent").write_text("HID_ID=0003:0000" + identity.replace(":", ":0000") + "\n")
                (parent / "bInterfaceNumber").write_text(interface)
                (entry / "device").symlink_to(device)
            self.assertEqual(keyboard.find_device(sysfs, root / "dev"), root / "dev/hidraw1")


if __name__ == "__main__":
    unittest.main()
