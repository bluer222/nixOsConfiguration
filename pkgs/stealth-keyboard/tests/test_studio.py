import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import controller
import effects
import keyboard
import profiles


class StudioEffectsTests(unittest.TestCase):
    def setUp(self):
        self.profile = profiles.default()

    def test_custom_palette_interpolates_and_wraps(self):
        palette = ["#FF0000", "#0000FF"]
        self.assertEqual(effects.hex_rgb(effects.palette_color(palette, 0)), "#FF0000")
        self.assertEqual(effects.hex_rgb(effects.palette_color(palette, 0.25)), "#800080")
        self.assertEqual(effects.hex_rgb(effects.palette_color(palette, 0.5)), "#0000FF")
        self.assertEqual(effects.hex_rgb(effects.palette_color(palette, 1)), "#FF0000")

    def test_keys_have_independent_periods_phases_and_modes(self):
        self.profile["effect"] = effects.settings("static")
        fast = effects.settings("breathing")
        fast["period_ms"] = 1000
        slow = copy.deepcopy(fast)
        slow["period_ms"] = 2000
        self.profile["key_effects"] = {4: fast, 26: slow}
        colors = effects.render(self.profile, 0.5)
        self.assertEqual(colors[4], "#000000")
        self.assertEqual(colors[26], "#808080")
        self.assertEqual(colors[44], "#FFFFFF")
        self.profile["key_effects"][26] = dict(fast, phase=50)
        self.assertEqual(effects.render(self.profile, 0)[26], "#000000")

    def test_start_delay_repeat_count_and_restoration(self):
        spec = effects.settings("breathing")
        spec.update(period_ms=1000, delay_ms=500, cycles=2)
        self.profile["effect"] = spec
        self.assertEqual(effects.render(self.profile, 0.1)[4], "#FFFFFF")
        self.assertEqual(effects.render(self.profile, 1)[4], "#000000")
        self.assertTrue(effects.running(self.profile, 2.49))
        self.assertFalse(effects.running(self.profile, 2.5))
        self.assertEqual(effects.render(self.profile, 2.5)[4], "#FFFFFF")

    def test_native_hit_color_preview_and_independent_fade(self):
        self.profile["key_effects"][4] = dict(effects.settings("reactive"), hit_color="#FF0000", fade_ms=1000)
        self.assertEqual(effects.render(self.profile, 1, {4: 1})[4], "#FF0000")
        self.assertEqual(effects.render(self.profile, 1.5, {4: 1})[4], "#FF8080")
        self.assertEqual(effects.render(self.profile, 2, {4: 1})[4], "#FFFFFF")
        self.assertEqual(effects.render(self.profile, 1, {4: 1})[26], "#FFFFFF")

    def test_directions_reverse_axes_and_use_origin(self):
        spec = effects.settings("wave")
        self.assertAlmostEqual(effects.position(4, spec) + effects.position(4, dict(spec, direction="left")), 1)
        self.assertAlmostEqual(effects.position(4, dict(spec, direction="down"))
                               + effects.position(4, dict(spec, direction="up")), 1)
        radial = dict(spec, direction="outward")
        self.assertNotEqual(effects.position(4, radial), effects.position(4, dict(radial, origin_x=0)))

    def test_every_mode_produces_bounded_colors_without_changing_profile(self):
        for mode in effects.MODES:
            for direction in effects.DIRECTIONS:
                self.profile["effect"] = effects.settings(mode)
                self.profile["effect"].update(direction=direction, palette=["#00FF00", "#FF0000"], minimum=10, maximum=80)
                original = copy.deepcopy(self.profile)
                for elapsed in (0, 0.1, 1.5, 3, 100):
                    colors = effects.render(self.profile, elapsed)
                    self.assertEqual(set(colors), set(keyboard.REPORT_KEYS))
                    for value in colors.values():
                        self.assertEqual(value, effects.color(value))
                self.assertEqual(self.profile, original)

    def test_bad_settings_are_rejected(self):
        for change in ({"mode": "bogus"}, {"period_ms": float("nan")}, {"phase": True},
                       {"cycles": 1.5}, {"palette": ["#FFFFFF"] * 17}, {"palette": ["invalid"]},
                       {"minimum": 90, "maximum": 50}, {"direction": "sideways"}, {"restore_reactive": "yes"}):
            with self.assertRaises(ValueError):
                effects.normalize(dict(effects.settings(), **change))


class StudioProfileTests(unittest.TestCase):
    def test_migration_preserves_colors_brightness_and_native_restore(self):
        legacy = {"colors": {str(c): "#123456" for c in keyboard.REPORT_KEYS}, "brightness": 42,
                  "enabled": True, "reactive": True, "fade_ms": 1200, "animation": "wave", "period_ms": 4500}
        profile = profiles.validate(legacy)
        self.assertEqual(profile["effect"]["mode"], "wave")
        self.assertEqual(profile["effect"]["period_ms"], 4500)
        self.assertEqual(profile["effect"]["fade_ms"], 1200)
        self.assertTrue(profile["effect"]["restore_reactive"])
        self.assertEqual(set(profile["colors"].values()), {"#123456"})
        self.assertEqual(profile["brightness"], 42)

    def test_roundtrip_preserves_per_key_options_and_background_preference(self):
        profile = profiles.default()
        profiles.set_effect(profile, dict(effects.settings("wave"), palette=["#FF0000", "#0000FF"], phase=25, cycles=4), {4, 26})
        profile["keep_running"] = True
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "profile.json"
            profiles.save(profile, path)
            self.assertEqual(profiles.load(path), profile)
            self.assertEqual(list(Path(directory).glob(".profile-*")), [])

    def test_invalid_imports_and_large_files(self):
        for change in ({"brightness": True}, {"enabled": "yes"}, {"version": 99},
                       {"key_effects": {999: effects.settings()}}, {"key_effects": {4.5: effects.settings()}},
                       {"key_effects": {True: effects.settings()}}, {"colors": {}}):
            with self.assertRaises(ValueError):
                profiles.validate(dict(profiles.default(), **change))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "large.json"
            path.write_bytes(b"x" * (profiles.MAX_BYTES + 1))
            with self.assertRaisesRegex(ValueError, "too large"):
                profiles.load(path)

    def test_invalid_save_does_not_replace_existing_profile(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "profile.json"
            profiles.save(profiles.default(), path)
            original = path.read_bytes()
            with self.assertRaises(ValueError):
                profiles.save(dict(profiles.default(), brightness=-1), path)
            self.assertEqual(path.read_bytes(), original)

    def test_profile_names_cannot_escape_library(self):
        for name in ("../escape", "/etc/file", "a/b", "", "..", "x" * 65):
            with self.assertRaises(ValueError):
                profiles.named_path(name)
        self.assertEqual(profiles.named_path("Game night", Path("/tmp/library")), Path("/tmp/library/Game night.json"))


class StudioControllerTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.lock = Path(self.directory.name) / "controller.lock"

    def test_partial_reports_do_not_address_unselected_keys(self):
        report = keyboard.make_report({4: "#FF0000", 26: "#00FF00"}, 100, partial=True)
        self.assertEqual(report[:5], bytes([0, 12, 0, 2, 0]))
        self.assertEqual(report[5:13], bytes([4, 255, 0, 0, 26, 0, 255, 0]))
        self.assertTrue(all(report[5 + i * 4] == 255 for i in range(2, 130)))
        with self.assertRaises(ValueError):
            keyboard.make_report({999: "#FFFFFF"}, 100, partial=True)

    def test_per_key_native_packet_encodes_color_and_duration(self):
        colors = {c: "#FFFFFF" for c in keyboard.REPORT_KEYS}
        reports = keyboard.make_group_reports(colors, 50, key_reactive={4: {"hit_color": "#FF0000", "fade_ms": 1200}})
        entries = {report[16 + i * 12]: report[5 + i * 12:17 + i * 12]
                   for report in reports for i in range(report[3])}
        self.assertEqual(entries[4], bytes([128, 128, 128, 128, 0, 0, 176, 4, 0, 8, 0, 4]))
        self.assertEqual(entries[26][9], 1)

    def test_mixed_timed_and_native_keys_then_stop(self):
        profile = profiles.default()
        profiles.set_effect(profile, effects.settings("breathing"), {4, 26})
        ctl = controller.Controller(self.lock)
        with patch("keyboard.apply") as native, patch("keyboard.stream") as stream:
            ctl.apply(profile)
            self.assertEqual(set(native.call_args.kwargs["key_reactive"]), set(keyboard.REPORT_KEYS) - {4, 26})
            ctl.tick(1.5)
            self.assertEqual(set(stream.call_args.args[0]), {4, 26})
            self.assertEqual(set(stream.call_args.args[0].values()), {"#000000"})
            ctl.stop()
            self.assertFalse(ctl.codes)
            self.assertEqual(native.call_count, 2)

    def test_finite_animation_restores_native_fallback(self):
        profile = profiles.default()
        profile["effect"] = dict(effects.settings("breathing"), cycles=1, period_ms=1000, restore_reactive=True)
        ctl = controller.Controller(self.lock)
        with patch("keyboard.apply") as native, patch("keyboard.stream"):
            ctl.apply(profile)
            self.assertFalse(native.call_args.kwargs["key_reactive"])
            self.assertFalse(ctl.tick(1))
            self.assertEqual(set(native.call_args.kwargs["key_reactive"]), set(keyboard.REPORT_KEYS))

    def test_invalid_profile_never_touches_hardware(self):
        with patch("keyboard.apply") as native, patch("keyboard.stream") as stream:
            with self.assertRaises(ValueError):
                controller.Controller(self.lock).apply(dict(profiles.default(), brightness=101))
            native.assert_not_called()
            stream.assert_not_called()

    def test_completed_key_restores_reactivity_while_other_keys_keep_running(self):
        profile = profiles.default()
        profile["key_effects"][4] = dict(effects.settings("breathing"), cycles=1, period_ms=1000, restore_reactive=True)
        profile["key_effects"][26] = effects.settings("wave")
        ctl = controller.Controller(self.lock)
        with patch("keyboard.apply") as native, patch("keyboard.stream") as stream:
            ctl.apply(profile)
            self.assertTrue(ctl.tick(1))
            self.assertEqual(ctl.codes, {26})
            self.assertIn(4, native.call_args.kwargs["key_reactive"])
            self.assertNotIn(26, native.call_args.kwargs["key_reactive"])
            self.assertEqual(set(stream.call_args.args[0]), {26})
            ctl.stop()

    def test_applied_profile_is_a_snapshot(self):
        profile = profiles.default()
        profile["effect"] = effects.settings("wave")
        ctl = controller.Controller(self.lock)
        with patch("keyboard.apply"), patch("keyboard.stream"):
            ctl.apply(profile)
            profile["effect"]["direction"] = "left"
            profile["colors"][4] = "#FF0000"
            self.assertEqual(ctl.profile["effect"]["direction"], "right")
            self.assertEqual(ctl.profile["colors"][4], "#FFFFFF")
            ctl.stop()

    def test_second_controller_cannot_overwrite_active_effects(self):
        profile = profiles.default()
        profile["effect"] = effects.settings("wave")
        first, second = controller.Controller(self.lock), controller.Controller(self.lock)
        with patch("keyboard.apply") as native, patch("keyboard.stream"):
            first.apply(profile)
            with self.assertRaisesRegex(OSError, "Another"):
                second.apply(profile)
            self.assertEqual(native.call_count, 1)
            first.stop()
            second.apply(profile)
            second.stop()


if __name__ == "__main__":
    unittest.main()
