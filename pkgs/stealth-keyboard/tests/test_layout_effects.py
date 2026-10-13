import unittest

import effects
import layout


class LayoutTests(unittest.TestCase):
    def test_physical_layout(self):
        keys = layout.BY_CODE
        self.assertEqual(len(keys), 83)
        self.assertEqual([keys[c].x for c in (224, 240, 227, 226)], sorted(keys[c].x for c in (224, 240, 227, 226)))
        self.assertTrue(keys[230].x < keys[100].x < keys[228].x)
        for c in (79, 80, 81, 82):
            self.assertEqual(keys[c].width, 1)
            self.assertEqual(keys[c].height, 0.5)
        self.assertEqual(keys[75].x, keys[80].x)
        self.assertEqual(keys[78].x, keys[79].x)
        self.assertEqual(keys[75].y + keys[75].height, keys[80].y)
        self.assertEqual(keys[78].y + keys[78].height, keys[79].y)
        self.assertNotIn(74, keys)
        self.assertNotIn(77, keys)
        self.assertNotIn(73, keys)
        self.assertTrue(keys[69].x < keys[70].x < keys[76].x)
        for c in range(58, 70):
            self.assertEqual(keys[c].height, 0.5)

    def test_entire_board_scales_uniformly_and_fits(self):
        base = layout.rectangles(layout.NATURAL_WIDTH, layout.NATURAL_HEIGHT)
        for factor in (0.5, 0.8, 1.5):
            width, height = layout.NATURAL_WIDTH * factor, layout.NATURAL_HEIGHT * factor
            scaled = layout.rectangles(width, height)
            for code, rectangle in base.items():
                for actual, original in zip(scaled[code], rectangle):
                    self.assertAlmostEqual(actual, original * factor)
                x, y, w, h = scaled[code]
                self.assertTrue(0 <= x < x + w <= width)
                self.assertTrue(0 <= y < y + h <= height)

    def test_labels_contrast_on_dark_blue_and_bright_colors(self):
        self.assertEqual(layout.text_color((18, 52, 86)), "#FFFFFF")
        self.assertEqual(layout.text_color((0, 0, 255)), "#FFFFFF")
        self.assertEqual(layout.text_color((0, 0, 0)), "#FFFFFF")
        self.assertEqual(layout.text_color((255, 255, 255)), "#000000")
        self.assertEqual(layout.text_color((0, 255, 255)), "#000000")


class EffectTests(unittest.TestCase):
    def setUp(self):
        self.colors = {4: "#FFFFFF", 44: "#123456", 79: "#FF0000"}

    def test_breathing_preserves_palette_and_repeats(self):
        self.assertEqual(effects.frame(self.colors, "breathing", 0), self.colors)
        self.assertEqual(set(effects.frame(self.colors, "breathing", 0.5).values()), {"#000000"})
        self.assertEqual(effects.frame(self.colors, "breathing", 1), self.colors)
        self.assertEqual(effects.frame(self.colors, "breathing", 0.25)[44], "#091A2B")

    def test_wave_moves_and_repeats_without_changing_base_colors(self):
        original = dict(self.colors)
        frame = effects.frame(self.colors, "wave", 0)
        self.assertNotEqual(frame[4], frame[79])
        self.assertNotEqual(frame, effects.frame(self.colors, "wave", 0.25))
        self.assertEqual(frame, effects.frame(self.colors, "wave", 1))
        self.assertEqual(original, self.colors)

    def test_validate_period_and_effect(self):
        for mode, period in [("unknown", 3000), ("wave", 0), ("wave", 30001), ("breathing", True)]:
            with self.assertRaises(ValueError):
                effects.validate(mode, period)


if __name__ == "__main__":
    unittest.main()
