{ config, pkgs, lib, inputs, ... }:

let
  home = config.home.homeDirectory;
  helper = "${pkgs.niri-helper}/bin/niri-helper";
  calendarUrls = import "${inputs.nixos-secrets}/noctalia-calendars.nix";
  # run ocr for super+prtscr
  ocrPipe = pkgs.writeShellScript "noctalia-ocr-pipe" '' 
    set -eu
    flag="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/noctalia-ocr-request"
    if [ -f "$flag" ]; then
      rm -f "$flag"
      text="$(${pkgs.tesseract}/bin/tesseract stdin stdout 2>/dev/null | ${pkgs.gnused}/bin/sed 's/[[:space:]]*$//')"
      if [ -z "$text" ]; then
        ${pkgs.libnotify}/bin/notify-send -u normal OCR "No text found"
        exit 0
      fi
      printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
      preview="$(printf '%s' "$text" | ${pkgs.coreutils}/bin/head -c 120)"
      ${pkgs.libnotify}/bin/notify-send -u low OCR "$preview"
    else
      ${pkgs.coreutils}/bin/cat >/dev/null
    fi
  '';
in {
  # Bind Wayland user services (including noctalia) to the niri session.
  wayland.systemd.target = "niri.service";

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        external_ip_enabled = true; #find the wan ip for network panel
        corner_radius_scale = 0; #sharp corners
        font_family = "FiraCode Nerd Font";
        polkit_agent = true;
        setup_wizard_enabled = false;
        launch_apps_as_systemd_services = true;
        clipboard_enabled = true;
        clipboard_history_max_entries = 500;
        clipboard_keep_from_closed_apps = true;
        panel = { #clipboard and polkit prompt are panels
          shadow = false;
          open_near_click_control_center = true; #open callender etc near the widget
          transparency_mode = "soft";
        };
        animation.speed = 1.4; #niri slowdown=0.7, 1/0.7~1.4
        screenshot = {
          directory = "${home}/Pictures/Screenshots";
          filename_pattern = "%Y-%m-%d %H-%M-%S";
          save_to_file = true;
          copy_to_clipboard = true;
          pipe_to_command = true;
          confirm_region = true;
          pipe_command = "${ocrPipe}";
          show_cursor = false;
          freeze_screen = true;
          remember_last_region = true;
        };
        session = {
          actions = [
            { action = "lock"; }
            { action = "logout"; }
            {
              action = "command";
              label = "Suspend";
              glyph = "bedtime";
              command = "systemctl suspend-then-hibernate";
            }
            {
              action = "command";
              label = "Hibernate";
              glyph = "moon";
              command = "systemctl hibernate";
            }
            { action = "reboot"; }
            {
              action = "shutdown";
            }
          ];
        };
        launcher = {
          compact = true;
          providers ={
            session.global = true; #always have shutdown etc in the launcher
            windows.global = true; #have windows in the launcher
          };
        };
      };

      control_center = {
        hidden_tabs = ["weather"];
      };

      plugins = {
        enabled = [ ];
        auto_update = true;
      };

      #battery threshold plugin
      #plugin_settings = {
      #  "damian-ds7/battery-threshold" = {
      #    battery_device = "/sys/class/power_supply/BAT1";
      #    charge_threshold = 100;
      #  };
      #};


      theme = {
        mode = "dark";
        source = "wallpaper";
        #theme other apps
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [ "gtk3" "gtk4" "qt" "kcolorscheme" "btop" "niri" ];
          community_ids = [ "blender" "antigravity" "gimp" "inkscape" "libreoffice" "vscode" "steam" "fastfetch" "obs" ];
        };
        #builtin = "Catppuccin";
      };

      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        directory = "${home}/Pictures/Wallpapers";
        transition = [ "zoom" ];
        transition_duration = 400;
        transition_on_startup = false;
        default.path = "${home}/Pictures/Wallpapers/workspace-1.png";
      };

      notification = {
        enable_daemon = true;
      };

      osd = {
        position = "top_center";
      };

      battery = {
        warning_threshold = 20;
      };
      
      weather.enabled = false;

      calendar = {
        enabled = true;
        account = {
          home = {
            type = "google";
            name = "home";
            color = "primary";
          };
          work = {
            type = "ics";
            name = "work";
            color = "secondary";
            server_url = calendarUrls.work;
          };
          canvas = {
            type = "ics";
            name = "canvas";
            color = "tertiary";
            server_url = calendarUrls.canvas;
          };
        };
      };

      audio = {
        enable_sounds = true;
        notification_sound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/dialog-information.ogg";
      };

      #1% minimum to stop black screen
      brightness.minimum_brightness = 0.01;

      hooks = {
        started = "noctalia msg session lock";
        # MSI EC power profile via niri-helper (replaces upower battery monitor).
        battery_charging = "${helper} power-plugged";
        battery_plugged = "${helper} power-plugged";
        battery_discharging = "${helper} power-unplugged";
      };

      lockscreen = {
        enabled = true;
        blurred_desktop = true;
        lock_before_suspend = true;
        # for howdy face recognition
        fingerprint = false;
        allow_empty_password = true;
      };

      idle = {
        pre_action_fade_seconds = 0;
        behavior = {
          dim = {
            timeout = 90;
            action = "command";
            command = "${helper} dim";
            resume_command = "${helper} restore";
            enabled = true;
          };
          lock = {
            timeout = 120;
            action = "lock";
            enabled = true;
          };
          "screen-off" = {
            timeout = 120;
            action = "screen_off";
            enabled = true;
          };
          suspend = {
            timeout = 140;
            action = "command";
            command = "systemctl suspend-then-hibernate";
            resume_command = "${helper} wake";
            enabled = true;
          };
        };
      };

      bar.main = {
        shadow = false;
        position = "top";
        thickness = 34;
        background_opacity = 1.0;
        #go all the way to left and right edge, sharp conrers
        margin_ends = 0;
        radius = 0;
        capsule_radius = 0;
        # have windows not overlap the bar
        reserve_space = true;
        start = [ "taskbar" "spacer" "cpu" "cpu_label" "ram" ];
        center = [ "workspaces" ];
        end = [
          "network-up"
          "network-down"
          "spacer"
          "bluetooth"
          "network"
          "volume"
          "battery"
          "power_profile"
          "tray"
          "clock"
          "notifications"
        ];
      };

      widget.network-up = {
        type = "sysmon";
        stat = "net_tx";
        visualization = "none";
        color = "#289b45";
      };

      widget.network-down = {
        type = "sysmon";
        stat = "net_rx";
        visualization = "none";
        color = "#9b1c1c";
      };

      widget.cpu = { 
        type = "sysmon";
        stat = "cpu_usage";
        show_value = true;
        visualization = "gauge";
        show_glyph = false;
      };

      widget.cpu_label = {
        type = "text";
        text = "CPU";
      };

      widget.ram = { 
        type = "sysmon";
        stat = "ram_used";
        show_value = true;
        visualization = "gauge";
        show_glyph = false;
      };

      widget.workspaces = {
        #optimally hide #4 only but not an option
        hide_when_empty = false;
        label_source = "id";
      };

      widget.taskbar = {
        show_window_title = true;
        only_active_workspace = true;
        taskbar_max_width = 720;
        window_title_max_width = 720;
      };

      widget.clock = {
          format = "{:%a %d/%b %m/%y  %H:%M}";
          tooltip_format = "{:%A, %d %B %Y  %H:%M:%S}";
      };

      dock.enabled = false;
      desktop_widgets.enabled = false;
    };
  };

  # Hibernate delay after suspend-then-hibernate (was in idle.nix).
  home.file.".config/systemd/sleep.conf".text = ''
    [Sleep]
    HibernateDelaySec=900
  '';

  # Bluetooth reconnect after lid / logind sleep (idle resume_command covers idle-triggered suspend).
  systemd.user.services.niri-helper-wake = {
    Unit = {
      Description = "Reconnect bluetooth after sleep";
      After = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${helper} wake";
    };
    Install.WantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
  };
}
