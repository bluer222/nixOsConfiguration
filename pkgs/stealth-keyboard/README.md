# Stealth Keyboard

Native GTK app for the MSI Stealth 14Studio A13VF's SteelSeries KLC controller,
USB `1038:113a`, interface 0. Open **Stealth Keyboard** from the app launcher.

Build or run the package from `/etc/nixos`:

```sh
nix build .#stealth-keyboard
nix run .#stealth-keyboard
```

The NixOS hardware module installs the same package on the next rebuild.

Choose a preset or custom color, adjust brightness, then click **Apply to
keyboard**. Click keys to select them before choosing a color. Clear the
selection to color the whole keyboard. **Fade on keypress** makes pressed keys
go dark, then fade back to their base color over the chosen time.

**Timed effect** provides a rainbow wave and breathing, with a period from
0.5 to 30 seconds. These effects stream RAM color reports at 20 frames per
second at most while the window is open. Closing the window stops streaming and
restores the applied base colors and keypress-fade setting. The app does not
read keyboard input to drive these effects.

The laptop handles the reactive effect. The app need not stay open, and does
not monitor keyboard input. Opening the app leaves the lighting unchanged.
Applied settings are saved to `$XDG_CONFIG_HOME/stealth-keyboard/profile.json`,
or `~/.config/stealth-keyboard/profile.json` by default. They are the app's own
settings, not a readback of the current SteelSeries GG profile.

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

Protocol references:

- [MSI KLC protocol notes](https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/blob/master/keyboard-rgb/KLC-PROTOCOL.md)
- [Per-key packet definitions](https://github.com/echtzeit-solutions/msi-wmi-platform-dkms/blob/master/keyboard-rgb/msi-klc/src/protocol.rs)
- [msi-perkeyrgb](https://github.com/Askannz/msi-perkeyrgb)

The app sends RAM-only `0x0E` color/reactive reports and a `0x0D` apply command,
and uses `0x0C` frames for timed effects.
It does not flash firmware or save to the controller's flash. It does not
automatically reapply after a reboot or resume. Open the app and click Apply
if the laptop resets its lighting.

For backend checks, run `python3 -m unittest discover -s tests -v` from this
directory. The packaged app's `--smoke-test` checks the GTK controls without
writing to the keyboard.
