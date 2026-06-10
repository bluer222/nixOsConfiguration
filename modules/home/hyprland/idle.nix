{ config, pkgs, ... }:

{
  # -----------------------------------------------------
  # Hypridle Configuration
  # -----------------------------------------------------
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "~/.config/hypr/scripts/session-resume.sh";
      };

      # 45s: Dim screen (Battery only)
      listener = [
        {
          timeout = 45;
          on-timeout = "cat /sys/class/power_supply/*/online | grep -q 1 || ~/.config/hypr/scripts/brightness-dim.sh";
          on-resume = "~/.config/hypr/scripts/brightness-restore.sh";
        }
        
        # 60s: Screen off (Battery), Lock/Dim (AC)
        {
          timeout = 60;
          on-timeout = ''
            if cat /sys/class/power_supply/*/online | grep -q 1; then
              # AC: Lock and Dim
              loginctl lock-session
              ~/.config/hypr/scripts/brightness-dim.sh
            else
              # Battery: Screen off
              hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = "off" }))'
            fi
          '';
          on-resume = "~/.config/hypr/scripts/brightness-restore.sh; ~/.config/hypr/scripts/session-resume.sh";
        }

        # 120s: Suspend (Battery)
        {
          timeout = 120;
          on-timeout = "cat /sys/class/power_supply/*/online | grep -q 1 || systemctl suspend-then-hibernate";
        }

        # 180s: Screen off (AC)
        {
          timeout = 180;
          on-timeout = "cat /sys/class/power_supply/*/online | grep -q 1 && hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = \"off\" }))'";
          on-resume = "~/.config/hypr/scripts/session-resume.sh";
        }

        # 240s: Suspend (AC)
        {
          timeout = 240;
          on-timeout = "cat /sys/class/power_supply/*/online | grep -q 1 && systemctl suspend-then-hibernate";
        }
      ];
    };
  };

  # -----------------------------------------------------
  # Hyprlock Configuration
  # -----------------------------------------------------
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        ignore_empty_input = false;
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(205, 214, 244)";
          inner_color = "rgb(30, 30, 46)";
          outer_color = "rgb(148, 226, 213)";
          outline_thickness = 2;
          placeholder_text = "Face unlock or type password...";
          shadow_passes = 2;
        }
      ];
    };
  };

  # -----------------------------------------------------
  # Ensure suspend-then-hibernate and deep sleep
  # (Note: Some of these need to be in configuration.nix, 
  # added here for completeness, though systemd settings 
  # via home-manager might not cover the full logind scope)
  # -----------------------------------------------------
  home.file.".config/systemd/sleep.conf".text = ''
    [Sleep]
    HibernateDelaySec=900
  '';
}
