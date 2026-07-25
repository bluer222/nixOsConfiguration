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
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 60;
          on-timeout = "hyprctl eval 'dim_brightness()'";
          on-resume = "hyprctl eval 'restore_brightness()'";
        }
        {
          timeout = 80;
          on-timeout = "loginctl lock-session && hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 90;
          on-timeout = "systemctl suspend-then-hibernate";
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
  # suspend-then-hibernate
  # -----------------------------------------------------
  home.file.".config/systemd/sleep.conf".text = ''
    [Sleep]
    HibernateDelaySec=900
  '';
}
