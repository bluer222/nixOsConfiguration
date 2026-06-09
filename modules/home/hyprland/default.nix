{ config, pkgs, inputs, lib, ... }:

let
  nerdFont = pkgs."nerd-fonts".fira-code;
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hyprland.nix
    ./waybar.nix
    ./idle.nix
    ./theme.nix
    ./scripts.nix
    ./notifications.nix
    ./avizo.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    cliphist
    jq
    xdg-utils
    libxcb-cursor

    waybar
    rofi
    kdePackages.dolphin
    kdePackages.kde-cli-tools
    kdePackages.bluedevil
    kdePackages.plasma-pa
    kdePackages.plasma-workspace
    kdePackages.plasma-integration
    kdePackages.breeze
    kdePackages.systemsettings
    kdePackages.breeze-icons
    kdePackages.kwallet
    kdePackages.polkit-kde-agent-1

    kdePackages.oxygen-sounds
    sound-theme-freedesktop
    avizo
    brightnessctl
    libnotify
    nerdFont

    wdisplays
    hypridle
    hyprlock
    hyprshot
  ];

  # HM overrides NIX_XDG_DESKTOP_PORTAL_DIR to the user profile; kde.portal must
  # be present there or FileChooser falls back to the GTK portal.
  xdg.portal.extraPortals = lib.mkAfter [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  xdg.portal.config.hyprland = {
    default = [ "hyprland" "kde" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    "org.freedesktop.impl.portal.OpenURI" = [ "kde" ];
  };

  systemd.user.startServices = "sd-switch";

  systemd.user.services.kwalletd6 = {
    Unit = {
      Description = "KDE Wallet daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" "dbus.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.polkit-kde-agent = {
    Unit = {
      Description = "KDE Polkit Authentication Agent";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.power-sounds = {
    Unit = {
      Description = "Power plug/unplug sounds";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" "pipewire-pulse.service" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/.config/hypr/scripts/power-sounds.sh";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.wallpaper-watcher = {
    Unit = {
      Description = "Change wallpaper on workspace switch (including swipes)";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper-watcher.sh";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.popup-closer = {
    Unit = {
      Description = "Close plasmawindowed popups when focus is lost";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/.config/hypr/scripts/popup-closer.sh";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
