Note to agent: avoid gnome and gtk apps like the plague. prefer qt or hyprland native tools(generally qt, hyprland native if it is clearly better than the qt option)

 todo:
- it seems like startup stuff just doesnt work anymore(waybar doesnt start, wallpaper doesnt get set)
 - (future) style inital login to look like the bgrt screen with the password *'s where the loading spinner would be, and a nixos logo somewere(naybe a bit below the password). (you can read the image from /sys/firmware/acpi/bgrt/image).
 - when i use hyprland global zoom with three finger, applications also triger thier built in two finger reaction.
 - some of the power menu options dont work(only logout seems to work) 
 - install whats necessary for wifi settings to work(rn just empty)
 - use hyprsession or other to save session before shutdown, logout, etc(just add it to power menu scripts). if using hyprsession: do not do saving at an interval, only keep latest session, generally the point is just to restore whatever it was when i last logged out, so configure keeping that in mind
 - keybind to toggle darkwindow effect
 - sleep blocking in the battery plasma windowed doesnt work(probably either need to fully embrace hypridle or powerdevil)
 - ocassionally all chromium based apps crash(including brave)
 - open games on desk 2(lutris, steam etc)
 - fix bwrap for lutris and steam 
 - reset all qt configurations back to the basics of what should be needed(either kvantium or qt5ct+qt6ct) using catppuccin Macchiato
 - waybar takes a while to start
 - theming settings in kde settings dont work(optimally we would at least get sound control to work to set powerdevil sounds). 
 - remove all current kwallet stuff and restart with a minimal impleemntation that unlocks on login(see https://wiki.archlinux.org/title/KDE_Wallet)