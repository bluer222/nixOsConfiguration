{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.wofi ];

  environment.etc."power_menu.sh".text = ''
    #!/usr/bin/env bash
    export PATH=$PATH:/run/current-system/sw/bin
    choice=$(printf "Logout\nSuspend\nReboot\nShutdown\n" | wofi --dmenu --prompt "Power Menu" --width 320 --height 240 --hide-scroll --allow-images)
    case "$choice" in
      Logout)   loginctl terminate-user "$USER" ;;
      Suspend)  systemctl suspend ;;
      Reboot)   systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
    esac
  '';
  environment.etc."power_menu.sh".mode = "0755";

  # Let Hyprland handle the power key instead of shutting down immediately.
  services.logind.settings.Login.HandlePowerKey = "ignore";
}
