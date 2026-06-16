Note to agent: avoid gnome and gtk apps like the plague. prefer qt or hyprland native tools(generally qt, hyprland native if it is clearly better than the qt option)

 todo:
 - (future) style inital login to look like the bgrt screen with the password *'s where the loading spinner would be, and a nixos logo somewere(naybe a bit below the password). (you can read the image from /sys/firmware/acpi/bgrt/image).
 - when i use hyprland global zoom with three finger, applications also triger thier built in two finger reaction.(maybe unfixable)
 - use hyprsession or other to save session before shutdown, logout, etc(just add it to power menu scripts). if using hyprsession: do not do saving at an interval, only keep latest session, generally the point is just to restore whatever it was when i last logged out, so configure keeping that in mind
 - set darkwindow chromakey to be the catppuccin Macchiato bg color
 - keybind to toggle darkwindow effect
 - open games on desk 2(lutris, steam etc)
 - fix bwrap for lutris and steam(i thought using uwsm would fix this but clearly not)
 - theme qt apps(either kvantium or qt5ct+qt6ct) using catppuccin Macchiato
   - some are themed rn but its bad, maybe switched from kvantium to qt5ct/qt6ct. also why do electron apps think the system is set to a light mode?
 - waybar takes a while to start
 - xfce session doest work because it cant find xstart or somthing
 - addy hyprpicker, trigger with super+c
 - strip out plasma-windowed
    - hyprpwcenter for audio(in nixpkgs, uses pipewire)
    - gazelle-tui for network(has a flake in https://github.com/Zeus-Deus/gazelle-tui, uses networkmanager)
    - maybe just remove bluetooth applet and just use albert(depends on BlueZ)