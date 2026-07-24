Note to agent: avoid gnome and gtk apps like the plague. prefer qt or hyprland native tools(generally qt, hyprland native if it is clearly better than the qt option)

 todo:
 - (future) style inital login to look like the bgrt screen with the password *'s where the loading spinner would be, and a nixos logo somewere(naybe a bit below the password). (you can read the image from /sys/firmware/acpi/bgrt/image).
 - when i use hyprland global zoom with three finger, applications also triger thier built in two finger reaction.(maybe unfixable)
 - use hyprsession or other to save session before shutdown, logout, etc(just add it to power menu scripts). if using hyprsession: do not do saving at an interval, only keep latest session, generally the point is just to restore whatever it was when i last logged out, so configure keeping that in mind
 - set darkwindow chromakey to be the catppuccin Macchiato bg color
 - keybind to toggle darkwindow effect
 - open games on desk 2(lutris, steam etc)
 - fix bwrap for lutris and steam(i thought using uwsm would fix this but clearly not)
 - xfce session doest work because it cant find xstart or somthing
 - add hyprpicker, trigger with super+c
 - why does uwsm only work the second time it is run. the first login its jsut black. after that is killed, the second login works. if the second login is killed, the thrd and onward are super laggy(but only for a while, then they become normal)
   - WIP fix: disable seatd (VT fight with logind), retry uwsm finalize until wayland-wm@/graphical-session is active, logout via `uwsm stop` (hyprshutdown was GPF'ing)
   - 2026-07-18: AQ_DRM_DEVICES was intel+nvidia; nvidia has no CRTCs here and can hard-hang Aquamarine (black screen, ignores SIGTERM → hard reset). Now intel-igpu only + DRM wait ExecStartPre + FinalKillSignal=SIGKILL
 - kwallet still not auto unlocked
 - pixelate closing effect
 - super + space to float a window
 - not all apps have the cursor applied(steam)
 