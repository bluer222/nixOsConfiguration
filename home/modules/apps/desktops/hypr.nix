{ config, pkgs, inputs, ... }:

let
  hyprland-pkg = pkgs.hyprland;

  # Hyprchroma / Darkwindow (Adaptive chromakey tint)
  darkwindow-src = pkgs.fetchFromGitHub {
    owner = "RomeoCavazza";
    repo = "Hyprchroma";
    rev = "a0241fd4c25e2a4d40a4cbfe8db2e30fc8e98233";
    hash = "sha256-PYBD6lhPdVsf1iPpM1+ikRSE7ce+LKevVwsyDFfFzKA=";
  };

  darkwindow = pkgs.stdenv.mkDerivation {
    pname = "darkwindow";
    version = "3.3.1-v054";
    srcs = [ ];
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ hyprland-pkg ] ++ hyprland-pkg.buildInputs;
    buildPhase = ''
      g++ -shared -fPIC -std=c++2b -O2 \
        $(pkg-config --cflags hyprland pixman-1 libdrm) \
        -DWLR_USE_UNSTABLE \
        ${darkwindow-src}/src/main.cpp \
        -o libhypr-darkwindow.so
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp libhypr-darkwindow.so $out/lib/
    '';
  };

  # Hypr-canvas (Infinite canvas)
  hypr-canvas-src = pkgs.fetchFromGitHub {
    owner = "RomeoCavazza";
    repo = "hypr-canvas";
    rev = "08358afacbac9f9a7ac45dc59a1a55188717b55c";
    hash = "sha256-pA6NSjk7SX+tdSY1aWlaI+ygXUl+K/dk1xGB7ok8CIs=";
  };

  hypr-canvas = pkgs.stdenv.mkDerivation {
    pname = "hypr-canvas";
    version = "0.2.0-patched";
    srcs = [ ];
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ hyprland-pkg ] ++ hyprland-pkg.buildInputs;
    buildPhase = ''
      g++ -shared -fPIC -std=c++2b -O2 \
        $(pkg-config --cflags hyprland pixman-1 libdrm) \
        ${hypr-canvas-src}/src/main.cpp ${hypr-canvas-src}/src/canvas.cpp \
        -o hypr-canvas.so
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp hypr-canvas.so $out/lib/
    '';
  };

  # Hyprspace (Overview plugin) from flake
  hyprspace = inputs.hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace;

in
{
  home.packages = with pkgs; [
    rofi
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
    starship
    kdePackages.polkit-kde-agent-1
    # Additional tools from Romeo's config
    chafa
    fd
    wev
    wf-recorder
    sway-contrib.grimshot
    socat
    bottom
    btop
    glances
    htop
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    configType = "lua";
    # conflicts with uwsm
    systemd.enable = false;
    extraConfig = "-- Managed by hyprland.lua";
  };

  xdg.configFile."hypr/hyprland.lua".text = ''
    -- ==============================================================================
    -- HYPRLAND LUA CONFIGURATION (v0.55+)
    -- ==============================================================================

    local terminal = "uwsm app -- konsole"
    local fileManager = "uwsm app -- dolphin"
    local menu = "uwsm app -- rofi -show drun"

    -- --- PLUGIN LOADING ---
    hl.plugin.load("${darkwindow}/lib/libhypr-darkwindow.so")
    hl.plugin.load("${hypr-canvas}/lib/hypr-canvas.so")
    hl.plugin.load("${hyprspace}/lib/libhyprspace.so")

    -- --- CONFIGURATION ---
    hl.config({
      monitor = ",preferred,auto,1.25",

      env = {
        "AQ_DRM_DEVICES,/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu",
        "LIBSEAT_BACKEND,logind",
        "XCURSOR_SIZE,24",
        "HYPRCURSOR_SIZE,24",
        "HYPRCURSOR_THEME,Hyprland-Logo",
        "NIXOS_OZONE_WL,1",
        "MOZ_ENABLE_WAYLAND,1",
        "SDL_VIDEODRIVER,wayland",
        "QT_QPA_PLATFORM,wayland;xcb",
        "QT_QPA_PLATFORMTHEME,qt6ct",
        "QT_STYLE_OVERRIDE,kvantum",
        "ELECTRON_OZONE_PLATFORM_HINT,auto",
      },

      cursor = {
        enable_hyprcursor = true,
        no_hardware_cursors = false,
      },

      general = {
        layout = "dwindle",
        resize_on_border = true,
        ["col.active_border"] = "rgba(94e2d5ff)",
        ["col.inactive_border"] = "rgba(ffffff14)",
        border_size = 2,
        gaps_in = 8,
        gaps_out = 16,
      },

      dwindle = {
        pseudotile = true,
        preserve_split = true,
      },

      decoration = {
        rounding = 12,
        active_opacity = 0.95,
        inactive_opacity = 0.85,
        blur = {
          enabled = true,
          size = 5,
          passes = 5,
          new_optimizations = true,
          ignore_opacity = true,
          xray = true,
          vibrancy = 0.10,
          popups = true,
          special = true,
        },
        shadow = {
          enabled = true,
          range = 30,
          render_power = 3,
          color = "rgba(00000022)",
        },
      },

      misc = {
        force_default_wallpaper = 2,
        disable_hyprland_logo = false,
        vfr = true,
      },

      input = {
        kb_layout = "us",
        kb_options = "ctrl:nocaps",
        follow_mouse = 1,
        natural_scroll = true,
        touchpad = {
          natural_scroll = true,
        },
      },

      gestures = {
        workspace_swipe = true,
        workspace_swipe_fingers = 3,
      },

      windowrulev2 = {
        "float, class:^(pavucontrol|blueman-manager)$",
        "size 900 650, class:^(pavucontrol)$",
        "animation off, class:^(steam)$",
        "opacity 0.96 0.92, class:^(kitty|Alacritty)$",
        "opacity 0.93 0.88, class:^(firefox|google-chrome|brave-browser|chromium)$",
        "opacity 0.93 0.88, class:^(code|cursor|antigravity)$",
      },

      xwayland = {
        force_zero_scaling = true,
      },
    })

    -- --- PLUGIN SETTINGS ---
    hl.config.plugin = {
      darkwindow = {
        tint_r = 0.20,
        tint_g = 0.70,
        tint_b = 1.00,
        tint_strength = 0.058,
        protect_brights = 1.00,
        bright_threshold = 0.55,
        bright_knee = 0.35,
        protect_saturated = 1.00,
        saturation_threshold = 0.05,
        saturation_knee = 0.25,
        enable_on_fullscreen = 0,
        tint_all_surfaces = 1,
      },
      overview = {
        panelColor = "rgba(1e1e2eef)",
        workspaceActiveBackground = "rgba(0d141b61)",
        workspaceInactiveBackground = "rgba(0d141b47)",
        workspaceActiveBorder = "rgba(94e2d5ff)",
        workspaceInactiveBorder = "rgba(b7bcc638)",
        workspaceBorderSize = 2,
        drawActiveWorkspace = true,
        workspaceActiveColor = "rgba(94e2d5ff)",
        autoScroll = true,
        exitOnClick = true,
        switchOnDrop = true,
        exitOnSwitch = true,
        autoDrag = true,
      },
    }

    -- --- AUTOSTART ---
    hl.on("hyprland.start", function()
      hl.exec_cmd("uwsm app -- ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1")
      hl.exec_cmd("uwsm app -- waybar")
    end)
    end)

    -- --- BINDS ---
    local mod = "SUPER"

    -- System/Apps
    hl.bind(mod, "Return", function() hl.exec_cmd(terminal) end)
    hl.bind(mod, "Q", "killactive")
    hl.bind(mod, "Tab", function() hl.exec_cmd(fileManager) end)
    hl.bind(mod, "Space", function() hl.exec_cmd(menu) end)
    hl.bind(mod, "F", "togglefloating")
    hl.bind(mod, "V", "fullscreen 0")
    hl.bind(mod, "L", function() hl.exec_cmd("uwsm app -- hyprlock") end)
    hl.bind(mod, "P", "togglechromakey")
    hl.bind(mod, "D", "overview:toggle")
    hl.bind(mod, "BackSpace", "layoutmsg togglesplit")

    -- Navigation
    hl.bind(mod, "left", "movefocus l")
    hl.bind(mod, "right", "movefocus r")
    hl.bind(mod, "up", "movefocus u")
    hl.bind(mod, "down", "movefocus d")

    -- Workspace Navigation
    hl.bind(mod, "period", "workspace e+1")
    hl.bind(mod, "comma", "workspace e-1")
    hl.bind(mod, "SHIFT, period", "movetoworkspace e+1")
    hl.bind(mod, "SHIFT, comma", "movetoworkspace e-1")

    -- Move windows
    hl.bind(mod .. " CTRL", "left", "moveactive -50 0")
    hl.bind(mod .. " CTRL", "right", "moveactive 50 0")
    hl.bind(mod .. " CTRL", "up", "moveactive 0 -50")
    hl.bind(mod .. " CTRL", "down", "moveactive 0 50")

    -- Workspaces
    for i = 1, 5 do
      hl.bind(mod, tostring(i), "workspace " .. i)
      hl.bind(mod .. " SHIFT", tostring(i), "movetoworkspace " .. i)
    end

    -- Canvas Controls
    hl.bind(mod, "R", "canvas:reset")
    hl.bind(mod .. " ALT SHIFT", "left", "canvas:pan left")
    hl.bind(mod .. " ALT SHIFT", "right", "canvas:pan right")
    hl.bind(mod .. " ALT SHIFT", "up", "canvas:pan up")
    hl.bind(mod .. " ALT SHIFT", "down", "canvas:pan down")
    hl.bind(mod, "minus", "canvas:zoom out")
    hl.bind(mod, "equal", "canvas:zoom in")

    -- Screenshots
    hl.bind("", "Print", function() hl.exec_cmd("uwsm app -- sh -lc 'mkdir -p \"$HOME/Images\" && grim \"$HOME/Images/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png\" && notify-send \"Screenshot saved\"'") end)
    hl.bind(mod, "Print", function() hl.exec_cmd("uwsm app -- sh -lc 'mkdir -p \"$HOME/Images\" && grim -g \"$(slurp)\" \"$HOME/Images/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png\" && notify-send \"Screenshot saved\"'") end)
    hl.bind(mod .. " SHIFT", "S", function() hl.exec_cmd("uwsm app -- sh -lc 'mkdir -p \"$HOME/Images\" && grim -g \"$(slurp)\" \"$HOME/Images/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png\" && notify-send \"Screenshot saved\"'") end)

    -- Function keys (Locked/Repeating)
    hl.bind("", "XF86AudioMute", "exec uwsm app -- wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
    hl.bind("", "XF86AudioPlay", "exec uwsm app -- playerctl play-pause", { locked = true })
    hl.bind("", "XF86MonBrightnessDown", "exec uwsm app -- brightnessctl set 5%-", { repeating = true, enabled = true })
    hl.bind("", "XF86MonBrightnessUp", "exec uwsm app -- brightnessctl set +5%", { repeating = true, enabled = true })
    hl.bind("", "XF86AudioLowerVolume", "exec uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-", { repeating = true, enabled = true })
    hl.bind("", "XF86AudioRaiseVolume", "exec uwsm app -- wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+", { repeating = true, enabled = true })

    -- Mouse binds
    hl.bind(mod, "mouse:272", "resizewindow", { mouse = true })
    hl.bind(mod, "mouse:273", "movewindow", { mouse = true })
  '';

  # Hypridle configuration
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        unlock_cmd = "pkill -USR1 hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  # Programs
  programs = {
    hyprlock = {
      enable = true;
      settings = {
        general = {
          no_fade_in = false;
          no_fade_out = false;
          hide_cursor = true;
          grace = 0;
          disable_loading_bar = false;
        };

        background = [{
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }];

        "input-field" = [{
          monitor = "";
          size = "200, 50";
          outline_thickness = 3;
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = false;
          outer_color = "rgb(94, 226, 213)";
          inner_color = "rgb(30, 30, 46)";
          font_color = "rgb(255, 255, 255)";
          placeholder_text = "Input Password...";
          font_family = "JetBrains Mono";
          fade_on_empty = true;
          fade_timeout = 1000;
          fade_in_duration = 200;
          fade_out_duration = 300;
          position = "0, -80";
          halign = "center";
          valign = "center";
          shadow_passes = 5;
          shadow_boost = 1.2;
        }];

        label = [
          {
            monitor = "";
            text = "$TIME";
            color = "rgba(255, 255, 255, 0.9)";
            font_size = 56;
            font_family = "JetBrains Mono";
            position = "0, 80";
            halign = "center";
            valign = "center";
            shadow_passes = 5;
            shadow_boost = 1.2;
          }
          {
            monitor = "";
            text = "cmd[update:18000] echo -n \"$(date +'%A, %d %B %Y')\"";
            color = "rgba(255, 255, 255, 0.82)";
            font_size = 20;
            font_family = "JetBrains Mono";
            position = "0, 20";
            halign = "center";
            valign = "center";
            shadow_passes = 3;
            shadow_boost = 1.0;
          }
        ];
      };
    };

    waybar = {
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

    starship = {
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

    bat.enable = true;
    fzf.enable = true;
    eza = {
      enable = true;
      enableBashIntegration = true;
      icons = "auto";
    };
  };
}
