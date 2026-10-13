import copy
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

import controller
import effects
import keyboard
import profiles


class OnboardTests(unittest.TestCase):
    def setUp(self):
        self.profile = profiles.default()

    def test_cycle_matches_hardware_verified_vector_and_direct_upload(self):
        self.profile['key_effects'][26] = dict(effects.settings('cycle'), palette=['#FF0000', '#00FF00'], speed=100)
        data = effects.program(26, self.profile)
        self.assertEqual(data[:16], bytes([175, 81, 0, 0, 50, 0, 1, 0, 81, 175, 0, 0, 50, 0, 0, 0]))
        self.assertEqual(data[16:128], bytes(112))
        self.assertEqual(data[128:136], struct.pack('<HHHBB', 4080, 0, 0, 255, 0))
        self.assertEqual(data[146:151], bytes([2, 0, 100, 0, 0]))
        reports, assigned = effects.onboard_programs(self.profile)
        self.assertEqual(assigned, {26: 0})
        self.assertEqual(reports[0][:5], bytes([0, 11, 0, 0, 0]))
        self.assertEqual(reports[0][5:156], data)
        self.assertEqual(reports[0][156:], bytes(369))

    def test_breathing_matches_hardware_verified_vector_and_adjustable_floor(self):
        self.profile['colors'][4] = '#0000FF'
        self.profile['key_effects'][4] = dict(effects.settings('breathing'), speed=100)
        data = effects.program(4, self.profile)
        self.assertEqual(data[:16], bytes([0, 0, 175, 0, 50, 0, 1, 0, 0, 0, 81, 0, 50, 0, 0, 0]))
        self.assertEqual(data[128:136], struct.pack('<HHHBB', 0, 0, 4080, 255, 0))
        self.profile['key_effects'][4]['minimum'] = 50
        data = effects.program(4, self.profile)
        self.assertEqual((data[2], data[10]), ((-40) & 255, 40))

    def test_wave_program_uses_onboard_spatial_propagation(self):
        self.profile['effect'] = effects.settings('wave')
        self.assertEqual(effects.program(26, self.profile)[140:146], struct.pack('<HHH', 1, 0, 100))
        self.profile['effect']['direction'] = 'up'
        data = effects.program(26, self.profile)
        self.assertEqual(data[140:146], struct.pack('<HHH', 0, 1, 100))
        self.assertEqual(data[150], 1)
        reports, assigned = effects.onboard_programs(self.profile)
        self.assertEqual(len(reports), 1)
        self.assertEqual(set(assigned), set(keyboard.REPORT_KEYS))

    def test_shared_settings_reuse_slots_and_independent_speeds_get_separate_slots(self):
        profiles.set_effect(self.profile, dict(effects.settings('cycle'), palette=['#FF0000', '#00FF00']), {4, 26})
        reports, assigned = effects.onboard_programs(self.profile)
        self.assertEqual(len(reports), 1)
        self.assertEqual(assigned[4], assigned[26])
        self.profile['key_effects'][26]['speed'] = 20
        reports, assigned = effects.onboard_programs(self.profile)
        self.assertEqual(len(reports), 2)
        self.assertNotEqual(assigned[4], assigned[26])

    def test_slot_capacity_is_checked_before_hardware_access(self):
        self.profile['effect'] = dict(effects.settings('cycle'), palette=['#FF0000', '#00FF00'])
        for i, code in enumerate(keyboard.REPORT_KEYS[:15]):
            self.profile['key_effects'][code] = dict(self.profile['effect'], speed=i+1)
        with patch('keyboard.os.open') as opened:
            with self.assertRaisesRegex(ValueError, '14 different'):
                controller.apply(self.profile)
            opened.assert_not_called()

    def test_phase_changes_initial_state_and_preserves_a_closed_loop(self):
        self.profile['key_effects'][26] = dict(effects.settings('cycle'), palette=['#FF0000', '#0000FF'], phase=25, speed=100)
        data = effects.program(26, self.profile)
        self.assertEqual(struct.unpack_from('<HHH', data, 128), (128*16, 0, 128*16))
        count = struct.unpack_from('<H', data, 146)[0]
        self.assertEqual(count, 3)
        self.assertEqual(data[(count-1)*8+6], 0)
        self.assertEqual(effects.base_frame(self.profile)[26], '#800080')

    def test_brightness_is_baked_into_palette(self):
        self.profile['brightness'] = 50
        self.profile['key_effects'][26] = dict(effects.settings('cycle'), palette=['#FF0000', '#00FF00'], maximum=50)
        self.assertEqual(struct.unpack_from('<HHH', effects.program(26, self.profile), 128), (64*16, 0, 0))
        self.profile['enabled'] = False
        self.assertEqual(effects.onboard_programs(self.profile), ([], {}))

    def test_program_tables_are_bounded_at_all_palette_limits(self):
        for mode in effects.ANIMATED:
            for phase in (0, 1, 25, 50, 99, 100):
                for speed in (1, 50, 100):
                    self.profile['effect'] = dict(effects.settings(mode), phase=phase, speed=speed,
                                                palette=(effects.RAINBOW*2)[:effects.palette_limit(mode)])
                    before = copy.deepcopy(self.profile)
                    data = effects.program(4, self.profile)
                    self.assertEqual(len(data), 151)
                    count = struct.unpack_from('<H', data, 146)[0]
                    self.assertLessEqual(count, 16)
                    for i in range(count):
                        self.assertGreaterEqual(struct.unpack_from('<H', data, i*8+4)[0], 33)
                        self.assertLess(data[i*8+6], count)
                    self.assertEqual(before, self.profile)

    def test_invalid_effects_and_palette_overflows_are_rejected(self):
        for change in ({'mode': 'scanner'}, {'speed': float('nan')}, {'speed': True}, {'speed': 0},
                       {'phase': True}, {'palette': ['invalid']},
                       {'mode': 'breathing', 'palette': ['#FFFFFF']*8}, {'mode': 'wave', 'direction': 'clockwise'}):
            with self.assertRaises(ValueError):
                effects.normalize(dict(effects.settings(), **change))

    def test_static_gradient_is_a_one_time_color_frame(self):
        self.profile['effect'] = dict(effects.settings('gradient'), palette=['#FF0000', '#0000FF'])
        self.assertNotEqual(effects.base_frame(self.profile)[4], effects.base_frame(self.profile)[79])
        self.assertEqual(effects.onboard_programs(self.profile), ([], {}))

    def test_one_shot_apply_sends_programs_then_groups_then_commit_and_closes(self):
        profiles.set_effect(self.profile, dict(effects.settings('cycle'), palette=['#FF0000', '#00FF00'], speed=100), {26})
        before = copy.deepcopy(self.profile)
        with patch('keyboard.find_device', return_value=Path('/dev/hidraw0')), \
             patch('keyboard.os.open', return_value=123), patch('keyboard.os.close') as closed, \
             patch('keyboard.fcntl.ioctl', side_effect=lambda fd, req, report, mutate: len(report)) as sent, \
             patch('keyboard.os.write', return_value=64) as commit, patch('keyboard.time.sleep'):
            controller.apply(self.profile)
            frames = [call.args[2] for call in sent.call_args_list]
            self.assertEqual(len(frames), 8)
            self.assertEqual(frames[0][:5], bytes([0, 11, 0, 0, 0]))
            self.assertTrue(all(frame[1] == 14 for frame in frames[1:]))
            entries = {r[16+i*12]: r[5+i*12:17+i*12] for r in frames[1:] for i in range(r[3])}
            self.assertEqual(entries[26][8:10], bytes([0, 0]))
            self.assertEqual(entries[4][9], 8)
            commit.assert_called_once_with(123, bytes([0, 13, 0, 2])+bytes(60))
            closed.assert_called_once_with(123)
        self.assertEqual(self.profile, before)
        self.assertFalse(hasattr(keyboard, 'stream'))
        self.assertFalse(hasattr(controller, 'run'))

    def test_invalid_effect_uploads_are_rejected_before_opening_device(self):
        with patch('keyboard.os.open') as opened:
            for report in (bytes(524), bytes([0, 9, 0, 0, 0])+bytes(520), bytes([0, 11, 0, 14, 0])+bytes(520)):
                with self.assertRaises(ValueError):
                    keyboard.apply(self.profile['colors'], 100, effect_reports=[report])
            with self.assertRaises(ValueError):
                keyboard.apply(self.profile['colors'], 100, key_effects={26: 14})
            with self.assertRaises(ValueError):
                controller.apply(dict(self.profile, brightness=101))
            opened.assert_not_called()


class NativeProfilesTests(unittest.TestCase):
    def test_old_profiles_migrate_to_native_effects_and_drop_background_flags(self):
        profile = profiles.default()
        profile.update(version=3, keep_running=True)
        profile['effect'] = dict(effects.settings('wave'), period_ms=4500, cycles=2, delay_ms=500, restore_reactive=True)
        profile['colors'][4] = '#123456'
        profile['key_effects'][4] = dict(effects.settings(), mode='scanner', restore_reactive=True)
        result = profiles.validate(profile)
        self.assertEqual(result['version'], 4)
        self.assertEqual(result['effect']['mode'], 'wave')
        self.assertEqual(result['effect']['speed'], 7)
        self.assertEqual(result['key_effects'][4]['mode'], 'reactive')
        self.assertEqual(result['colors'][4], '#123456')
        self.assertNotIn('keep_running', result)
        self.assertNotIn('cycles', result['effect'])
        self.assertNotIn('delay_ms', result['effect'])

    def test_malformed_legacy_periods_are_rejected_cleanly(self):
        for period in (0, 'fast', True, float('nan')):
            profile = profiles.default()
            profile['version'] = 3
            profile['effect'] = dict(effects.settings('wave'), period_ms=period)
            with self.assertRaises(ValueError):
                profiles.validate(profile)

    def test_native_profile_roundtrip_and_failed_save_preserve_data(self):
        profile = profiles.default()
        profiles.set_effect(profile, dict(effects.settings('cycle'), palette=['#FF0000', '#0000FF'], phase=25, speed=75), {4, 26})
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)/'profile.json'
            profiles.save(profile, path)
            self.assertEqual(profiles.load(path), profile)
            self.assertEqual(list(Path(folder).glob('.profile-*')), [])
            before = path.read_bytes()
            with self.assertRaises(ValueError):
                profiles.save(dict(profile, brightness=-1), path)
            self.assertEqual(path.read_bytes(), before)

    def test_invalid_imports_and_large_files(self):
        for change in ({'brightness': True}, {'enabled': 'yes'}, {'version': 99}, {'key_effects': {999: effects.settings()}},
                       {'key_effects': {4.5: effects.settings()}}, {'key_effects': {True: effects.settings()}}, {'colors': {}}):
            with self.assertRaises(ValueError):
                profiles.validate(dict(profiles.default(), **change))
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)/'large.json'
            path.write_bytes(b'x'*(profiles.MAX_BYTES+1))
            with self.assertRaisesRegex(ValueError, 'too large'):
                profiles.load(path)

    def test_profile_names_cannot_escape_library(self):
        for name in ('../escape', '/etc/file', 'a/b', '', '..', 'x'*65):
            with self.assertRaises(ValueError):
                profiles.named_path(name)


if __name__ == '__main__':
    unittest.main()
