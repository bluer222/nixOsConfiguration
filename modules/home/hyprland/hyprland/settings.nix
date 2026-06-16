{ config, lib, ... }:

let
  home = config.home.homeDirectory;
  scripts = "${home}/.config/hypr/scripts";
in {
  wayland.windowManager.hyprland.settings = {
    mainMod = {
      _var = "SUPER";
    };

    monitor = {
      output = "";
      mode = "preferred";
      position = "auto";
      scale = 1;
    };

    config = {
      general = {
        gaps_in = 2;
        gaps_out = 4;
        border_size = 2;
        col = {
          active_border = "rgba(94e2d5ff)";
          inactive_border = "rgba(1e1e2e00)";
        };
        layout = "scrolling";
      };
      scrolling = {
        follow_focus = true;
        fullscreen_on_one_column = false;
        follow_min_visible = 0.01;
      };
      decoration = {
        rounding = 0;
        active_opacity = 1;
        inactive_opacity = 1;
        shadow = {
          enabled = false;
        };
        blur = {
          enabled = true;
          size = 8;
          passes = 4;
          new_optimizations = true;
          ignore_opacity = true;
          xray = false;
        };
      };
      cursor = {
        no_warps = true;
        no_hardware_cursors = 1;
        zoom_detached_camera = false;
      };
      animations = {
        enabled = true;
      };
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        accel_profile = "flat";
        focus_on_close = 1;
        sensitivity = 0.7;
        touchpad = {
          natural_scroll = true;
          tap_to_click = false;
          disable_while_typing = false;
        };
      };
      misc = {
        focus_on_activate = true;
        middle_click_paste = false;
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };
    };

    animation = [
      {
        leaf = "windows";
        enabled = true;
        speed = 3.5;
        bezier = "default";
      }
      {
        leaf = "windowsOut";
        enabled = true;
        speed = 3.5;
        bezier = "default";
        style = "popin 80%";
      }
      {
        leaf = "border";
        enabled = true;
        speed = 5;
        bezier = "default";
      }
      {
        leaf = "borderangle";
        enabled = true;
        speed = 4;
        bezier = "default";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 3.5;
        bezier = "default";
      }
      {
        leaf = "workspaces";
        enabled = true;
        speed = 3;
        bezier = "default";
        style = "slidevert";
      }
    ];

    gesture = [
      {
        fingers = 3;
        direction = "pinch";
        action = "cursorZoom";
        zoom_level = 1;
        mode = "live";
      }
      {
        fingers = 3;
        direction = "horizontal";
        action = "scroll_move";
        scale = 3.0;
      }
      {
        fingers = 3;
        direction = "vertical";
        action = "workspace";
        scale = 2.0;
      }
    ];

    workspace_rule = [
      {
        workspace = "1";
        default = true;
        persistent = true;
      }
      {
        workspace = "2";
        persistent = true;
      }
      {
        workspace = "3";
        persistent = true;
      }
      {
        workspace = "4";
        persistent = false;
        gaps_out = 0;
        gaps_in = 0;
      }
    ];
    
    window_rule = [
      {
        name = "polkit-auth-dialogs";
        match = {
          class = "^hyprpolkitagent$";
        };
        float = true;
        center = true;
      }
    ];
  };
}
