{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "niri.service" ];
    };
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

      #taskbar {
        min-width: 0;
      }

      #taskbar button {
        color: @text;
        padding: 0 4px;
        background: transparent;
        border: none;
        min-width: 0;
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
          "niri/workspaces"
        ];

        modules-right = [
          "bluetooth"
          "network"
          "pulseaudio"
          "battery"
          "power-profiles-daemon"
          "tray"
          "clock"
        ];

        "wlr/taskbar" = {
          format = "{icon} {title}";
          tooltip-format = "{title}";
          icon-size = 16;
          icon-theme = "breeze-dark";
          ignore-list = [ "Albert" ];
          on-click = "activate";
          on-click-middle = "close";
          truncate = true;
        };

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            default = "•";
          };
          # Hide the show-desktop spare workspace from the switcher.
          ignore-workspaces = [ "desktop" ];
        };

        "cpu" = {
          format = "CPU {usage}%";
        };

        "memory" = {
          format = "RAM {used:0.1f}/{total:0.1f}G";
        };

        "network" = {
          format-wifi = "󰖩  <span color='#289b45'>{bandwidthUpBytes}</span> <span color='#9b1c1c'>{bandwidthDownBytes}</span>";
          format-ethernet = "󰈀  <span color='#289b45'>{bandwidthUpBytes}</span> <span color='#9b1c1c'>{bandwidthDownBytes}</span>";
          format-disconnected = "󰖪";
          tooltip-format = "{ifname} via {gwaddr}";
          interval = 1;
          on-click = "konsole -e nmtui";
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
          on-click = "hyprpwcenter";
        };

        "bluetooth" = {
          format = "󰂯 {status}";
          format-off = "󰂲 off";
          format-on = "󰂯 on";
          format-connected = "󰂱 {num_connections}";
          on-click = "${pkgs.blueman}/bin/blueman-manager";
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
        };

        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}";
          tooltip = true;
          format-icons = {
            default = "  ";
            performance = "  ";
            balanced = "  ";
            power-saver = "  ";
          };
        };

        "tray" = {
          icon-size = 16;
          spacing = 10;
        };

        "clock" = {
          format = "{:%a %d/%b %m/%y  %H:%M}";
          interval = 1;
          tooltip-format = "{:%A, %d %B %Y  %H:%M:%S}";
          on-click = "";
        };
      };
    };
  };
}
