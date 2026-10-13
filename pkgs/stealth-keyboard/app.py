#!/usr/bin/env python3
"""Native GTK controls for the Stealth 14 Studio keyboard."""

import sys
import math
import time

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gsk", "4.0")
gi.require_version("Graphene", "1.0")
gi.require_version("Pango", "1.0")
from gi.repository import Gdk, GLib, Graphene, Gsk, Gtk, Pango

import keyboard
import effects
import layout


PRESETS = [("Warm white", "#FFDDB0"), ("White", "#FFFFFF"), ("Ice", "#72D8FF"),
           ("Mint", "#72FFC5"), ("Rose", "#FF80AE"), ("Red", "#FF3838")]
CSS = b"""
window { background: #11151c; color: #e6edf6; }
.content { font-family: sans-serif; }
.title { font-size: 26px; font-weight: 700; }
.muted { color: #9baabd; }
.section { font-size: 16px; font-weight: 600; }
.keyboard { background: #1b222d; border-radius: 16px; }
button { border-radius: 9px; padding: 7px 12px; }
button.key { padding: 0; min-width: 0; min-height: 0; font-size: 11px; }
button.key label { color: inherit; }
button.key:checked { outline: 2px solid #8bd5ff; outline-offset: -2px; }
button.suggested-action { background: #8bd5ff; color: #10212f; font-weight: 600; }
.error { color: #ff9f9f; }
.success { color: #9ae6bb; }
"""


class KeyboardBoard(Gtk.Fixed):
    """Native accessible buttons transformed together at one common scale."""

    def __init__(self, on_selection):
        super().__init__(hexpand=True)
        self.set_layout_manager(None)
        self.add_css_class("keyboard")
        self.buttons = {}
        for key in layout.KEYS:
            button = Gtk.ToggleButton(label=key.label)
            button.add_css_class("key")
            button.add_css_class(f"key-{key.code}")
            button.get_child().set_ellipsize(Pango.EllipsizeMode.END)
            button.set_tooltip_text("Fn: " + key.label.split("\n")[1] if "\n" in key.label else f"Select {key.label}")
            button.connect("toggled", on_selection, key.code)
            button.set_parent(self)
            self.buttons[key.code] = button

    def do_get_request_mode(self):
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH

    def do_measure(self, orientation, for_size):
        if orientation == Gtk.Orientation.HORIZONTAL:
            return 300, layout.NATURAL_WIDTH, -1, -1
        width = for_size if for_size >= 0 else layout.NATURAL_WIDTH
        height = math.ceil(width * layout.NATURAL_HEIGHT / layout.NATURAL_WIDTH)
        return height, height, -1, -1

    def do_size_allocate(self, width, height, baseline):
        scale = min(width / layout.NATURAL_WIDTH, height / layout.NATURAL_HEIGHT)
        for code, (x, y, w, h) in layout.rectangles(width, height).items():
            button = self.buttons[code]
            button.measure(Gtk.Orientation.HORIZONTAL, -1)
            button.measure(Gtk.Orientation.VERTICAL, round(w / scale))
            transform = Gsk.Transform.new().translate(Graphene.Point().init(x, y)).scale(scale, scale)
            button.allocate(round(w / scale), round(h / scale), -1, transform)


class KeyboardWindow(Gtk.ApplicationWindow):
    def __init__(self, application):
        super().__init__(application=application, title="Stealth Keyboard")
        self.set_default_size(980, 710)
        self.selected = set()
        self.buttons = {}
        self.loaded = False
        self.animation_source = None
        self.applied_profile = None
        self.pending = False
        self.connect("close-request", self.on_close)
        profile_error = None
        try:
            (self.colors, self.brightness, self.enabled, self.reactive, self.fade_ms,
             self.animation, self.period_ms) = keyboard.load_profile()
        except (OSError, ValueError, TypeError) as exc:
            self.colors = {code: "#FFDDB0" for code in keyboard.REPORT_KEYS}
            self.brightness, self.enabled = 70, True
            self.reactive, self.fade_ms = False, 750
            self.animation, self.period_ms = "none", 3000
            profile_error = f"Could not load the saved profile: {exc}"

        self.provider = Gtk.CssProvider()
        # RGB previews need their literal colors, including under a user theme.
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), self.provider, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        content.add_css_class("content")
        for side in ("top", "bottom", "start", "end"):
            getattr(content, f"set_margin_{side}")(24)
        scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER)
        scroll.set_child(content)
        self.set_child(scroll)

        header = Gtk.Box(spacing=12)
        titles = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5, hexpand=True)
        title = Gtk.Label(label="Stealth Keyboard", xalign=0)
        title.add_css_class("title")
        titles.append(title)
        subtitle = Gtk.Label(label="SteelSeries RGB · Stealth 14 Studio", xalign=0)
        subtitle.add_css_class("muted")
        titles.append(subtitle)
        header.append(titles)
        header.append(Gtk.Label(label="Lighting"))
        self.power = Gtk.Switch(active=self.enabled, valign=Gtk.Align.CENTER)
        self.power.connect("notify::active", self.on_power)
        header.append(self.power)
        content.append(header)

        instruction = Gtk.Label(label="Select keys, then choose a color. Clear the selection to color the whole keyboard.", xalign=0, wrap=True)
        instruction.add_css_class("muted")
        content.append(instruction)
        self.board = KeyboardBoard(self.on_selection)
        self.buttons = self.board.buttons
        content.append(self.board)

        selection = Gtk.Box(spacing=10)
        self.scope = Gtk.Label(label="Whole keyboard", xalign=0, hexpand=True)
        self.scope.add_css_class("section")
        selection.append(self.scope)
        clear = Gtk.Button(label="Clear selection")
        clear.connect("clicked", lambda _: self.clear_selection())
        selection.append(clear)
        wasd = Gtk.Button(label="Select WASD")
        wasd.connect("clicked", lambda _: self.select_wasd())
        selection.append(wasd)
        content.append(selection)

        presets = Gtk.Box(spacing=8)
        for name, value in PRESETS:
            button = Gtk.Button(label=name, hexpand=True)
            button.connect("clicked", lambda _, value=value: self.paint(value))
            presets.append(button)
        content.append(presets)

        custom = Gtk.Box(spacing=10)
        custom.append(Gtk.Label(label="Custom color", xalign=0))
        rgba = Gdk.RGBA()
        rgba.parse("#FFDDB0")
        self.picker = Gtk.ColorButton(rgba=rgba, title="Choose a keyboard color", use_alpha=False)
        self.picker.connect("color-set", self.on_color_picked)
        custom.append(self.picker)
        self.hex_entry = Gtk.Entry(text="#FFDDB0", max_length=7, hexpand=True)
        self.hex_entry.set_placeholder_text("#RRGGBB")
        self.hex_entry.set_tooltip_text("Enter a six-digit hex color")
        self.hex_entry.connect("activate", lambda _: self.paint_entry())
        custom.append(self.hex_entry)
        paint = Gtk.Button(label="Set color")
        paint.connect("clicked", lambda _: self.paint_entry())
        custom.append(paint)
        content.append(custom)

        brightness_row = Gtk.Box(spacing=12)
        brightness_row.append(Gtk.Label(label="Brightness"))
        self.slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.slider.set_hexpand(True)
        self.slider.set_draw_value(False)
        self.slider.set_value(self.brightness)
        self.slider.set_tooltip_text("Keyboard brightness, from 0 to 100 percent")
        self.slider.connect("value-changed", self.on_brightness)
        brightness_row.append(self.slider)
        self.level = Gtk.Label(label=f"{self.brightness}%", width_chars=4)
        brightness_row.append(self.level)
        content.append(brightness_row)

        effect_row = Gtk.Box(spacing=12)
        self.reactive_check = Gtk.CheckButton(label="Fade on keypress", active=self.reactive, hexpand=True)
        self.reactive_check.connect("toggled", self.on_reactive)
        effect_row.append(self.reactive_check)
        effect_row.append(Gtk.Label(label="Fade back"))
        self.fade_control = Gtk.SpinButton.new_with_range(50, 2000, 50)
        self.fade_control.set_value(self.fade_ms)
        self.fade_control.set_sensitive(self.reactive)
        self.fade_control.connect("value-changed", self.on_fade)
        effect_row.append(self.fade_control)
        effect_row.append(Gtk.Label(label="ms"))
        content.append(effect_row)

        timed_row = Gtk.Box(spacing=12)
        timed_row.append(Gtk.Label(label="Timed effect"))
        self.effect_control = Gtk.DropDown.new_from_strings(["None", "Rainbow wave", "Breathing"])
        self.effect_control.set_selected(effects.NAMES.index(self.animation))
        self.effect_control.set_hexpand(True)
        self.effect_control.connect("notify::selected", self.on_animation)
        timed_row.append(self.effect_control)
        timed_row.append(Gtk.Label(label="Period"))
        self.period_control = Gtk.SpinButton.new_with_range(0.5, 30, 0.5)
        self.period_control.set_digits(1)
        self.period_control.set_value(self.period_ms / 1000)
        self.period_control.connect("value-changed", self.on_period)
        timed_row.append(self.period_control)
        timed_row.append(Gtk.Label(label="seconds"))
        content.append(timed_row)
        timed_note = Gtk.Label(label="Wave and breathing run while this app is open. Closing restores your base colors.", xalign=0, wrap=True)
        timed_note.add_css_class("muted")
        content.append(timed_note)

        footer = Gtk.Box(spacing=12)
        self.status = Gtk.Label(xalign=0, wrap=True, hexpand=True)
        self.status.add_css_class("muted")
        footer.append(self.status)
        self.apply_button = Gtk.Button(label="Apply to keyboard", valign=Gtk.Align.CENTER)
        self.apply_button.add_css_class("suggested-action")
        self.apply_button.connect("clicked", lambda _: self.apply())
        footer.append(self.apply_button)
        content.append(footer)
        note = Gtk.Label(label="Your last applied colors are remembered. Opening the app leaves the lighting as it is.", xalign=0, wrap=True)
        note.add_css_class("muted")
        content.append(note)

        self.loaded = True
        self.update_effect_controls()
        self.update_preview()
        if profile_error:
            self.message(profile_error, "error")
        else:
            try:
                device = keyboard.find_device()
                self.message(f"Connected · {device.name}. Preview ready to apply.")
            except OSError as exc:
                self.message(str(exc), "error")

    def message(self, text, style=None):
        self.status.set_label(text)
        for name in ("error", "success", "muted"):
            self.status.remove_css_class(name)
        self.status.add_css_class(style or "muted")

    def on_selection(self, button, code):
        if button.get_active():
            self.selected.add(code)
        else:
            self.selected.discard(code)
        self.scope.set_label(f"{len(self.selected)} keys selected" if self.selected else "Whole keyboard")

    def clear_selection(self):
        for button in self.buttons.values():
            button.set_active(False)

    def select_wasd(self):
        self.clear_selection()
        for code in (26, 4, 22, 7):
            self.buttons[code].set_active(True)

    def paint(self, value):
        try:
            value = keyboard.color(value)
        except ValueError as exc:
            self.message(str(exc), "error")
            return
        for code in self.selected or keyboard.REPORT_KEYS:
            self.colors[code] = value
        self.hex_entry.set_text(value)
        rgba = Gdk.RGBA()
        rgba.parse(value)
        self.picker.set_rgba(rgba)
        self.mark_changed()

    def paint_entry(self):
        self.paint(self.hex_entry.get_text())

    def on_color_picked(self, picker):
        rgba = picker.get_rgba()
        self.paint("#" + "".join(f"{round(channel * 255):02X}" for channel in (rgba.red, rgba.green, rgba.blue)))

    def on_brightness(self, slider):
        self.brightness = round(slider.get_value())
        self.level.set_label(f"{self.brightness}%")
        self.mark_changed()

    def on_power(self, switch, _):
        self.enabled = switch.get_active()
        if self.loaded:
            self.mark_changed()

    def on_reactive(self, button):
        self.reactive = button.get_active()
        self.update_effect_controls()
        self.mark_changed()

    def on_fade(self, control):
        self.fade_ms = control.get_value_as_int()
        self.mark_changed()

    def on_animation(self, control, _):
        self.animation = effects.NAMES[control.get_selected()]
        self.update_effect_controls()
        self.mark_changed()

    def on_period(self, control):
        self.period_ms = round(control.get_value() * 1000)
        self.mark_changed()

    def update_effect_controls(self):
        timed = self.animation != "none"
        self.reactive_check.set_sensitive(not timed)
        self.fade_control.set_sensitive(self.reactive and not timed)
        self.period_control.set_sensitive(timed)

    def mark_changed(self):
        self.pending = True
        self.update_preview()
        self.message("Preview changed · press Apply to update the keyboard.")

    def update_preview(self, colors=None, brightness=None, enabled=None):
        colors = effects.frame(self.colors, self.animation, 0) if colors is None else colors
        brightness = self.brightness if brightness is None else brightness
        enabled = self.enabled if enabled is None else enabled
        rules = []
        for code in self.buttons:
            rgb = bytes.fromhex(colors[code][1:])
            scale = brightness / 100 if enabled else 0
            rgb = tuple(round(channel * scale) for channel in rgb)
            background = "#" + "".join(f"{channel:02x}" for channel in rgb)
            foreground = layout.text_color(rgb)
            # A Pango foreground attribute keeps user theme label rules from
            # replacing the contrast color on the key's child label.
            key = layout.BY_CODE[code]
            size = 5120 if "\n" in key.label else 8192
            label = GLib.markup_escape_text(key.label)
            markup = f'<span foreground="{foreground}" size="{size}" weight="bold">{label}</span>'
            if self.buttons[code].get_child().get_label() != markup:
                self.buttons[code].get_child().set_markup(markup)
            rules.append(f"button.key-{code}, button.key-{code}:hover, button.key-{code}:checked, button.key-{code}:active {{ background-image: none; background-color: {background}; color: {foreground}; border: 1px solid #526074; }}")
        self.provider.load_from_data(CSS + "\n".join(rules).encode())

    def apply(self):
        self.stop_animation()
        try:
            effects.validate(self.animation, self.period_ms)
            if self.animation == "none" or not self.enabled or self.brightness == 0:
                keyboard.apply(self.colors, self.brightness, self.enabled, self.reactive, self.fade_ms)
            else:
                keyboard.apply(self.colors, self.brightness, self.enabled, False, self.fade_ms)
                keyboard.stream(effects.frame(self.colors, self.animation, 0), self.brightness)
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")
            return
        self.pending = False
        self.applied_profile = (dict(self.colors), self.brightness, self.enabled, self.reactive,
                                self.fade_ms, self.animation, self.period_ms)
        if self.animation != "none" and self.enabled and self.brightness:
            self.animation_start = time.monotonic()
            # ponytail: stream the tested color report until onboard effect
            # uploads have been checked against this model's Windows capture.
            self.animation_source = GLib.timeout_add(50, self.animate)
        try:
            keyboard.save_profile(self.colors, self.brightness, self.enabled, self.reactive,
                                  self.fade_ms, self.animation, self.period_ms)
        except OSError as exc:
            self.message(f"Lighting applied, but the profile could not be saved: {exc}", "error")
            return
        text = "Timed effect running · keep this app open." if self.animation_source else "Applied and saved."
        self.message(text if self.enabled and self.brightness else "Lighting off · colors saved.", "success")

    def animate(self):
        colors, brightness, enabled, _, _, effect, period = self.applied_profile
        phase = (time.monotonic() - self.animation_start) * 1000 / period
        frame = effects.frame(colors, effect, phase)
        try:
            keyboard.stream(frame, brightness)
        except OSError as exc:
            self.animation_source = None
            self.message(f"Timed effect stopped: {exc}", "error")
            return GLib.SOURCE_REMOVE
        if not self.pending:
            self.update_preview(frame, brightness, enabled)
        return GLib.SOURCE_CONTINUE

    def stop_animation(self):
        if self.animation_source is not None:
            GLib.source_remove(self.animation_source)
            self.animation_source = None

    def on_close(self, _):
        was_running = self.animation_source is not None
        self.stop_animation()
        if was_running and self.applied_profile:
            try:
                keyboard.apply(*self.applied_profile[:5])
            except OSError as exc:
                print(f"Could not restore base colors: {exc}", file=sys.stderr)
        return False


class App(Gtk.Application):
    def __init__(self, smoke=False):
        super().__init__(application_id="local.stealth.Keyboard.Test" if smoke else "local.stealth.Keyboard")
        self.smoke = smoke

    def do_activate(self):
        window = self.get_active_window()
        if window is None:
            window = KeyboardWindow(self)
        window.present()
        if self.smoke:
            from unittest.mock import patch
            window.select_wasd()
            window.paint("#123456")
            assert window.selected == {26, 4, 22, 7}
            assert all(window.colors[c] == "#123456" for c in window.selected)
            assert 'foreground="#FFFFFF"' in window.buttons[4].get_child().get_label()
            window.clear_selection()
            window.paint("#FFFFFF")
            assert set(window.colors.values()) == {"#FFFFFF"}
            assert len(window.buttons) == 83
            window.slider.set_value(42)
            window.power.set_active(True)
            window.effect_control.set_selected(0)
            window.reactive_check.set_active(True)
            window.fade_control.set_value(1200)
            with patch("keyboard.apply") as sent, patch("keyboard.save_profile") as saved:
                window.apply()
                sent.assert_called_once_with(window.colors, 42, True, True, 1200)
                saved.assert_called_once_with(window.colors, 42, True, True, 1200, "none", window.period_ms)
                window.power.set_active(False)
                window.apply()
                assert sent.call_args.args[2] is False
            window.power.set_active(True)
            window.effect_control.set_selected(1)
            window.period_control.set_value(4)
            with patch("keyboard.stream") as streamed, patch("keyboard.apply") as restored, patch("keyboard.save_profile"):
                window.apply()
                assert window.animation_source is not None
                window.animate()
                assert streamed.call_count == 2
                window.on_close(None)
                assert restored.call_args.args == (window.colors, 42, True, True, 1200)
                assert restored.call_args_list[0].args == (window.colors, 42, True, False, 1200)
                assert window.animation_source is None
            for factor in (1, 0.5):
                width, height = round(layout.NATURAL_WIDTH * factor), round(layout.NATURAL_HEIGHT * factor)
                window.board.measure(Gtk.Orientation.HORIZONTAL, -1)
                window.board.measure(Gtk.Orientation.VERTICAL, width)
                window.board.allocate(width, height, -1, None)
                for code, expected in layout.rectangles(width, height).items():
                    ok, bounds = window.buttons[code].compute_bounds(window.board)
                    assert ok
                    actual = (bounds.get_x(), bounds.get_y(), bounds.get_width(), bounds.get_height())
                    assert all(abs(a - e) < 1 for a, e in zip(actual, expected)), (code, actual, expected)
            print("GTK smoke check passed: contrast, uniform resizing, selection, effects, apply, restore, save.", flush=True)
            GLib.timeout_add(150, lambda: self.quit())


if __name__ == "__main__":
    smoke = "--smoke-test" in sys.argv
    if smoke:
        sys.argv.remove("--smoke-test")
    App(smoke).run(sys.argv)
