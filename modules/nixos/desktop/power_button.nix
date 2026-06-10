{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.wofi ];

  environment.etc."power_menu.sh".text = ''
    #!/usr/bin/env bash
    choice=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown\n" | /run/current-system/sw/bin/wofi \
      --dmenu \
      --prompt "Power Menu" \
      --width 320 \
      --height 280 \
      --hide-scroll \
      --style /etc/wofi/style.css | tr -d '\n')
    case "$choice" in
      Lock)     loginctl lock-session ;;
      Logout) /etc/hypr-logout.sh ;;
      Suspend)  systemctl suspend ;;
      Reboot)   systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
    esac
  '';
  environment.etc."power_menu.sh".mode = "0755";

  environment.etc."wofi/style.css".text = ''
    * {
      font-family: "Inter", sans-serif;
      font-size: 14px;
    }

    window {
      background-color: rgba(30, 30, 46, 0.95);
      color: #cdd6f4;
      border: 2px solid #94e2d5;
      border-radius: 12px;
      margin: 0;
      padding: 12px;
    }

    #input {
      background-color: #313244;
      color: #cdd6f4;
      border: none;
      border-radius: 8px;
      padding: 8px 12px;
      margin-bottom: 8px;
    }

    #inner-box {
      background-color: transparent;
      padding: 4px;
    }

    #entry {
      padding: 8px 12px;
      border-radius: 8px;
    }

    #entry:selected {
      background-color: #313244;
      color: #94e2d5;
    }
  '';

  services.logind.settings.Login.HandlePowerKey = "ignore";
}
