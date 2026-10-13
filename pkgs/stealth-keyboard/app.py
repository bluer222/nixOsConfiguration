#!/usr/bin/env python3
"""Native GTK controls for the Stealth 14 Studio keyboard."""

import sys
import copy
import argparse
from pathlib import Path
import math

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
import profiles
import controller


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
flowboxchild { padding: 0; }
.error { color: #ff9f9f; }
.success { color: #9ae6bb; }
"""


class WrappingRow(Gtk.FlowBox):
    def __init__(self):
        super().__init__(selection_mode=Gtk.SelectionMode.NONE, column_spacing=10,
                         row_spacing=8, min_children_per_line=1, max_children_per_line=8)

    def append(self, child):
        self.insert(child, -1)


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
    def __init__(self, application, profile_path=None):
        super().__init__(application=application, title="Stealth Keyboard")
        self.set_default_size(980, 1000)
        self.selected = set()
        self.selecting = False
        self.updating = True
        self.editor_error = False
        self.preview_style = None
        error = None
        try:
            self.profile = profiles.load(profile_path) if profile_path else profiles.current()
        except (OSError, ValueError, TypeError) as exc:
            self.profile = profiles.default()
            error = f"Could not load the saved profile: {exc}"
        self.connect("close-request", self.on_close)
        self.provider = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), self.provider, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        content.add_css_class("content")
        for side in ("top", "bottom", "start", "end"):
            getattr(content, f"set_margin_{side}")(24)
        scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER, vexpand=True)
        scroll.set_child(content)
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root.append(scroll)
        self.set_child(root)

        header = Gtk.Box(spacing=12)
        titles = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4, hexpand=True)
        title = Gtk.Label(label="Stealth Keyboard", xalign=0)
        title.add_css_class("title")
        titles.append(title)
        sub = Gtk.Label(label="SteelSeries RGB · onboard lighting controls", xalign=0)
        sub.add_css_class("muted")
        titles.append(sub)
        header.append(titles)
        header.append(Gtk.Label(label="Lighting"))
        self.power = Gtk.Switch(active=self.profile["enabled"], valign=Gtk.Align.CENTER)
        self.power.connect("notify::active", self.on_power)
        header.append(self.power)
        self.add_button(header, "Quit", lambda: self.quit())
        content.append(header)
        info = Gtk.Label(label="Select keys to edit their colors and effects. Clear selection to edit the default effect.", xalign=0, wrap=True)
        info.add_css_class("muted")
        content.append(info)
        self.board = KeyboardBoard(self.on_selection)
        self.buttons = self.board.buttons
        content.append(self.board)

        selection = Gtk.Box(spacing=8)
        self.scope = Gtk.Label(xalign=0, hexpand=True)
        self.scope.add_css_class("section")
        selection.append(self.scope)
        self.groups = [set(self.buttons), {26, 4, 22, 7}, {79, 80, 81, 82}, set(range(58, 70)),
                       set(range(30, 40)), set(range(4, 30)), {224, 225, 226, 227, 228, 229, 230, 240},
                       {70, 75, 76, 78, 102}]
        self.group_control = Gtk.DropDown.new_from_strings(["Select group…", "All keys", "WASD", "Arrows", "Function keys", "Numbers", "Letters", "Modifiers", "Navigation"])
        self.group_control.connect("notify::selected", self.on_group)
        selection.append(self.group_control)
        self.add_button(selection, "Clear selection", lambda: self.select_keys(set()))
        content.append(selection)

        presets = WrappingRow()
        for name, value in PRESETS:
            button = Gtk.Button(label=name, hexpand=True)
            button.connect("clicked", lambda _, value=value: self.paint(value))
            presets.append(button)
        content.append(presets)
        custom = Gtk.Box(spacing=10)
        custom.append(Gtk.Label(label="Base color"))
        self.picker = Gtk.ColorButton(title="Base color", use_alpha=False)
        self.set_picker(self.picker, "#FFFFFF")
        self.picker.connect("color-set", lambda picker: self.paint(self.picker_color(picker)))
        custom.append(self.picker)
        self.hex_entry = Gtk.Entry(text="#FFFFFF", max_length=7, hexpand=True)
        self.hex_entry.connect("activate", lambda _: self.paint(self.hex_entry.get_text()))
        custom.append(self.hex_entry)
        self.add_button(custom, "Set color", lambda: self.paint(self.hex_entry.get_text()))
        content.append(custom)

        editor = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.controls = {}
        mode_row = Gtk.Box(spacing=10)
        mode_row.append(Gtk.Label(label="Effect"))
        mode = Gtk.DropDown.new_from_strings(effects.LABELS)
        mode.set_hexpand(True)
        mode.connect("notify::selected", lambda control, _: self.edit("mode", effects.MODES[control.get_selected()]))
        self.controls["mode"] = mode
        mode_row.append(mode)
        self.add_button(mode_row, "Use on all keys", self.effect_on_all)
        self.add_button(mode_row, "Reset overrides", self.reset_overrides)
        editor.append(mode_row)
        self.effect_info = Gtk.Label(xalign=0, wrap=True)
        self.effect_info.add_css_class("muted")
        editor.append(self.effect_info)

        timing = WrappingRow()
        self.speed_group = self.add_spin(timing, "Speed", "speed", 1, 100, 1, suffix="%")
        self.add_spin(timing, "Start phase", "phase", 0, 100, 1, suffix="%")
        self.timing_row = timing
        editor.append(timing)

        native = WrappingRow()
        self.add_spin(native, "Fade back", "fade_ms", 50, 2000, 50, suffix="ms")
        hit = Gtk.Box(spacing=8)
        hit.append(Gtk.Label(label="Keypress color"))
        self.hit_picker = Gtk.ColorButton(title="Color on keypress", use_alpha=False)
        self.hit_picker.connect("color-set", lambda picker: self.edit("hit_color", self.picker_color(picker)))
        hit.append(self.hit_picker)
        native.append(hit)
        self.native_row = native
        editor.append(native)

        palette_title = Gtk.Box(spacing=8)
        palette_title.append(Gtk.Label(label="Effect palette", xalign=0, hexpand=True))
        self.add_button(palette_title, "Add picked color", self.add_palette_color)
        self.add_button(palette_title, "Rainbow", lambda: self.edit("palette", list(effects.RAINBOW)))
        self.add_button(palette_title, "Use base colors", lambda: self.edit("palette", []))
        self.palette_title = palette_title
        editor.append(palette_title)
        self.palette_box = Gtk.FlowBox(selection_mode=Gtk.SelectionMode.NONE, column_spacing=8, row_spacing=6,
                                       max_children_per_line=8, min_children_per_line=1)
        editor.append(self.palette_box)

        spatial = Gtk.Box(spacing=10)
        spatial.append(Gtk.Label(label="Direction"))
        direction = Gtk.DropDown.new_from_strings(effects.DIRECTION_LABELS)
        direction.set_hexpand(True)
        direction.connect("notify::selected", lambda control, _: self.edit("direction", effects.DIRECTIONS[control.get_selected()])
                          if not self.updating and control.get_selected() < len(effects.DIRECTIONS) else None)
        self.controls["direction"] = direction
        spatial.append(direction)
        self.add_spin(spatial, "Spacing", "spacing", 5, 400, 5, suffix="%")
        self.spatial_row = spatial
        editor.append(spatial)

        origin = WrappingRow()
        self.add_spin(origin, "Origin X", "origin_x", 0, 100, 1, suffix="%")
        self.add_spin(origin, "Origin Y", "origin_y", 0, 100, 1, suffix="%")
        self.origin_row = origin
        editor.append(origin)

        key_level = WrappingRow()
        self.add_spin(key_level, "Per-key brightness", "maximum", 0, 100, 1, suffix="%")
        self.minimum_group = self.add_spin(key_level, "Dimmest level", "minimum", 0, 100, 1, suffix="% of peak")
        self.key_level_row = key_level
        editor.append(key_level)
        content.append(editor)

        global_row = Gtk.Box(spacing=12)
        global_row.append(Gtk.Label(label="Overall brightness"))
        self.slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.slider.set_hexpand(True)
        self.slider.set_draw_value(False)
        self.slider.set_value(self.profile["brightness"])
        self.slider.connect("value-changed", self.on_brightness)
        global_row.append(self.slider)
        self.level = Gtk.Label(label=f'{self.profile["brightness"]}%', width_chars=4)
        global_row.append(self.level)
        content.append(global_row)
        library = Gtk.Expander(label="Saved profiles and import / export")
        library_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        saved_row = Gtk.Box(spacing=10)
        self.saved_control = Gtk.DropDown.new_from_strings(["Choose a profile…"])
        self.saved_control.set_hexpand(True)
        saved_row.append(self.saved_control)
        self.add_button(saved_row, "Load", self.load_named)
        self.add_button(saved_row, "Delete", self.delete_named)
        library_box.append(saved_row)
        save_row = Gtk.Box(spacing=10)
        self.profile_name = Gtk.Entry(placeholder_text="Profile name", hexpand=True)
        save_row.append(self.profile_name)
        self.add_button(save_row, "Save profile", self.save_named)
        self.add_button(save_row, "Import…", lambda: self.choose_file(False))
        self.add_button(save_row, "Export…", lambda: self.choose_file(True))
        library_box.append(save_row)
        library.set_child(library_box)
        content.append(library)

        footer = Gtk.Box(spacing=10)
        self.status = Gtk.Label(xalign=0, wrap=True, hexpand=True)
        footer.append(self.status)
        apply = self.add_button(footer, "Apply to keyboard", self.apply)
        apply.add_css_class("suggested-action")
        for side in ("top", "bottom", "start", "end"):
            getattr(footer, f"set_margin_{side}")(16 if side in ("top", "bottom") else 24)
        root.append(footer)
        note = Gtk.Label(label="Apply programs the keyboard once. All effects keep working after this app closes. Up to 14 different animated settings can run together.", xalign=0, wrap=True)
        note.add_css_class("muted")
        content.append(note)
        self.updating = False
        self.refresh_library()
        self.load_editor()
        self.update_preview()
        if error:
            self.message(error, "error")
        else:
            try:
                self.message(f"Connected · {keyboard.find_device().name}. Preview ready to apply.")
            except OSError as exc:
                self.message(str(exc), "error")

    @staticmethod
    def add_button(box, text, callback):
        button = Gtk.Button(label=text)
        button.connect("clicked", lambda _: callback())
        box.append(button)
        return button

    @staticmethod
    def set_picker(picker, value):
        rgba = Gdk.RGBA()
        rgba.parse(value)
        picker.set_rgba(rgba)

    @staticmethod
    def picker_color(picker):
        value = picker.get_rgba()
        return effects.hex_rgb(c * 255 for c in (value.red, value.green, value.blue))

    def add_spin(self, box, title, name, low, high, step, factor=1, digits=0, suffix=None):
        group = Gtk.Box(spacing=8)
        group.append(Gtk.Label(label=title))
        spin = Gtk.SpinButton.new_with_range(low, high, step)
        spin.set_digits(digits)
        spin.connect("value-changed", lambda control: self.edit(name, round(control.get_value() * factor, 6)))
        self.controls[name] = spin
        spin._effect_factor = factor
        group.append(spin)
        if suffix:
            group.append(Gtk.Label(label=suffix))
        box.append(group)
        return group

    def message(self, text, style=None):
        self.status.set_label(text)
        for name in ("error", "success", "muted"):
            self.status.remove_css_class(name)
        self.status.add_css_class(style or "muted")

    def first_spec(self):
        if self.selected:
            return effects.resolved(self.profile, self.ordered_selection()[0])
        return self.profile["effect"]

    def ordered_selection(self):
        return sorted(self.selected, key=lambda code: (layout.BY_CODE[code].y, layout.BY_CODE[code].x))

    def on_selection(self, button, code):
        if button.get_active():
            self.selected.add(code)
        else:
            self.selected.discard(code)
        if not self.selecting:
            self.load_editor()

    def select_keys(self, keys):
        self.selecting = True
        for code, button in self.buttons.items():
            button.set_active(code in keys)
        self.selecting = False
        self.load_editor()

    def on_group(self, control, _):
        index = control.get_selected()
        if index:
            self.select_keys(self.groups[index - 1])
            control.set_selected(0)

    def load_editor(self):
        self.updating = True
        spec = self.first_spec()
        self.editor_error = False
        self.controls["mode"].set_selected(effects.MODES.index(spec["mode"]))
        self.controls["direction"].set_model(Gtk.StringList.new(effects.DIRECTION_LABELS[:6] if spec["mode"] == "wave" else effects.DIRECTION_LABELS))
        self.controls["direction"].set_selected(effects.DIRECTIONS.index(spec["direction"]))
        for name, control in self.controls.items():
            if isinstance(control, Gtk.SpinButton):
                control.set_value(spec[name] / control._effect_factor)
            elif isinstance(control, Gtk.CheckButton):
                control.set_active(spec[name])
        self.set_picker(self.hit_picker, spec["hit_color"])
        base = self.profile["colors"][self.ordered_selection()[0] if self.selected else keyboard.REPORT_KEYS[0]]
        self.set_picker(self.picker, base)
        self.hex_entry.set_text(base)
        self.refresh_palette(spec)
        if self.selected:
            mixed = any(effects.resolved(self.profile, c) != spec for c in self.selected)
            self.scope.set_label(f'{len(self.selected)} keys selected' + (" · mixed settings" if mixed else ""))
        else:
            self.scope.set_label(f'Default effect · {len(self.profile["key_effects"])} overrides')
        self.update_sensitivity(spec["mode"])
        self.updating = False

    def update_sensitivity(self, mode):
        self.native_row.set_visible(mode == "reactive")
        self.timing_row.set_visible(mode in effects.ANIMATED or mode == "gradient")
        self.controls["speed"].set_sensitive(mode in effects.ANIMATED)
        self.controls["minimum"].set_sensitive(mode == "breathing")
        self.speed_group.set_visible(mode in effects.ANIMATED)
        self.minimum_group.set_visible(mode == "breathing")
        self.palette_title.set_visible(mode in effects.ANIMATED or mode == "gradient")
        self.palette_box.set_visible(mode in effects.ANIMATED or mode == "gradient")
        self.spatial_row.set_visible(mode in ("gradient", "wave"))
        self.origin_row.set_visible(mode == "gradient")
        notes = {"static": "Selected keys hold their base color after the app closes.",
                 "reactive": "Each key reacts on the keyboard itself, using its own hit color and fade duration.",
                 "gradient": "A stationary palette written once to the keyboard.",
                 "cycle": "The keyboard loops through this palette itself. Empty palette uses a rainbow.",
                 "breathing": "The keyboard fades between each palette color and its dimmest level. Empty palette uses base colors.",
                 "wave": "The keyboard runs this wave itself. Empty palette uses a rainbow."}
        self.effect_info.set_label(notes[mode])

    def edit(self, name, value):
        if self.updating:
            return
        changes = []
        for code in self.selected or (None,):
            spec = copy.deepcopy(effects.resolved(self.profile, code) if code is not None else self.profile["effect"])
            spec[name] = value
            if name == "mode" and value == "wave" and spec["direction"] not in effects.DIRECTIONS[:6]:
                spec["direction"] = "outward"
            try:
                spec = effects.normalize(spec)
            except ValueError as exc:
                self.editor_error = True
                self.message(str(exc), "error")
                return
            changes.append((code, spec))
        for code, spec in changes:
            if code is None:
                self.profile["effect"] = spec
            else:
                self.profile["key_effects"][code] = spec
        self.editor_error = False
        if name in ("mode", "palette", "hit_color", "maximum"):
            self.load_editor()
        self.changed()

    def effect_on_all(self):
        if self.editor_error:
            self.message("Correct the invalid effect setting first.", "error")
            return
        self.profile["effect"] = copy.deepcopy(self.first_spec())
        self.profile["key_effects"].clear()
        self.select_keys(set())
        self.changed()

    def reset_overrides(self):
        for code in self.selected or set(self.profile["key_effects"]):
            self.profile["key_effects"].pop(code, None)
        self.load_editor()
        self.changed()

    def paint(self, value):
        try:
            value = effects.color(value)
        except ValueError as exc:
            self.message(str(exc), "error")
            return
        for code in self.selected or self.profile["colors"]:
            self.profile["colors"][code] = value
        self.hex_entry.set_text(value)
        self.set_picker(self.picker, value)
        self.changed()

    def refresh_palette(self, spec):
        child = self.palette_box.get_first_child()
        while child:
            self.palette_box.remove(child)
            child = self.palette_box.get_first_child()
        if not spec["palette"]:
            self.palette_box.insert(Gtk.Label(label="Using base colors / automatic rainbow"), -1)
        for i, value in enumerate(spec["palette"]):
            box = Gtk.Box(spacing=2)
            picker = Gtk.ColorButton(title=f"Palette color {i + 1}", use_alpha=False)
            self.set_picker(picker, value)
            picker.connect("color-set", lambda control, i=i: self.palette_color(i, self.picker_color(control)))
            box.append(picker)
            self.add_button(box, "×", lambda i=i: self.remove_palette_color(i))
            self.palette_box.insert(box, -1)

    def palette_color(self, index, value):
        palette = list(self.first_spec()["palette"])
        palette[index] = value
        self.edit("palette", palette)

    def remove_palette_color(self, index):
        palette = list(self.first_spec()["palette"])
        palette.pop(index)
        self.edit("palette", palette)

    def add_palette_color(self):
        palette = list(self.first_spec()["palette"])
        limit = effects.palette_limit(self.first_spec()["mode"])
        if len(palette) >= limit:
            self.message(f"This effect supports up to {limit} colors.", "error")
            return
        self.edit("palette", palette + [self.picker_color(self.picker)])

    def changed(self):
        self.update_preview()
        self.message("Preview changed · Apply updates the keyboard.")

    def on_power(self, control, _):
        if not self.updating:
            self.profile["enabled"] = control.get_active()
            self.changed()

    def on_brightness(self, control):
        if not self.updating:
            self.profile["brightness"] = round(control.get_value())
            self.level.set_label(f'{self.profile["brightness"]}%')
            self.changed()

    def update_preview(self):
        colors = effects.base_frame(self.profile)
        scale = self.profile["brightness"] / 100 if self.profile["enabled"] else 0
        rules = []
        for code, button in self.buttons.items():
            channels = tuple(round(c * scale) for c in effects.rgb(colors[code]))
            background = effects.hex_rgb(channels)
            foreground = layout.text_color(channels)
            key = layout.BY_CODE[code]
            size = 5120 if "\n" in key.label else 8192
            label = GLib.markup_escape_text(key.label)
            markup = f'<span foreground="{foreground}" size="{size}" weight="bold">{label}</span>'
            if button.get_child().get_label() != markup:
                button.get_child().set_markup(markup)
            spec = effects.resolved(self.profile, code)
            override = code in self.profile["key_effects"]
            border = "#c89bff" if override else "#526074"
            button.set_tooltip_text(f'{key.label.replace(chr(10), " / ")} · {effects.LABELS[effects.MODES.index(spec["mode"])]}\n' + ("custom effect" if override else "default effect"))
            rules.append(f"button.key-{code}, button.key-{code}:hover, button.key-{code}:checked, button.key-{code}:active {{ background-image: none; background-color: {background}; color: {foreground}; border: 1px solid {border}; }}")
        style = CSS + "\n".join(rules).encode()
        if style != self.preview_style:
            self.provider.load_from_data(style)
            self.preview_style = style

    def apply(self):
        if self.editor_error:
            self.message("Correct the invalid effect setting before applying.", "error")
            return
        try:
            self.profile = profiles.validate(self.profile)
            controller.apply(self.profile)
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")
            return
        try:
            profiles.save(self.profile)
        except OSError as exc:
            self.message(f"Applied, but could not save the profile: {exc}", "error")
            return
        self.message("Applied and saved · lighting continues after you close the app.", "success")

    def refresh_library(self):
        self.saved_names = profiles.names()
        self.saved_control.set_model(Gtk.StringList.new(["Choose a profile…", *self.saved_names]))
        self.saved_control.set_selected(0)

    def save_named(self):
        try:
            path = profiles.named_path(self.profile_name.get_text())
            profiles.save(self.profile, path)
            self.refresh_library()
            self.message(f"Saved '{path.stem}'. Keyboard unchanged.", "success")
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")

    def selected_profile_name(self):
        index = self.saved_control.get_selected()
        if not 1 <= index <= len(self.saved_names):
            raise ValueError("Choose a saved profile first.")
        return self.saved_names[index - 1]

    def load_named(self):
        try:
            name = self.selected_profile_name()
            self.load_draft(profiles.load(profiles.named_path(name)))
            self.profile_name.set_text(name)
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")

    def delete_named(self):
        try:
            name = self.selected_profile_name()
            profiles.named_path(name).unlink()
            self.refresh_library()
            self.message(f"Deleted saved profile '{name}'. Current preview and keyboard unchanged.")
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")

    def load_draft(self, profile):
        self.profile = profiles.validate(profile)
        self.updating = True
        self.power.set_active(self.profile["enabled"])
        self.slider.set_value(self.profile["brightness"])
        self.level.set_label(f'{self.profile["brightness"]}%')
        self.updating = False
        self.select_keys(set())
        self.changed()

    def choose_file(self, exporting):
        chooser = Gtk.FileChooserNative(title="Export profile" if exporting else "Import profile", transient_for=self,
                                        action=Gtk.FileChooserAction.SAVE if exporting else Gtk.FileChooserAction.OPEN,
                                        accept_label="Export" if exporting else "Import", cancel_label="Cancel")
        filter = Gtk.FileFilter()
        filter.set_name("Lighting profiles")
        filter.add_pattern("*.json")
        chooser.add_filter(filter)
        if exporting:
            chooser.set_current_name("stealth-keyboard.json")
        chooser.connect("response", self.file_chosen, exporting)
        chooser.show()
        self.file_chooser = chooser

    def file_chosen(self, chooser, response, exporting):
        try:
            if response == Gtk.ResponseType.ACCEPT:
                path = chooser.get_file().get_path()
                if not path:
                    raise ValueError("Choose a local file.")
                if exporting:
                    profiles.save(self.profile, path)
                    self.message("Profile exported.", "success")
                else:
                    self.load_draft(profiles.load(path))
        except (OSError, ValueError) as exc:
            self.message(str(exc), "error")
        finally:
            chooser.destroy()
            self.file_chooser = None

    def on_close(self, _):
        self.quit()
        return True

    def quit(self):
        self.get_application().quit()


class App(Gtk.Application):
    def __init__(self, smoke=False, profile_path=None):
        super().__init__(application_id="local.stealth.Keyboard.Test" if smoke else "local.stealth.Keyboard")
        self.smoke = smoke
        self.profile_path = profile_path

    def do_activate(self):
        windows = self.get_windows()
        window = windows[0] if windows else None
        if window is None:
            window = KeyboardWindow(self, self.profile_path)
        window.present()
        if self.smoke and not getattr(self, "smoke_started", False):
            self.smoke_started = True
            from unittest.mock import patch
            import tempfile
            with patch("keyboard.apply") as sent, patch("profiles.save"):
                window.load_draft(profiles.default())
                window.select_keys({26, 4, 22, 7})
                window.paint("#123456")
                assert all(window.profile["colors"][c] == "#123456" for c in window.selected)
                assert 'foreground="#FFFFFF"' in window.buttons[4].get_child().get_label()
                window.edit("fade_ms", 1200)
                window.edit("hit_color", "#0000FF")
                window.apply()
                assert all(sent.call_args.kwargs["key_reactive"][c] == {"fade_ms": 1200, "hit_color": "#0000FF"} for c in window.selected)
                window.reset_overrides()
                assert not window.profile["key_effects"]
                window.select_keys({26, 4})
                window.edit("mode", "cycle")
                window.edit("palette", ["#FF0000", "#00FF00"])
                window.edit("speed", 100)
                window.apply()
                assert len(sent.call_args.kwargs["effect_reports"]) == 1
                assert set(sent.call_args.kwargs["key_effects"]) == {26, 4}
                window.edit("mode", "breathing")
                window.edit("minimum", 10)
                window.apply()
                assert sent.call_args.kwargs["effect_reports"][0][1] == 11
                window.edit("mode", "wave")
                window.controls["direction"].set_selected(1)
                window.apply()
                assert sent.call_args.kwargs["effect_reports"][0][155] == 1
                assert not hasattr(window, "timer")
                window.load_draft(profiles.default())
                window.controls["mode"].set_selected(effects.MODES.index("gradient"))
                window.controls["direction"].set_selected(4)
                window.controls["spacing"].set_value(50)
                window.add_palette_color()
                window.palette_color(0, "#00FF00")
                window.remove_palette_color(0)
                assert window.profile["effect"]["direction"] == "outward"
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
                assert window.get_child().measure(Gtk.Orientation.HORIZONTAL, -1)[0] <= 650
            with tempfile.TemporaryDirectory() as directory:
                original_names, original_path = profiles.names, profiles.named_path
                with patch("profiles.names", lambda: original_names(Path(directory))), \
                     patch("profiles.named_path", lambda name: original_path(name, Path(directory))):
                    window.profile_name.set_text("Smoke profile")
                    original = copy.deepcopy(window.profile)
                    window.save_named()
                    window.load_draft(profiles.default())
                    window.saved_control.set_selected(1)
                    window.load_named()
                    assert window.profile == original
                    window.saved_control.set_selected(1)
                    window.delete_named()
                    assert not list(Path(directory).glob("*.json"))
            print("GTK smoke check passed: onboard cycle/breathing/wave, native per-key fades, palettes, profiles, contrast, resizing; no recurring timer.", flush=True)
            GLib.timeout_add(150, lambda: window.quit())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Stealth Keyboard lighting controls")
    parser.add_argument("--smoke-test", action="store_true")
    parser.add_argument("--profile", type=Path, help="Load a lighting profile")
    parser.add_argument("--headless", action="store_true", help="Apply once and exit, without opening the editor")
    args = parser.parse_args()
    if args.headless:
        try:
            controller.apply(profiles.load(args.profile) if args.profile else profiles.current())
        except (OSError, ValueError) as exc:
            parser.exit(1, f"{exc}\n")
    else:
        App(args.smoke_test, args.profile).run([sys.argv[0]])
