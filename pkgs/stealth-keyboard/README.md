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

Effects include static color, keypress fade, breathing, color cycle, wave,
gradient, pulse, blink, twinkle, and scanner. The controls support:

- Independent periods from 0.1 to 120 seconds, phases, start delays, repeat
  counts, and phase offsets across a selection.
- Up to 16 palette colors, editable swatches, a rainbow preset, and base colors.
- Eight wave directions, spacing, scanner width, and an adjustable origin for
  radial and rotating patterns.
- Per-key brightness limits, five fade curves, and pulse/blink on-time.
- Per-key keypress colors and fade durations from 50 to 2000 ms.
- Live previews, a simulated keypress, and preview restart.

Wave, breathing, cycle, pulse, blink, twinkle, and scanner stream RAM color
reports at up to 20 frames per second. Only animated keys are streamed, so other
keys keep their native keypress response. Each finite effect returns to its
base color when complete, optionally restoring keypress fade. Gradient is
stationary and remains on the keyboard without a running app.

Closing the window normally stops streaming and restores base colors and the
selected keypress fallback. Enable **Keep effects running when window closes**
to hide the window and keep animation running. Launch the app again to reopen
it. **Quit** stops and exits; **Stop timed effects** restores lighting while
keeping the editor open. Another GUI or headless process cannot replace active
effects until they stop.

The laptop handles the reactive effect. The app need not stay open, and does
not monitor keyboard input. Opening the app leaves the lighting unchanged.
Applied settings are saved to `$XDG_CONFIG_HOME/stealth-keyboard/profile.json`,
or `~/.config/stealth-keyboard/profile.json` by default. They are the app's own
settings, not a readback of the current SteelSeries GG profile.

The profile library can save, load, and delete named profiles. Import and export
use validated JSON files. Opening, editing, or loading a profile changes only
the preview until Apply. Older app profiles migrate automatically. Saves are
atomic and preserve every key's effect settings.

For animation without the editor:

```sh
stealth-keyboard --headless --profile /path/to/profile.json
```

Without `--profile`, this uses the last applied profile. Static, gradient, and
native reactive profiles apply and exit. Timed profiles run until their repeat
counts finish, Ctrl+C, or SIGTERM, then restore base colors and native fallback.
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
Rainbow wave and breathing were physically confirmed as well.
Independent breathing speeds were checked alongside native Space blue-hit
1500 ms fade and S dark-hit 100 ms fade, confirming mixed timed/reactive control.

Protocol references:

- [MSI KLC protocol notes](https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/blob/master/keyboard-rgb/KLC-PROTOCOL.md)
- [Per-key packet definitions](https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/blob/master/keyboard-rgb/msi-klc/src/protocol.rs)
- [msi-perkeyrgb](https://github.com/Askannz/msi-perkeyrgb)

The app sends RAM-only `0x0E` color/reactive reports and a `0x0D` apply command,
and uses `0x0C` frames for timed effects.
It does not flash firmware or save to the controller's flash. It does not
automatically reapply after a reboot or resume. Open the app and click Apply
if the laptop resets its lighting.
SteelSeries GG's onboard effect programs and profile readback have not been
validated for this controller; timed patterns use the running app instead.

For backend checks, run `python3 -m unittest discover -s tests -v` from this
directory. The packaged app's `--smoke-test` checks the GTK controls without
writing to the keyboard.
