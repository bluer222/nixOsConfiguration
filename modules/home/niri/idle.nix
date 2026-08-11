{ config, pkgs, ... }:

let
  helper = "${pkgs.niri-helper}/bin/niri-helper";
in {
  programs.swaylock = {
    enable = true;
    packages = pkgs.swaylock-effects;
    settings = {
      color = "24273a";
      bs-hl-color = "f4dbd6";
      caps-lock-bs-hl-color = "f4dbd6";
      caps-lock-key-hl-color = "a6da95";
      inside-color = "24273a";
      inside-clear-color = "24273a";
      inside-caps-lock-color = "24273a";
      inside-ver-color = "24273a";
      inside-wrong-color = "24273a";
      key-hl-color = "a6da95";
      layout-bg-color = "00000000";
      layout-border-color = "00000000";
      layout-text-color = "cad3f5";
      line-color = "00000000";
      line-clear-color = "00000000";
      line-caps-lock-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      ring-color = "363a4f";
      ring-clear-color = "f4dbd6";
      ring-caps-lock-color = "f5a97f";
      ring-ver-color = "8aadf4";
      ring-wrong-color = "ee99a0";
      separator-color = "00000000";
      text-color = "cad3f5";
      text-clear-color = "f4dbd6";
      text-caps-lock-color = "f5a97f";
      text-ver-color = "8aadf4";
      text-wrong-color = "ee99a0";
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
        command = "${pkgs.swaylock}/bin/swaylock -f --screenshots --clock --indicator; ${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors; && ${helper} restore";
      }
      {
        timeout = 140;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f --screenshots --clock --indicator";
      after-resume = "${helper} wake";
    };
  };

  home.file.".config/systemd/sleep.conf".text = ''
    [Sleep]
    HibernateDelaySec=900
  '';
}