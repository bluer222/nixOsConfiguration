{ config, pkgs, ... }:

let
  helper = "${pkgs.niri-helper}/bin/niri-helper";
in {
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      inside-color = "1e1e2e";
      ring-color = "94e2d5";
      key-hl-color = "94e2d5";
      line-color = "00000000";
      text-color = "cdd6f4";
      layout-bg-color = "1e1e2e";
      layout-text-color = "cdd6f4";
      separator-color = "00000000";
      font = "FiraCode Nerd Font";
      indicator-radius = 100;
      indicator-thickness = 8;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    systemdTargets = [ "niri.service" ];
    timeouts = [
      {
        timeout = 90;
        command = "${helper} dim";
        resumeCommand = "${helper} restore";
      }
      {
        timeout = 120;
        command = "${pkgs.swaylock}/bin/swaylock -f; ${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors; && ${helper} restore";
      }
      {
        timeout = 140;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
      after-resume = "${helper} wake";
    };
  };

  home.file.".config/systemd/sleep.conf".text = ''
    [Sleep]
    HibernateDelaySec=900
  '';
}