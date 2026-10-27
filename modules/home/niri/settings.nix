{ config, pkgs, lib, ... }:

let
  helper = "${pkgs.niri-helper}/bin/niri-helper";
  home = config.home.homeDirectory;
in {
  programs.niri = {
    # Validate generated KDL against the same nixpkgs niri used at runtime.
    package = pkgs.niri;
    settings = {
      # Force compositor rendering onto the Intel iGPU. Numbered renderD*
      # nodes swap when NVIDIA enumerates first, which ignores eDP-1.
      debug = {
        render-drm-device = "/dev/dri/by-path/pci-0000:00:02.0-render";
        ignore-drm-device = "/dev/dri/by-path/pci-0000:01:00.0-render";
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
        variable-refresh-rate = true;
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };

      layout = {
        gaps = 4;
        # NOTE: do NOT enable empty-workspace-above-first. Niri exposes
        # unnamed workspaces to the bar with an index-derived name, so the
        # dynamic above-first desk also calls itself "1" — duplicating real
        # desk "1" and breaking Noctalia's workspace matching (ghost pill).
        # The persistent "0" desk below plays the same role with a unique name.
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
        # "0" is the top wraparound slot (swipe down from 1 lands here and
        # bounces to 3). Persistent with a unique name so it never collides
        # in Noctalia's matching; hidden via hide_when_empty. "1"-"3" are
        # the everyday desks. Utility desks (persistent so references always
        # resolve):
        # "desktop" is the show-desktop target, "trash" stages windows for
        # delayed close. Non-numeric names keep them unambiguous as
        # references — Niri resolves numeric references by POSITION, which
        # shifts as dynamic workspaces come and go ("0" is only ever
        # compared/resolved by exact name inside niri-helper, never passed
        # to Niri as a positional reference). All stay hidden via
        # hide_when_empty.
        # Never navigate to utility desks directly; wrap.go and show-desktop
        # own them. Numbered desks are addressed through
        # `niri-helper goto-desk|move-to-desk`, never bare strings.
        "0" = { };
        "1" = { };
        "2" = { };
        "3" = { };
        "desktop" = { };
        "trash" = { };
      };

      screenshot-path = "${home}/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";

      # Hotkey overlay still useful while learning niri binds.
      hotkey-overlay.skip-at-startup = true;

      binds = {
        # Super tap (keydown→keyup, no other keys) is handled by niri-helper

        "Mod+Space".action.toggle-window-floating = { };

        # Windows
        # Soft-close: hide + queue a real close in 30s, Super+Z undoes.
        # Shift+Escape is instant graceful close, Ctrl+Escape is SIGKILL.
        "Mod+Escape".action.spawn = [ helper "soft-close" ];
        "Mod+Z".action.spawn = [ helper "undo-close" ];
        "Mod+Shift+Escape".action.close-window = { };
        "Mod+Ctrl+Escape".action.spawn = [ helper "kill-focused" ];

        "Mod+W".action.move-window-up = { };
        "Mod+S".action.move-window-down = { };
        "Mod+A".action.move-column-left = { };
        "Mod+D".action.move-column-right = { };

        "Mod+M".action.maximize-column = { };
        # Desk jumps go through the helper: Niri resolves numeric references
        # by position (shifted by the pinned above-first workspace), so the
        # daemon resolves each desk NAME to its current index first.
        "Mod+E".action.spawn = [ helper "goto-desk" "1" ];
        "Mod+R".action.spawn = [ helper "goto-desk" "2" ];
        "Mod+F".action.spawn = [ helper "goto-desk" "3" ];

        "Mod+Shift+E".action.spawn = [ helper "move-to-desk" "1" ];
        "Mod+Shift+R".action.spawn = [ helper "move-to-desk" "2" ];
        "Mod+Shift+F".action.spawn = [ helper "move-to-desk" "3" ];

        "Mod+Grave".action.spawn = [ helper "show-desktop" ];
        "Mod+Tab".action.toggle-overview = { };
        "Mod+Comma".action.spawn-sh = "noctalia msg settings-toggle";

        "Mod+V".action.spawn-sh = "noctalia msg panel-toggle clipboard";
        "Mod+C".action.spawn-sh = "hyprpicker -a";

        # Keyboard pointer: bisect the output, then click. 0.4.1 has no
        # --drag yet, so drags stay in the bisect click keys.
        "Mod+Q".action.spawn = [ (lib.getExe pkgs.wl-kbptr) ];

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
