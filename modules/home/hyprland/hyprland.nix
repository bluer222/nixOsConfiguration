{ config, pkgs, inputs, lib, ... }:

let
  # Fallback empty string if the package is missing, though we'll try to use the flake output.
  hyprchroma-pkg = inputs.hyprchroma.packages.${pkgs.stdenv.hostPlatform.system}.Hyprchroma;
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    # The prompt requested we load the .so in the plugins block
    plugins = [
      inputs.hyprchroma.packages.${pkgs.stdenv.hostPlatform.system}.Hyprchroma
    ];

    settings = {
      # -----------------------------------------------------
      # Display & Environment
      # -----------------------------------------------------
      # Force Intel iGPU
      env = [
        "AQ_DRM_DEVICES,/dev/dri/intel-igpu:/dev/dri/card0"
        "WLR_DRM_DEVICES,/dev/dri/intel-igpu:/dev/dri/card0"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      # -----------------------------------------------------
      # General & Layout
      # -----------------------------------------------------
      general = {
        gaps_in = 4;
        gaps_out = 4;
        border_size = 2;
        "col.active_border" = "rgba(94e2d5ff)";
        "col.inactive_border" = "rgba(1e1e2e00)";
        
        # Use native scrolling layout (Hyprland 0.45+)
        layout = "scrolling";
      };

      decoration = {
        rounding = 0; # Square corners
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1; # Focus follows mouse
        
        touchpad = {
          natural_scroll = true;
        };
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
        # Horizontal swipe scrolls workspace inherently, vertical switches workspaces
        workspace_swipe_direction_lock = false;
      };

      # -----------------------------------------------------
      # Workspaces & Monitors
      # -----------------------------------------------------
      monitor = ",preferred,auto,1";

      workspace = [
        "1, monitor:eDP-1, default:true"
        "2, monitor:eDP-1"
        "3, monitor:eDP-1"
      ];

      # -----------------------------------------------------
      # Autostart
      # -----------------------------------------------------
      exec-once = [
        "waybar"
        "hypridle"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "~/.config/hypr/scripts/wallpaper_init.sh"
        # Hyprchroma toggle example
        # "hyprctl keyword chromakey_background rgba(0,0,0,1)" 
      ];

      # -----------------------------------------------------
      # Keybindings
      # -----------------------------------------------------
      bind = [
        # Launcher
        "SUPER, SUPER_L, exec, rofi -show drun -theme ~/.config/rofi/spotlight.rasi"
        
        # Window Management
        "SUPER, Escape, killactive"
        "SUPER SHIFT, Escape, exec, hyprctl activewindow -j | jq -r '.pid' | xargs kill -9"
        
        "SUPER, W, movewindow, u"
        "SUPER, A, movewindow, l"
        "SUPER, S, movewindow, d"
        "SUPER, D, movewindow, r"

        # Workspaces (Vertical arrangement conceptually, switching with E/R/F)
        "SUPER, E, workspace, 1"
        "SUPER, R, workspace, 2"
        "SUPER, F, workspace, 3"

        # Moving windows to workspaces
        "SUPER SHIFT, E, movetoworkspace, 1"
        "SUPER SHIFT, R, movetoworkspace, 2"
        "SUPER SHIFT, F, movetoworkspace, 3"

        # Clipboard
        "SUPER, V, exec, cliphist list | rofi -dmenu -theme ~/.config/rofi/spotlight.rasi | cliphist decode | wl-copy"

        # Config Reload
        ", 153, exec, hyprctl reload" # Fn+F12 (KEY_DIRECTION = 153)

        # Screenshot
        ", Print, exec, spectacle -r"
      ];

      # Mouse bindings for move and resize
      bindm = [
        "SUPER, mouse:272, resizewindow" # LMB
        "SUPER, mouse:273, movewindow"   # RMB
      ];

      # Media / Fn Keys
      bindel = [
        ", 113, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" # Fn+F1
        ", 114, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" # Fn+F2
        ", 115, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" # Fn+F3
        ", 248, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" # Fn+F5
      ];
      
      bindl = [
        # Trackpad toggle
        "SUPER CTRL, 201, exec, ~/.config/hypr/scripts/toggle_trackpad.sh" # F24 usually mapped as high keycode, we will match the actual output of Fn+F4. Assuming Super+Ctrl+F24 translates to a keycode we intercept, or we can just bind to the direct key if the compositor sees it. For now, we bind the script.
        # Fn+F7 Settings
        ", 171, exec, systemsettings" # KEY_CONFIG
        # Fn+F11 Display
        "SUPER, P, exec, wdisplays" # using wdisplays or standard display settings
      ];

      # Workspace change triggers wallpaper script
      binde = [
        "SUPER, E, exec, ~/.config/hypr/scripts/change_wallpaper.sh 1"
        "SUPER, R, exec, ~/.config/hypr/scripts/change_wallpaper.sh 2"
        "SUPER, F, exec, ~/.config/hypr/scripts/change_wallpaper.sh 3"
      ];
    };
  };
}
