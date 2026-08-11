{ config, pkgs, lib, ... }:

let
  helper = "${pkgs.niri-helper}/bin/niri-helper";
  home = config.home.homeDirectory;
in {
  programs.niri = {
    # Validate generated KDL against the same nixpkgs niri used at runtime.
    package = pkgs.niri;
    settings = {
      prefer-no-csd = true;

      input = {
        keyboard.xkb.layout = "us";
        mouse = {
          accel-profile = "flat";
          accel-speed = 0.7;
        };
        touchpad = {
          natural-scroll = true;
          tap = false;
          dwt = false;
          accel-profile = "flat";
          accel-speed = 0.7;
          click-method = "button-areas";
        };
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "100%";
        };
      };

      animations = {
        #faster
        slowdown = 0.6;
      };

      outputs."eDP-1" = {
        scale = 1.0;
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };

      layout = {
        gaps = 4;
        focus-ring = {
          enable = false;
        };
        border = {
          enable = true;
          width = 4;
          active.color = "#94e2d5";
          inactive.color = "#1e1e2e00";
        };
        default-column-width.proportion = 50.0;
      };

      # Named workspaces; "desktop" is the show-desktop target (hidden in waybar).
      workspaces = {
        "1" = { };
        "2" = { };
        "3" = { };
        "desktop" = { };
      };

      screenshot-path = "${home}/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";

      # Hotkey overlay still useful while learning niri binds.
      hotkey-overlay.skip-at-startup = true;

      binds = {
        # Super tap (keydown→keyup, no other keys) is handled by niri-helper.
        # Mod+Space remains as a fallback.
        "Mod+Space".action.spawn = [ "albert" "toggle" ];

        # Windows
        "Mod+Escape".action.close-window = { };
        "Mod+Shift+Escape".action.spawn = [ helper "kill-focused" ];

        "Mod+W".action.move-window-up = { };
        "Mod+S".action.move-window-down = { };
        "Mod+A".action.move-column-left = { };
        "Mod+D".action.move-column-right = { };

        "Mod+M".action.maximize-column = { };
        "Mod+E".action.focus-workspace = "1";
        "Mod+R".action.focus-workspace = "2";
        "Mod+F".action.focus-workspace = "3";

        "Mod+Shift+E".action.move-window-to-workspace = "1";
        "Mod+Shift+R".action.move-window-to-workspace = "2";
        "Mod+Shift+F".action.move-window-to-workspace = "3";

        "Mod+Grave".action.spawn = [ helper "show-desktop" ];
        "Mod+Tab".action.toggle-overview = { };

        "Mod+V".action.spawn-sh = "cliphist list | rofi -dmenu -unfocus-exit -theme ~/.config/rofi/spotlight.rasi | cliphist decode | wl-copy";

        # Screenshots (niri built-in) + OCR
        "Print".action.screenshot = { };
        "Alt+Print".action.screenshot-window = { };
        "Ctrl+Print".action.screenshot-screen = { };
        "Mod+Print".action.spawn = [ helper "ocr" ];

        # Media / brightness (work while locked)
        "XF86AudioMute".action.spawn = [ helper "volume" "mute" ];
        "XF86AudioMute".allow-when-locked = true;
        "XF86AudioLowerVolume".action.spawn = [ helper "volume" "down" ];
        "XF86AudioLowerVolume".allow-when-locked = true;
        "XF86AudioRaiseVolume".action.spawn = [ helper "volume" "up" ];
        "XF86AudioRaiseVolume".allow-when-locked = true;
        "XF86AudioMicMute".action.spawn = [ helper "volume" "mic-mute" ];
        "XF86AudioMicMute".allow-when-locked = true;

        "XF86MonBrightnessUp".action.spawn = [ "lightctl" "-d" "up" ];
        "XF86MonBrightnessUp".allow-when-locked = true;
        "XF86MonBrightnessDown".action.spawn = [ "lightctl" "-d" "down" ];
        "XF86MonBrightnessDown".allow-when-locked = true;

        "XF86PowerOff".action.spawn = [ "wleave" ];
        "XF86PowerOff".allow-when-locked = true;
      };

      window-rules = [
        {
          matches = [{ app-id = "^org\\.kde\\.polkit-kde-authentication-agent-1$"; }];
          open-floating = true;
        }
      ];

      xwayland-satellite = {
        enable = true;
        path = lib.getExe pkgs.xwayland-satellite;
      };
    };
  };
}
