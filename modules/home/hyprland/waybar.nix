{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    style = ''
      /* Catppuccin Mocha */
      @define-color base   #1e1e2e;
      @define-color mantle #181825;
      @define-color crust  #11111b;
      @define-color text   #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;
      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;
      @define-color overlay0 #6c7086;
      @define-color overlay1 #7f849c;
      @define-color overlay2 #9399b2;
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
        box-shadow: none;
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

      /* Base styling for modules */
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
          "network"
          "pulseaudio"
          "bluetooth"
          "tray"
          "battery"
          "clock"
        ];

        # Tool choice: wlr/taskbar handles window enumeration cleanly inside Waybar.
        # Alternative: nwg-dock or another external panel.
        "wlr/taskbar" = {
          format = "{icon} {name}";
          icon-size = 14;
          on-click = "activate";
          on-click-middle = "close";
        };

        "cpu" = {
          format = "CPU: {usage}%";
        };

        "memory" = {
          format = "RAM: {}%";
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "default" = "";
          };
        };

        # Interval set to 1 for 1-second real-time feel
        "network" = {
          format-wifi = "⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
          format-ethernet = "⇡{bandwidthUpBytes} ⇣{bandwidthDownBytes}";
          format-disconnected = "Offline";
          interval = 1;
          on-click = "nm-connection-editor"; # Wifi configurator
        };

        "pulseaudio" = {
          format = "Vol: {volume}%";
          on-click = "~/.config/hypr/scripts/qt-popup.sh volume";
        };

        "bluetooth" = {
          format = "BT: {status}";
          on-click = "~/.config/hypr/scripts/qt-popup.sh bluetooth";
        };

        "battery" = {
          format = "Bat: {capacity}%";
        };

        # Format: day-of-week, date, month, year, time
        "clock" = {
          format = "{:%w %a / %d %b / %Y  %H:%M}";
        };
        
        "tray" = {
          icon-size = 14;
          spacing = 10;
        };
      };
    };
  };
}
