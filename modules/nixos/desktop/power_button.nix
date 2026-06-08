{ config, pkgs, ... }:
{
  # Install wofi for graphical power menu and kdialog for chooser
  environment.systemPackages = [ pkgs.wofi pkgs.kdialog pkgs.kde-cli-tools ];

  # Power menu script placed in /etc/power_menu.sh
  environment.etc."power_menu.sh".text = ''
    #!/usr/bin/env bash
    options=$(printf "Shutdown\nReboot\nLogout\nSuspend\n")
    # Use wofi fullscreen dmenu
    choice=$(echo "$options" | wofi --dmenu -p "Power Menu" --width 100% --height 100% --prompt "Power Menu")
    case "$choice" in
      Shutdown) systemctl poweroff ;;
      Reboot)   systemctl reboot   ;;
      Logout)   kill -9 -1 ;;
      Suspend)  systemctl suspend  ;;
    esac
  '';
  environment.etc."power_menu.sh".mode = "0755";

  # Systemd service to trigger the menu on power key press
  systemd.services.power-button-gui = {
    description = "Show graphical power menu on power key";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.coreutils}/bin/bash /etc/power_menu.sh";
    };
    # Make logind ignore the default power key handling
    preStart = "${pkgs.systemd}/bin/loginctl set-power-key-ignore false";
  };
}
