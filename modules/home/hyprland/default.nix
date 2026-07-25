{ config, pkgs, inputs, lib, ... }:

let
  nerdFont = pkgs."nerd-fonts".fira-code;

in {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hyprland.nix
    ./cliphist.nix
    ./waybar.nix
    ./idle.nix
    ./theme.nix
    ./notifications.nix
    ./session-services.nix
    ./wleave.nix
  ];


  services.hyprpolkitagent.enable = true;
  services.avizo.enable = true;

  home.packages = with pkgs; [
    wl-clipboard
    jq
    xdg-utils
    libxcb-cursor

    waybar
    rofi
    kdePackages.dolphin
    kdePackages.qtsvg #needed for dolphin?
    #remote fs
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.kio-fuse

    kdePackages.kded
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kwalletmanager

    libsecret
    hyprshutdown
    nerdFont

    hypridle
    hyprlock
    hyprshot
    hyprpaper
    hyprpwcenter
  ];

  home.sessionVariables = {
    #XDG_CURRENT_DESKTOP = "Hyprland";
    #XDG_SESSION_TYPE = "wayland";
    #XDG_SESSION_DESKTOP = "Hyprland";
    # iGPU only — see modules/nixos/desktop/hyprland.nix (nvidia AQ hang).
    #AQ_DRM_DEVICES = "/dev/dri/intel-igpu";
    # Albert splits on `;` — wrap every launched app in a UWSM scope so polkit
    # can see a valid subject (see uwsm README launcher table).
    ALBERT_APPLICATIONS_COMMAND_PREFIX = "uwsm;app;--";
  };

  systemd.user.startServices = "sd-switch";
/*
  systemd.user.services.portmaster-tray = {
    Unit = {
      Description = "Portmaster tray UI";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "network-online.target"
      ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = pkgs.writeShellScript "portmaster-tray-wait" ''
        for _ in $(seq 1 30); do
          [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -n "''${WAYLAND_DISPLAY:-}" ] && break
          sleep 1
        done
        exec ${pkgs.portmaster}/bin/portmaster --background
      '';
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };*/

  services.hyprpaper= {
    enable = true;
    settings = {
      splash = false;
      ipc = "on"; # Required for your workspace script to send commands

      # The wallpaper setting must now use the block array format
      wallpaper = [
        {
          monitor = ""; # Leaving this empty acts as a fallback for all monitors
          path = "${config.home.homeDirectory}/Pictures/Wallpapers/workspace-1.png";
        }
      ];
    };
  };
}
