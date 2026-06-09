{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    style = ''
      @define-color base   #1e1e2e;
      @define-color text   #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color teal      #94e2d5;

      * {
        font-family: "FiraCode Nerd Font", "Inter", "Sans", sans-serif;
        font-size: 14px;
        min-height: 0;
      }

      window#waybar {
        background-color: @base;
        color: @text;
      }

      #workspaces button {
        padding: 0 5px;
        color: @subtext0;
        background: transparent;
        border: none;
      }
      #workspaces button.active {
        color: @teal;
      }

      #workspaces button .taskbar button {
        color: @text;
        padding: 0 4px;
        background: transparent;
        border: none;
      }
      #workspaces button .taskbar button.active {
        color: @teal;
      }

      .modules-right, .modules-center, .modules-left {
        padding: 0 10px;
      }

      #clock, #battery, #pulseaudio, #network, #bluetooth, #cpu, #memory, #custom-notifications {
        padding: 0 10px;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/workspaces#windows"
          "cpu"
          "memory"
        ];

        modules-center = [ ];

        modules-right = [
          "bluetooth"
          "network"
          "pulseaudio"
          "custom/notifications"
          "tray"
          "battery"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "default" = "•";
          };
          persistent-workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
          };
        };

        "hyprland/workspaces#windows" = {
          active-only = true;
          format = "{windows}";
          workspace-taskbar = {
            enable = true;
            update-active-window = true;
            format = "{icon}";
            icon-size = 16;
            icon-theme = "breeze-dark";
            orientation = "horizontal";
            on-click-window = "activate";
            on-click-middle-window = "close";
          };
        };

        "cpu" = {
          format = "CPU {usage}%";
        };

        "memory" = {
          format = "RAM {}%";
        };

        "network" = {
          format-wifi = "󰖩";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          tooltip-format = "⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
          interval = 1;
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh network";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 mute";
          format-icons = {
            headphone = "󰋋";
            handsfree = "󰋎";
            headset = "󰋎";
            phone = "󰄜";
            portable = "󰦧";
            car = "󰄋";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          tooltip-format = "{desc} · {volume}%";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh volume";
        };

        "custom/notifications" = {
          format = "󰂚";
          tooltip = "Notification history";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh notifications";
        };

        "bluetooth" = {
          format = "󰂯 {status}";
          format-off = "󰂲 off";
          format-on = "󰂯 on";
          format-connected = "󰂱 {num_connections}";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh bluetooth";
        };

        "battery" = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          states = {
            warning = 30;
            critical = 15;
          };
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh battery";
        };

        "clock" = {
          format = "{:%a %d/%b %m  %H:%M}";
          interval = 1;
          tooltip-format = "{:%A, %d %B %Y  %H:%M:%S}";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh clock";
        };

        "tray" = {
          icon-size = 16;
          spacing = 10;
        };
      };
    };
  };
}
