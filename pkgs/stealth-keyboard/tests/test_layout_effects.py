import unittest

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


if __name__ == "__main__":
    unittest.main()
