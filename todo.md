Note to agent: avoid gnome and gtk apps like the plague. prefer qt or hyprland native tools(generally qt, hyprland native if it is clearly better than the qt option)

 todo:
- it seems like startup stuff just doesnt work anymore(waybar doesnt start, wallpaper doesnt get set)
 - (future) style inital login to look like the bgrt screen with the password *'s where the loading spinner would be, and a nixos logo somewere(naybe a bit below the password). (you can read the image from /sys/firmware/acpi/bgrt/image).
 - when i use hyprland global zoom with three finger, applications also triger thier built in two finger zoom.
 - some of the power menu options dont work(only logout seems to work) 
 - install whats necessary for wifi settings to work(rn just empty)
 - use hyprsession or other to save session before shutdown, logout, etc(just add it to power menu scripts). if using hyprsession: do not do saving at an interval, only keep latest session, generally the point is just to restore whatever it was when i last logged out, so configure keeping that in mind
 - keybind to toggle darkwindow effect
 - sleep blocking in the battery plasma windowed doesnt work
 - ocassionally all chromium based apps crash(including brave)
 - paldsma windowd menus close other apps instead of themselves
 - open games on desk 2(lutris, steam etc)
 - fix bwrap for lutris and steam 
 - reset all qt configurations back to the basics of what should be needed(either kvantium or qt5ct+qt6ct) using catppuccin Macchiato
 - fix kwallet autostart
 - changing volume freeses hyprland for like a minute
 - waybar takes a while to start
 - wallpaper switching broke