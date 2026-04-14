{ config, pkgs, inputs, ... }:

let
  hyprland-pkg = pkgs.hyprland;

  # Hyprchroma v3.3 — grouped adaptive chromakey tint
  hyprchroma-src = pkgs.fetchFromGitHub {
    owner = "RomeoCavazza";
    repo = "Hyprchroma";
    rev = "a0241fd4c25e2a4d40a4cbfe8db2e30fc8e98233";
    hash = "sha256-PYBD6lhPdVsf1iPpM1+ikRSE7ce+LKevVwsyDFfFzKA=";
  };

  hyprchroma = pkgs.stdenv.mkDerivation {
    pname = "hyprchroma";
    version = "3.3.1";
    src = hyprchroma-src;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ hyprland-pkg ] ++ hyprland-pkg.buildInputs;
    buildPhase = ''
      g++ -shared -fPIC -std=c++2b -O2 \
        $(pkg-config --cflags hyprland pixman-1 libdrm) \
        -DWLR_USE_UNSTABLE \
        src/main.cpp \
        -o libhyprchroma.so
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp libhyprchroma.so $out/lib/
    '';
  };

in
{
  home.packages = with pkgs; [
    foot
    nemo
    rofi-wayland
    brightnessctl
    playerctl
    grim
    slurp
    libnotify
    hypridle
    hyprlock
    hyprpaper
    cava
    eza
    bat
    fzf
    jq
    ripgrep
    yazi
    starship
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [
      hyprchroma
      pkgs.hyprlandPlugins.hyprspace
    ];

    settings = {
      monitor = ",preferred,auto,1.25";

      # ENV
      env = [
        "LIBSEAT_BACKEND,logind"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "SDL_VIDEODRIVER,wayland"
        "QT_QPA_PLATFORM,wayland"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_STYLE_OVERRIDE,kvantum"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "ELECTRON_ENABLE_WAYLAND,1"
      ];

      # AUTOSTART
      "exec-once" = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY"
        "sh -lc 'pkill waybar; (waybar </dev/null >/dev/null 2>&1 & disown)'"
        "systemctl --user restart hypridle.service"
      ];

      # APPS
      "$terminal" = "foot";
      "$fileManager" = "nemo";
      "$menu" = "rofi -show drun";

      # THEME / VISUALS
      general = {
        layout = "scrolling"; # Using built-in scrolling layout
        resize_on_border = true;
        "col.active_border" = "rgba(94e2d5ff)";
        "col.inactive_border" = "rgba(ffffff14)";
        border_size = 2;
        gaps_in = 8;
        gaps_out = 16;
      };

      scrolling = {
        column_width = 0.5;
        fullscreen_on_one_column = true;
      };

      decoration = {
        rounding = 12;
        active_opacity = 0.57;
        inactive_opacity = 0.57;
        blur = {
          enabled = true;
          size = 5;
          passes = 5;
          ignore_opacity = true;
          noise = 0.01;
          contrast = 1.0;
          brightness = 1.2;
          xray = true;
          vibrancy = 0.10;
        };
        shadow = {
          enabled = true;
          range = 30;
          render_power = 3;
          color = "rgba(00000022)";
        };
      };

      # PLUGIN CONFIG
      plugin = {
        darkwindow = {
          tint_r = 0.20;
          tint_g = 0.70;
          tint_b = 1.00;
          tint_strength = 0.058;
          protect_brights = 1.00;
          bright_threshold = 0.55;
          bright_knee = 0.35;
          protect_saturated = 1.00;
          saturation_threshold = 0.05;
          saturation_knee = 0.25;
          enable_on_fullscreen = 0;
          tint_all_surfaces = 1;
        };
        overview = {
          panelColor = "rgba(1e1e2eef)";
          workspaceActiveBackground = "rgba(0d141b61)";
          workspaceInactiveBackground = "rgba(0d141b47)";
          workspaceActiveBorder = "rgba(94e2d5ff)";
          workspaceInactiveBorder = "rgba(b7bcc638)";
          workspaceBorderSize = 2;
          drawActiveWorkspace = true;
          workspaceActiveColor = "rgba(94e2d5ff)";
          autoScroll = true;
          exitOnClick = true;
          switchOnDrop = true;
          exitOnSwitch = true;
          autoDrag = true;
        };
      };

      # INPUT - US Layout
      input = {
        kb_layout = "us";
        kb_options = "ctrl:nocaps";
        follow_mouse = 1;
        natural_scroll = "yes";
        touchpad.natural_scroll = "yes";
      };

      # BINDS
      "$mod" = "SUPER";
      bind = [
        # System/Apps
        "$mod, Return, exec, $terminal"
        "$mod, Escape, killactive"
        "$mod, Tab, exec, $fileManager"
        "$mod, Space, exec, $menu"
        "$mod, F, togglefloating"
        "$mod, V, fullscreen, 0"
        "$mod, L, exec, hyprlock"
        "$mod, P, exec, hyprctl dispatch togglechromakey"
        "$mod, D, exec, hyprctl dispatch overview:toggle"

        # Navigation (Standard)
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Scrolling Layout Navigation
        "$mod, period, layoutmsg, move +col"
        "$mod, comma, layoutmsg, move -col"
        "$mod SHIFT, period, layoutmsg, swapcol r"
        "$mod SHIFT, comma, layoutmsg, swapcol l"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # Function keys
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+"
        ", XF86AudioPlay, exec, playerctl play-pause"
        
        # Screenshot
        ", Print, exec, mkdir -p ~/Images && grim ~/Images/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png && notify-send 'Screenshot saved'"
      ];

      gesture = [
        "3, left, dispatcher, layoutmsg, move +col"
        "3, right, dispatcher, layoutmsg, move -col"
      ];

      bindm = [
        "$mod, mouse:272, resizewindow"
        "$mod, mouse:273, movewindow"
      ];
    };
  };

  # Waybar
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      height = 36;
      modules-left = [ "cpu" "memory" "battery" ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right = [ "pulseaudio" "network" "tray" "clock" ];
    }];
  };

  # Starship
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      format = "[░▒▓](#94e2d5)[  ](bg:#94e2d5 fg:#090c0c)[](fg:#94e2d5 bg:#1d2230)$directory[](fg:#1d2230 bg:none)$character";
      directory = {
        style = "fg:#94e2d5 bg:#1d2230";
        format = "[ $path ]($style)";
      };
      character = {
        success_symbol = "[ ❯](bold #94e2d5)";
        error_symbol = "[ ❯](bold #ff0055)";
      };
    };
  };

  programs.bat.enable = true;
  programs.fzf.enable = true;
  programs.yazi.enable = true;
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    icons = "auto";
  };
}
