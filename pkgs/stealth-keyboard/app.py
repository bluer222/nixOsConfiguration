#!/usr/bin/env python3
"""Native GTK controls for the Stealth 14 Studio keyboard."""

import sys

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, GLib, Gtk

import keyboard


PRESETS = [("Warm white", "#FFDDB0"), ("White", "#FFFFFF"), ("Ice", "#72D8FF"),
           ("Mint", "#72FFC5"), ("Rose", "#FF80AE"), ("Red", "#FF3838")]
CSS = b"""
window { background: #11151c; color: #e6edf6; }
.content { font-family: sans-serif; }
.title { font-size: 26px; font-weight: 700; }
.muted { color: #9baabd; }
.section { font-size: 16px; font-weight: 600; }
.keyboard { background: #1b222d; padding: 16px; border-radius: 16px; }
button { border-radius: 9px; padding: 7px 12px; }
button.key { padding: 4px; min-width: 0; min-height: 34px; font-size: 11px; }
button.key:checked { outline: 2px solid #8bd5ff; outline-offset: -2px; }
button.suggested-action { background: #8bd5ff; color: #10212f; font-weight: 600; }
.error { color: #ff9f9f; }
.success { color: #9ae6bb; }
"""


class KeyboardWindow(Gtk.ApplicationWindow):
    def __init__(self, application):
        super().__init__(application=application, title="Stealth Keyboard")
        self.set_default_size(980, 710)
        self.selected = set()
        self.buttons = {}
        self.loaded = False
        profile_error = None
        try:
            self.colors, self.brightness, self.enabled, self.reactive, self.fade_ms = keyboard.load_profile()
        except (OSError, ValueError, TypeError) as exc:
            self.colors = {code: "#FFDDB0" for code in keyboard.REPORT_KEYS}
            self.brightness, self.enabled = 70, True
            self.reactive, self.fade_ms = False, 750
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
        board = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        board.add_css_class("keyboard")
        for row in keyboard.ROWS:
            box = Gtk.Box(spacing=5, homogeneous=False)
            for label, code, width in row:
                button = Gtk.ToggleButton(label=label, hexpand=True)
                button.set_size_request(round(32 * width), 40)
                button.add_css_class("key")
                button.add_css_class(f"key-{code}")
                button.set_tooltip_text(f"Select {label}")
                button.connect("toggled", self.on_selection, code)
                self.buttons[code] = button
                box.append(button)
            board.append(box)
        content.append(board)

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
        self.fade_control.set_sensitive(self.reactive)
        self.mark_changed()

    def on_fade(self, control):
        self.fade_ms = control.get_value_as_int()
        self.mark_changed()

    def mark_changed(self):
        self.update_preview()
        self.message("Preview changed · press Apply to update the keyboard.")

    def update_preview(self):
        rules = []
        for code in self.buttons:
            rgb = bytes.fromhex(self.colors[code][1:])
            scale = self.brightness / 100 if self.enabled else 0
            rgb = tuple(round(channel * scale) for channel in rgb)
            background = "#" + "".join(f"{channel:02x}" for channel in rgb)
            foreground = "#101722" if sum(c * w for c, w in zip(rgb, (0.2126, 0.7152, 0.0722))) > 135 else "#ffffff"
            rules.append(f"button.key-{code} {{ background-image: none; background-color: {background}; color: {foreground}; border: 1px solid #526074; }}")
        self.provider.load_from_data(CSS + "\n".join(rules).encode())

    def apply(self):
        try:
            keyboard.apply(self.colors, self.brightness, self.enabled, self.reactive, self.fade_ms)
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")
            return
        try:
            keyboard.save_profile(self.colors, self.brightness, self.enabled, self.reactive, self.fade_ms)
        except OSError as exc:
            self.message(f"Lighting applied, but the profile could not be saved: {exc}", "error")
            return
        self.message("Applied and saved." if self.enabled and self.brightness else "Lighting off · colors saved.", "success")


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
            window.clear_selection()
            window.paint("#FFFFFF")
            assert set(window.colors.values()) == {"#FFFFFF"}
            assert len(window.buttons) == 83
            window.slider.set_value(42)
            window.power.set_active(True)
            window.reactive_check.set_active(True)
            window.fade_control.set_value(1200)
            with patch("keyboard.apply") as sent, patch("keyboard.save_profile") as saved:
                window.apply()
                sent.assert_called_once_with(window.colors, 42, True, True, 1200)
                saved.assert_called_once_with(window.colors, 42, True, True, 1200)
                window.power.set_active(False)
                window.apply()
                assert sent.call_args.args[2] is False
            print("GTK smoke check passed: key selection, colors, brightness, fade, off, apply, save.", flush=True)
            GLib.timeout_add(150, lambda: self.quit())


if __name__ == "__main__":
    smoke = "--smoke-test" in sys.argv
    if smoke:
        sys.argv.remove("--smoke-test")
    App(smoke).run(sys.argv)
