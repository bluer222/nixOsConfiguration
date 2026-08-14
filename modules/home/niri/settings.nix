{ config, pkgs, lib, ... }:

let
  helper = "${pkgs.niri-helper}/bin/niri-helper";
  home = config.home.homeDirectory;
in {
  programs.niri = {
    # Validate generated KDL against the same nixpkgs niri used at runtime.
    package = pkgs.niri;
    settings = {
      # Force compositor rendering onto the Intel iGPU (stable by-path; not NVIDIA).
      debug = {
        render-drm-device = "/dev/dri/renderD128";
        ignore-drm-device = "/dev/dri/renderD129";
        # Allows notification actions and window activation from Noctalia.
        honor-xdg-activation-with-invalid-serial = [ ];
      };

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
        # Session panel via XF86PowerOff instead.
        power-key-handling.enable = false;
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
          width = 3;
          active.color = "#94e2d5";
          inactive.color = "#1e1e2e";
        };
        shadow.enable = false;
        default-column-width.proportion = 0.5;
        # Stationary noctalia wallpaper sits in the backdrop.
        background-color = "transparent";
      };

      overview = {
        workspace-shadow = {
          enable = false;
        };
      };

      workspaces = {
        "1" = { };
        "2" = { };
        "3" = { };
      };

      screenshot-path = "${home}/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";

      # Hotkey overlay still useful while learning niri binds.
      hotkey-overlay.skip-at-startup = true;

      binds = {
        # Super tap (keydown→keyup, no other keys) is handled by niri-helper

        "Mod+Space".action.toggle-window-floating = { };

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
        "Mod+Comma".action.spawn-sh = "noctalia msg settings-toggle";

        "Mod+V".action.spawn-sh = "noctalia msg panel-toggle clipboard";
        "Mod+C".action.spawn-sh = "hyprpicker -a";

        # Screenshots (Noctalia) + OCR (Noctalia region → tesseract pipe)
        "Print".action.spawn-sh = "noctalia msg screenshot-region";
        "Alt+Print".action.spawn-sh = "noctalia msg screenshot-fullscreen";
        "Ctrl+Print".action.spawn-sh = "noctalia msg screenshot-fullscreen all";
        "Mod+Print".action.spawn = [ helper "ocr" ];

        # Media / brightness (work while locked)
        "XF86AudioMute".action.spawn-sh = "noctalia msg volume-mute";
        "XF86AudioMute".allow-when-locked = true;
        "XF86AudioLowerVolume".action.spawn-sh = "noctalia msg volume-down";
        "XF86AudioLowerVolume".allow-when-locked = true;
        "XF86AudioRaiseVolume".action.spawn-sh = "noctalia msg volume-up";
        "XF86AudioRaiseVolume".allow-when-locked = true;
        "XF86AudioMicMute".action.spawn-sh = "noctalia msg mic-mute";
        "XF86AudioMicMute".allow-when-locked = true;

        "XF86MonBrightnessUp".action.spawn-sh = "noctalia msg brightness-up 1%";
        "XF86MonBrightnessUp".allow-when-locked = true;
        "XF86MonBrightnessDown".action.spawn-sh = "noctalia msg brightness-down 1%";
        "XF86MonBrightnessDown".allow-when-locked = true;

        "XF86PowerOff".action.spawn-sh = "noctalia msg panel-toggle session";
        "XF86PowerOff".allow-when-locked = true;
      };

      window-rules = [
        {
          #no matches = all windows
          #matches = [ ];
          background-effect = {
            blur = true;
            #noise = 0.05;
            #saturation = 3;
          };
        }
        # Games / launchers → workspace 2
        {
          matches = [
            { app-id = "^steam$"; }
            { app-id = "^steam_app_"; }
            { app-id = "^lutris$"; }
            { app-id = "^net\\.lutris\\.Lutris$"; }
            { app-id = "^gamescope$"; }
            { app-id = "^org\\.godotengine\\."; }
            { app-id = "^Godot$"; }
            { app-id = "^heroic$"; }
            { app-id = "^com\\.heroicgameslauncher\\."; }
          ];
          open-on-workspace = "2";
        }
      ];

      layer-rules = [
        {
          matches = [{ namespace = "^noctalia-backdrop$"; }];
          place-within-backdrop = true;
        }
        {
          matches = [{ namespace = "^noctalia-wallpaper$"; }];
          place-within-backdrop = true;
        }
      ];

      xwayland-satellite = {
        enable = true;
        path = lib.getExe pkgs.xwayland-satellite;
      };
    };
  };
}
