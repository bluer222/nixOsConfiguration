# Stealth Keyboard

Native GTK app for the MSI Stealth 14Studio A13VF's SteelSeries KLC controller,
USB `1038:113a`, interface 0. Open **Stealth Keyboard** from the app launcher.

Build or run the package from `/etc/nixos`:

```sh
nix build .#stealth-keyboard
nix run .#stealth-keyboard
```

The NixOS hardware module installs the same package on the next rebuild.

Choose a preset or custom base color, adjust brightness, then click **Apply to
keyboard**. Click keys or choose a group to select them. With no selection,
colors affect the whole keyboard and effect edits change its default effect.
Selected keys get independent effect settings, marked with a purple border.
Changing one field preserves their other settings. **Reset overrides** returns
selected keys to the default effect, or clears all overrides with no selection.
**Use on all keys** replaces every key's effect with the editor's settings.

Every effect runs on the keyboard after Apply: static color, keypress fade,
gradient, color cycle, breathing, and wave. Closing the app exits completely
and leaves lighting unchanged. There is no streaming loop, daemon, background
mode, or continuously animated preview.

Controls include per-key speed, starting phase, brightness, and palettes;
breathing also has a dimmest level relative to its peak. Waves support
horizontal, vertical, and radial propagation, reversed direction, and spacing.
Gradient has eight directions and an adjustable origin. The keyboard handles
keypress colors and fade durations from 50 to 2000 ms independently per key.
The preview shows initial colors and updates only when settings change.

There are up to 14 shared onboard program slots. Keys with identical animated
settings share a slot; different palettes, speeds, phases, and brightness may
need separate slots. An over-capacity profile is rejected before hardware
writes. Cycle and wave palettes allow 14 colors; breathing allows 7, leaving
room in the 16-section ramp table for a shifted starting phase. Gradients
allow 16 colors. Speed is relative, with 100% fastest; firmware tick limits and
fixed-point ramps quantize timing and colors.

Delay, finite repeats, extra fade curves, pulse, blink, twinkle, and scanner
were removed because their earlier implementations required the app to run.

The laptop handles the reactive effect. The app need not stay open, and does
not monitor keyboard input. Opening the app leaves the lighting unchanged.
Applied settings are saved to `$XDG_CONFIG_HOME/stealth-keyboard/profile.json`,
or `~/.config/stealth-keyboard/profile.json` by default. They are the app's own
settings, not a readback of the current SteelSeries GG profile.

The profile library can save, load, and delete named profiles. Import and export
use validated JSON files. Opening, editing, or loading a profile changes only
the preview until Apply. Saves are atomic and preserve every key's native
settings. Older profiles migrate to version 4: cycle, breathing, and wave
become onboard programs; removed patterns become their stored base color or
keypress fallback. Their software-only timing options and background flags
are dropped. Oversized legacy palettes are shortened to hardware capacity.
The original profile file is untouched until you save or Apply.

For a single apply without opening the editor:

```sh
stealth-keyboard --headless --profile /path/to/profile.json
```

This programs all settings once and exits immediately, including animations.
Without `--profile`, it uses the last applied profile.
`stealth-keyboard --profile /path/to/profile.json` loads a file into the editor.

Brightness scales the outgoing RGB values from 0 to 100 percent. The laptop's
own brightness controls can also affect the result. This controller responds
to a layout query, but its brightness query returned zeros. Full GG profile
readback is not implemented or verified.

The NixOS module in `modules/nixos/hardware/keyboard-rgb.nix` installs the app
and a device-specific udev rule allowing the active local session to access
the lighting interface. It takes effect after the next NixOS rebuild. For a
temporary grant before that, use the device path reported by the app:

```sh
sudo setfacl -m u:$(id -u):rw /dev/hidraw0
```

The number may change after reboot. The app redetects interface 0 each time it
applies a setting.

The physical preview has a half-height function row, full-width half-height arrows,
PgUp/Home and PgDn/End above the left and right arrows, Fn between left Ctrl
and Super, a second backslash between AltGr and right Ctrl, and PrtSc between
F12 and Del. It has no separate Ins, Home, or End key. Key positions,
sizes, gaps, and labels scale together. W, A, Space, and all four arrow
addresses were physically checked. All-key static red and white, and
white-to-black-to-white reactive fade were also confirmed on this laptop.
Onboard W red/green cycling and A blue breathing were confirmed after the
writer exited. Rainbow wave propagation across F1-F12 was also confirmed after
the writer exited, alongside native keypress fade on other keys.

Protocol references:

- [MSI KLC protocol notes](https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/blob/master/keyboard-rgb/KLC-PROTOCOL.md)
- [Per-key packet definitions](https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/blob/master/keyboard-rgb/msi-klc/src/protocol.rs)
- [msi-perkeyrgb](https://github.com/Askannz/msi-perkeyrgb)

The app uploads 151-byte RAM effect programs with a 525-byte feature report
headed `[0, 0x0B, 0, slot, 0]`, followed by the program at offset 5. This direct
header is verified on the Stealth 14. The reference's nested
`[0, 0x0C, 0, 0x0B, ...]` upload header did not work on this controller.
`0x0E` reports assign static colors, keypress settings, or an effect slot to
each key; `0x0D` applies the settings once. No color frames are streamed.

The app does not flash firmware or save to the controller's flash. Continuing
after the app exits is distinct from surviving a power loss or controller
reset. If the laptop resets its lighting, open the app and Apply again.
Automatic resume/reboot reapplication and GG profile readback are not included.

For backend checks, run `python3 -m unittest discover -s tests -v` from this
directory. The packaged app's `--smoke-test` checks the GTK controls without
writing to the keyboard.
