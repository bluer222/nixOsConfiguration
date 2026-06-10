{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.wmenu ];

  environment.etc."power_menu.sh".text = ''
    #!/usr/bin/env bash
    choice=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown\n" | /run/current-system/sw/bin/wmenu -p "Power Menu" | tr -d '\n')
    case "$choice" in
      Lock)     loginctl lock-session ;;
      Logout) /etc/hypr-logout.sh ;;
      Suspend)  systemctl suspend ;;
      Reboot)   systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
    esac
  '';
  environment.etc."power_menu.sh".mode = "0755";

  services.logind.settings.Login.HandlePowerKey = "ignore";
}
