{ config, pkgs, inputs, lib, ... }:

let
  nerdFont = pkgs."nerd-fonts".fira-code;


  portalBackends = {
    default = [ "hyprland" "kde" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    "org.freedesktop.impl.portal.OpenURI" = [ "kde" ];
    "org.freedesktop.impl.portal.AppChooser" = [ "kde" ];
    "org.freedesktop.impl.portal.MimeResolver" = [ "kde" ];
  };
  
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hyprland.nix
    ./cliphist.nix
    ./waybar.nix
    ./idle.nix
    ./theme.nix
    ./notifications.nix
    ./wleave.nix
  ];

  wayland.systemd.target = lib.mkIf config.wayland.windowManager.hyprland.enable
    "graphical-session.target";

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemd.enable = false;
  };

  services.hyprpolkitagent.enable = true;
  services.avizo.enable = true;

  home.packages = with pkgs; [
    systemd # For systemctl during activation
    wl-clipboard
    jq
    xdg-utils
    libxcb-cursor

    waybar
    rofi
    kdePackages.dolphin
    kdePackages.kde-cli-tools
    kdePackages.bluedevil
    kdePackages.bluez-qt
    kdePackages.plasma-pa
    kdePackages.plasma-workspace
    kdePackages.breeze
    kdePackages.kded
    kdePackages.plasma-nm
    kdePackages.kwallet

    kdePackages.systemsettings
    libsecret
    hyprshutdown
    libnotify
    nerdFont

    hypridle
    hyprlock
    hyprshot
    hyprpaper
  ];

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    AQ_DRM_DEVICES = "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu";
  };

  # HM overrides NIX_XDG_DESKTOP_PORTAL_DIR — must enable portals in the user profile.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = lib.mkAfter [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    config = {
      hyprland = portalBackends;
      common.default = [ "hyprland" "kde" ];
    };
  };

  systemd.user.startServices = "sd-switch";

  systemd.user.services.portmaster-tray = {
    Unit = {
      Description = "Portmaster tray UI";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "network-online.target"
        "xdg-desktop-portal.service"
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
  };

  services.hyprpaper= {
    enable = true;
    settings = {
      splash = false;
      ipc = "on"; # Required for your workspace script to send commands
      
      # Preloads are now handled as a simple array list
      #preload = [
      #  "${config.home.homeDirectory}/Pictures/Wallpapers/workspace-1.png"
      #  "${config.home.homeDirectory}/Pictures/Wallpapers/workspace-2.png"
      #  "${config.home.homeDirectory}/Pictures/Wallpapers/workspace-3.png"
      #];

      # The wallpaper setting must now use the block array format
      wallpaper = [
        {
          monitor = ""; # Leaving this empty acts as a fallback for all monitors
          path = "${config.home.homeDirectory}/Pictures/Wallpapers/workspace-1.png";
        }
      ];
    };
  };

  # ksecretd is the KF6 KWallet daemon that provides the Secret Service D-Bus API.
  # PAM (via kwallet-pam) unlocks the wallet at login; this service keeps the daemon
  # running for the duration of the graphical session so apps can query secrets.
  systemd.user.services.plasma-kwallet-pam = {
    Unit = {
      Description = "KDE Wallet (ksecretd) Secret Service daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "dbus.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kwallet}/bin/ksecretd";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.plasma-kded6 = {
    Unit = {
      Description = "KDE Daemon 6";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "dbus.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kded}/bin/kded6";
      BusName = "org.kde.kded6";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.plasma-xdg-desktop-portal-kde = {
    Unit = {
      Description = "Xdg Desktop Portal For KDE";
      PartOf = [ "graphical-session.target" ];
      After = [ "xdg-desktop-portal.service" "dbus.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.xdg-desktop-portal-kde}/libexec/xdg-desktop-portal-kde";
      BusName = "org.freedesktop.impl.portal.desktop.kde";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
