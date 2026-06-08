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
        font-family: "Inter", "Sans", sans-serif;
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

      #taskbar button {
        color: @text;
        padding: 0 4px;
        background: transparent;
        border: none;
      }
      #taskbar button.active {
        color: @teal;
      }

      .modules-right, .modules-center, .modules-left {
        padding: 0 10px;
      }

      #clock, #battery, #pulseaudio, #network, #bluetooth, #cpu, #memory {
        padding: 0 10px;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [
          "wlr/taskbar"
          "cpu"
          "memory"
        ];

        modules-center = [
          "hyprland/workspaces"
        ];

        modules-right = [
          "bluetooth"
          "network"
          "tray"
          "battery"
          "clock"
        ];

        "wlr/taskbar" = {
          format = "{icon} {name}";
          icon-size = 16;
          icon-theme = "breeze-dark";
          on-click = "activate";
          on-click-middle = "close";
        };

        "cpu" = {
          format = "CPU {usage}%";
        };

        "memory" = {
          format = "RAM {}%";
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "default" = "•";
          };
        };

        "network" = {
          format-wifi = "WiFi";
          format-ethernet = "Eth";
          format-disconnected = "Off";
          tooltip-format = "⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
          interval = 1;
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh network";
        };

        "pulseaudio" = {
          format = "Vol {volume}%";
          format-muted = "Vol mute";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh volume";
        };

        "bluetooth" = {
          format = "BT {status}";
          format-off = "BT off";
          format-on = "BT on";
          format-connected = "BT {num_connections}";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh bluetooth";
        };

        "battery" = {
          format = "Bat {capacity}%";
          format-charging = "Bat {capacity}%";
          format-plugged = "Bat {capacity}%";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/qt-popup.sh battery";
        };

        "clock" = {
          format = "{:%a %d %b  %H:%M}";
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
