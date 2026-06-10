{ config, pkgs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
    ];

    configType = "lua";

    extraConfig = ''

      -- -----------------------------------------------------
      -- Display & Environment
      -- -----------------------------------------------------
      hl.env("XCURSOR_SIZE", "24")
      hl.env("HYPRCURSOR_SIZE", "24")
      hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

      hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
      })

      -- -----------------------------------------------------
      -- General & Layout
      -- -----------------------------------------------------
      hl.config({
        general = {
          gaps_in = 4,
          gaps_out = 4,
          border_size = 2,
          col = {
            active_border = "rgba(94e2d5ff)",
            inactive_border = "rgba(1e1e2e00)",
          },
          layout = "scrolling",
        },
        scrolling = {
          follow_focus = true,
          fullscreen_on_one_column = false,
          follow_min_visible = 0.01,
        },
        decoration = {
          rounding = 0,
          active_opacity = 1.0,
          inactive_opacity = 1.0,
          shadow = {
            enabled = false,
          },
          blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = true,
          },
        },
        cursor = {
          no_warps = true,
          no_hardware_cursors = 1,
          zoom_detached_camera = false,
        },
        animations = {
          enabled = true,
        },
        input = {
          kb_layout = "us",
          follow_mouse = 1,
          accel_profile = "flat",
          focus_on_close = 1,
          sensitivity = 0.7,
          touchpad = {
            natural_scroll = true,
            tap_to_click = false,
          },
        },
        misc = {
          focus_on_activate = true,
          middle_click_paste = false
        },
      })

      hl.curve("myBezier", {
        type = "bezier",
        points = {
          { 0.05, 0.9 },
          { 0.1, 1.05 },
        },
      })

      hl.animation({ leaf = "windows", enabled = true, speed = 3.5, bezier = "myBezier" })
      hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "default", style = "popin 80%" })
      hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
      hl.animation({ leaf = "borderangle", enabled = true, speed = 4, bezier = "default" })
      hl.animation({ leaf = "fade", enabled = true, speed = 3.5, bezier = "default" })
      hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slidevert" })

      -- -----------------------------------------------------
      -- Gestures
      -- -----------------------------------------------------
      hl.gesture({
        fingers = 3,
        direction = "pinch",
        action = "cursorZoom",
        zoom_level = 1,
        mode = "live",
      })
      hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move", scale = 3.0 })
      hl.gesture({ fingers = 3, direction = "vertical", action = "workspace", scale = 2.0 })

      -- -----------------------------------------------------
      -- Workspaces
      -- -----------------------------------------------------

      hl.workspace_rule({ workspace = "1", default = true, persistent = true })
      hl.workspace_rule({ workspace = "2", persistent = true })
      hl.workspace_rule({ workspace = "3", persistent = true })

      -- -----------------------------------------------------
      -- Window Rules
      -- -----------------------------------------------------
      hl.window_rule({
        name = "qt-volume-popup",
        match = { title = ".*Volume.*" },
        float = true,
        size = { 380, 460 },
        move = { "monitor_w-window_w-12", 32 },
        opacity = "0.97 0.97",
      })
      hl.window_rule({
        name = "qt-bluetooth-popup",
        match = { title = ".*Bluetooth.*" },
        float = true,
        size = { 380, 460 },
        move = { "monitor_w-window_w-12", 32 },
        opacity = "0.97 0.97",
      })
      hl.window_rule({
        name = "qt-plasmawindowed-popup",
        match = { class = "^org\\.kde\\.plasmawindowed.*$" },
        float = true,
        size = { 380, 460 },
        move = { "monitor_w-window_w-12", 32 },
        opacity = "0.97 0.97",
      })
      hl.window_rule({
        name = "menu-opacity",
        match = { title = "^.*[Mm]enu.*$" },
        opacity = "0.97 0.97",
      })
      hl.window_rule({
        name = "polkit-auth-dialogs",
        match = { class = "^(hyprpolkitagent|polkit-kde-authentication-agent.*)$" },
        float = true,
        center = true,
        opacity = "1 1",
      })

      -- -----------------------------------------------------
      -- Autostart
      -- -----------------------------------------------------
      hl.on("hyprland.start", function()
        hl.exec_cmd("albert")
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
        hl.exec_cmd("~/.config/hypr/scripts/wallpaper_init.sh")
        hl.exec_cmd("bash -lc '~/.config/hypr/scripts/session-restore.sh &'")
      end)

      hl.on("hyprland.shutdown", function()
        hl.exec_cmd("~/.config/hypr/scripts/session-save.sh")
      end)

      -- -----------------------------------------------------
      -- Keybindings
      -- -----------------------------------------------------
      local mainMod = "SUPER"


      hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("albert toggle"), { release = true })

      hl.bind(mainMod .. " + Escape", hl.dsp.window.close())
      hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd("hyprctl activewindow -j | jq -r '.pid' | xargs kill -9"))

      hl.bind(mainMod .. " + W", hl.dsp.window.move({ direction = "up" }))
      hl.bind(mainMod .. " + A", hl.dsp.window.move({ direction = "left" }))
      hl.bind(mainMod .. " + S", hl.dsp.window.move({ direction = "down" }))
      hl.bind(mainMod .. " + D", hl.dsp.window.move({ direction = "right" }))

      hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_workspace.sh 1"))
      hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_workspace.sh 2"))
      hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_workspace.sh 3"))

      hl.bind(mainMod .. " + SHIFT + E", hl.dsp.window.move({ workspace = 1 }))
      hl.bind(mainMod .. " + SHIFT + R", hl.dsp.window.move({ workspace = 2 }))
      hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.move({ workspace = 3 }))

      hl.bind(mainMod .. " + GRAVE", hl.dsp.exec_cmd("~/.config/hypr/scripts/show_desktop.sh"))

      hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -unfocus-exit -theme ~/.config/rofi/spotlight.rasi | cliphist decode | wl-copy"))

      hl.bind("code:161", hl.dsp.exec_cmd("hyprctl reload"))
      hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-region.sh"))

      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.resize(), { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.drag(), { mouse = true })

      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-key.sh mute"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-key.sh down"), { locked = true, repeating = true })
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-key.sh up"), { locked = true, repeating = true })
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("volumectl -d -m toggle-mute"), { locked = true, repeating = true })

      local brightnessUp = hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-key.sh up")
      local brightnessDown = hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-key.sh down")
      local brightnessOpts = { locked = true, repeating = true }

      hl.bind("XF86MonBrightnessUp", brightnessUp, brightnessOpts)
      hl.bind("XF86MonBrightnessDown", brightnessDown, brightnessOpts)
      -- Linux KEY_BRIGHTNESSUP/DOWN (224/225) when Fn keys skip XF86* symlinks
      hl.bind("code:224", brightnessDown, brightnessOpts)
      hl.bind("code:225", brightnessUp, brightnessOpts)

      hl.bind("XF86PowerOff", hl.dsp.exec_cmd("/etc/power_menu.sh"), { locked = true })
      hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("kcmshell6 kcm_kscreen"), { locked = true })
    '';
  };
}
