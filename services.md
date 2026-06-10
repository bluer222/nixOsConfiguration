# Background services and daemons

Services configured in this NixOS repo for `samm-desktop`. Scope is **enabled/configured** units — not every package on the system.

## System (root / multi-user)

| Service / daemon | Scope | Description |
|---|---|---|
| `greetd` | Login | Text greeter (`tuigreet`) — session picker and login before Hyprland |
| `NetworkManager` | Network | Wi‑Fi/Ethernet, DNS override (`1.1.1.2` / `1.0.0.1`), no powersave throttling |
| `nftables` + `firewall` | Network | Host firewall; extra rules for Waydroid forwarding |
| `portmaster` | Network | Application firewall / filter daemon (tray UI is separate, user service) |
| `portmaster-managed-profiles` | Network | One-shot import of Portmaster app profiles at boot |
| `nginx` | Web | Local file index on `localhost` (home dir root) |
| `avahi-daemon` | Network | mDNS / local service discovery |
| `pipewire` + `wireplumber` | Audio | Low-latency audio; PulseAudio compatibility |
| `rtkit` | Audio | Real-time scheduling for audio threads |
| `bluetooth` (`bluetoothd`) | Hardware | Bluetooth stack |
| `nvidia-uvm` | GPU | Loads NVIDIA UVM module for CUDA (deferred from early boot) |
| `msi-ec` | Hardware | Loads MSI embedded-controller module for fan/EC control |
| `tlp` + `tlp-pd` | Power | Laptop power profiles (AC/battery/saver); replaces power-profiles-daemon |
| `thermald` | Power | Intel thermal throttling daemon |
| `upower` | Power | Battery/AC state for applets and scripts |
| `powertop` (auto-tune) | Power | Periodic power tuning via `powerManagement` |
| `howdy` | Auth | Facial recognition daemon (IR camera) |
| `linux-enable-ir-emitter` | Auth | IR emitter for Howdy |
| `polkit` | Auth | Privilege escalation framework |
| `automatic-timezoned` | System | Timezone from geolocation |
| `systemd-timesyncd` | System | NTP clock sync |
| `geoclue2` | System | Location services (used by timezone etc.) |
| `nscd` + `nsncd` | System | Name-service cache |
| `fstrim` | Storage | Periodic SSD TRIM |
| `ananicy-cpp` | Performance | Process niceness / IO priority rules |
| `system76-scheduler` | Performance | CFS scheduler tuning for foreground apps |
| `irqbalance` | Performance | Spread hardware interrupts across CPUs |
| `uresourced` | Performance | User-session resource management (systemd-oom integration) |
| `dbus-broker` | System | D-Bus message broker (replaces classic dbus-daemon) |
| `libvirtd` | Virtualisation | QEMU/KVM hypervisor (not auto-started via wantedBy override) |
| `cups` | Printing | Print spooler |
| `fwupd` | Hardware | Firmware updates |
| `flatpak` | Apps | Flatpak repo helper / session integration |
| `wivrn` | VR | Wireless VR streaming server (manual/autoStart off by default) |
| `oomd` | System | **Disabled** — avoids extra boot delay |

## User session (systemd --user, Hyprland)

Started via `hyprland-session.target` unless noted.

| Service | Description |
|---|---|
| `waybar` | Top bar: workspaces, taskbar, tray, status modules |
| `hyprpaper` | Wallpaper daemon — initial wallpaper + IPC for workspace changes |
| `plasma-kded6` | KDE background daemon (plasma applets, device integration) |
| `plasma-xdg-desktop-portal-kde` | KDE portal backend — file picker, app chooser, mime resolver |
| `powerdevil` | KDE PowerDevil (battery/upower backend for battery applet) |
| `kwalletd6` | KDE wallet — started after login PAM handoff, not at session target |
| `ksecretd` | libsecret → KWallet bridge for apps (Signal, Brave, etc.) |
| `kdeconnectd` | KDE Connect daemon (`programs.kdeconnect`) |
| `portmaster-tray` | Portmaster GUI tray (waits for Wayland, connects to system daemon) |
| `mcontrolcenter` | MSI laptop EC/fan control tray |
| `power-sounds` | Oxygen plug/unplug sounds via udev monitor |
| `wallpaper-watcher` | Changes wallpaper on workspace switch; resets show-desktop state |
| `popup-closer` | Closes plasmawindowed waybar popups when focus is lost |
| `mako` (HM) | Notification daemon |
| `hypridle` (HM) | Idle dim/lock/suspend policy |
| `xdg-desktop-portal` + `xdg-desktop-portal-hyprland` (HM) | XDG portal hub + Hyprland screencast/screenshot backend |
| `pipewire-pulse` (user) | PulseAudio socket for session apps |

**Disabled / blocked user units**

| Service | Reason |
|---|---|
| `polkit-kde-agent` | Started from Hyprland autostart once `WAYLAND_DISPLAY` exists |
| `avizo` | Started from Hyprland autostart (`avizo-start.sh`) |
| `kwalletd6` at session target | Avoids race with greetd PAM unlock |

## Hyprland autostart (non-systemd)

Started from `hyprland.start` in `hyprland.nix`.

| Process | Description |
|---|---|
| `kwallet-unlock.sh` | Ensures kwalletd6/ksecretd are running after greetd PAM |
| `polkit-agent.sh` | KDE polkit authentication agent |
| `avizo-start.sh` | Volume/brightness on-screen display daemon |
| `albert` | Qt launcher / clipboard search |
| `wl-paste --type text --watch cliphist store` | Clipboard history (text) |
| `wl-paste --type image --watch cliphist store` | Clipboard history (images) |
| `session-restore.sh` | Restores windows saved on last Hyprland exit |

## Session helpers (scripts invoked by services/keys, not always running)

| Script | Role |
|---|---|
| `show_desktop.sh` | Super+` — toggle workspace 4 (empty desk) / restore previous |
| `session-resume.sh` | After sleep/hibernate — restart KDE services, polkit, portals |
| `qt-popup.sh` | Waybar module popups (volume, network, bluetooth, …) |
| `open-monitors.sh` | Super+P — rofi + hyprctl monitor scale/enable/disable |
| `change_wallpaper.sh` | Sets wallpaper via `hyprctl hyprpaper` |
| `brightness-dim.sh` / `brightness-restore.sh` | Hypridle battery dim |
| `session-save.sh` | Saves window list on Hyprland shutdown |

## XFCE backup session

Minimal XFCE (`xfce4-session`) is installed as an alternate display-manager session only — no extra daemons beyond what XFCE starts when that session is chosen.
