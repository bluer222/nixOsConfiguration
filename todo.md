Note to agent: avoid gnome and gtk apps like the plague. prefer qt or hyprland native tools(generally qt, hyprland native if it is clearly better than the qt option)

 todo:
 - (future) style inital login to look like the bgrt screen with the password *'s where the loading spinner would be, and a nixos logo somewere(naybe a bit below the password). (you can read the image from /sys/firmware/acpi/bgrt/image).
 - when i use hyprland global zoom with three finger, applications also triger thier built in two finger zoom.
 - some of the power menu options dont work 
 - install whats necessary for wifi settings to work(rn just empty)
 - logins after the initial login stuff takes longer to start up(eg waybar doesnt start until like 60s after login), why, how fix
 - use hyprsession or other to save session before shutdown, logout, etc(just add it to power menu scripts). if using hyprsession: do not do saving at an interval, only keep latest session, generally the point is just to restore whatever it was when i last logged out, so configure keeping that in mind
 - keybind to toggle darkwindow effect
 - sleep blocking in the battery plasma windowed doesnt work