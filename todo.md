Note to agent: avoid gnome and gtk apps like the plague. prefer qt or hyprland native tools(generally qt, hyprland native if it is clearly better than the qt option)

new:
the waybar menus for volume etc should close on lose focus
screenshot util for prtscr is gtk
some qt apps dont get styled(one example is kde sound settings)
holding power button shuts down without giving any menu
darkwindow and one other hting has a version mismatch(check logs)
the cursor issue seems fixed maybe?
can ou make waybar track the active apps of each workspace independently
when chrome or another app opens a file manager for download choosing etc, it should use dolphin, not whatever gtk app its using
wallpaper change only works when i use the keybind, not when i swipe to change workspace(is this not possible using real hyperland fucntionality rather than scripts?, if not, do not have some sort of daemon checking every time interval, use somthing event based)

done:
- volume/bluetooth/battery/network/clock waybar popups via plasmawindowed (Qt plasma applets)
- waybar icons for volume, bluetooth, battery, network, clock
- rofi close on mouse movement (-unfocus-exit on SUPER+d launcher)
- howdy for hyprlock (PAM)
- super+` show desktop
- Hypr-DarkWindow for transparency with opaque text
- volume/brightness on-screen popups via avizo (volumectl/lightctl + avizo-service)
- oxygen sound on volume key press
- screen recording / xdg-open portal fix (removed duplicate xdg-desktop-portal-hyprland)
- notifications via mako (home-manager)
- power menu on power button (logind ignore + XF86PowerOff -> wofi menu)
- fixed scripts: trackpad toggle uses hyprctl eval, show desktop uses official hyprland pattern, qt-popup for all waybar menus
- mamba shell init fixed (MAMBA_EXE)
- polkit kde agent wired in
- super+e/r/f workspace switching with wallpaper script
- super+P -> wdisplays for temporary monitor layout
- plasma login: howdy for unlock, password for login
- waybar icon positioning fixed
- migrated to ppd (power-profiles-daemon)
- display configuration error (missing kitemmodels)
- removed trackpad toggle
- replaced rofi with albert (Qt-based)
- run mcontrolcenter on startup
- fixed UI auth for systemd-run0 (added password fallback)
- fixed volume notifications (managed avizo with systemd service)

still todo:
- figure out why after logging in with sddm/plasma-login-manager, the login cursor stays fixed on screen (added no_hardware_cursors; may need more testing)
- desktop sounds for power plug/unplug etc (beyond volume key press)
- switch from kwallet to something else unlocked with hyprland
- settings app for multi monitor beyond wdisplays if needed
