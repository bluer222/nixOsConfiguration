{ config, pkgs, inputs, lib, ... }:

let
  nerdFont = pkgs."nerd-fonts".fira-code;

  portalBackends = {
    default = [ "hyprland" "kde" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    "org.freedesktop.impl.portal.OpenURI" = [ "kde" ];
    "org.freedesktop.impl.portal.AppChooser" = [ "kde" ];
    "org.freedesktop.impl.portal.MimeResolver" = [ "kde" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };
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

  # org.freedesktop.secrets via dbus — apps discover it through libsecret, no per-app flags.
  services.gnome-keyring.enable = true;

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
    kdePackages.bluez-qt
    kdePackages.plasma-pa
    kdePackages.plasma-workspace
    kdePackages.plasma-integration
    kdePackages.breeze
    kdePackages.systemsettings
    kdePackages.breeze-icons
    kdePackages.polkit-kde-agent-1
    kdePackages.kdeconnect-kde
    kdePackages.kded
    kdePackages.kscreen
    kdePackages.libkscreen
    kdePackages.plasma-nm

    kdePackages.oxygen-sounds
    libsecret
    gnome-keyring
    hyprshutdown
    avizo
    libnotify
    nerdFont

    hypridle
    hyprlock
    hyprshot
  ];

  # HM overrides NIX_XDG_DESKTOP_PORTAL_DIR — must enable portals in the user profile.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = lib.mkAfter [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      hyprland = portalBackends;
      common.default = [ "hyprland" "kde" ];
    };
  };

  systemd.user.startServices = "sd-switch";

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

  systemd.user.services.desktop-prewarm = {
    Unit = {
      Description = "Prebuild KDE cache and start portal/keyring daemons";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" "dbus.service" "pipewire-pulse.service" ];
      Before = [ "waybar.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "desktop-prewarm" ''
        set -euo pipefail
        ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
        systemctl --user start gnome-keyring.service 2>/dev/null || true
        systemctl --user start xdg-desktop-portal-gnome.service 2>/dev/null || true
        systemctl --user start plasma-kded6.service 2>/dev/null || true
        systemctl --user stop kwalletd6.service ksecretd.service 2>/dev/null || true
        ${pkgs.coreutils}/bin/killall -q kwalletd6 ksecretd 2>/dev/null || true
      '';
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.kdeconnectd = {
    Unit = {
      Description = "KDE Connect daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" "dbus.service" "desktop-prewarm.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.portmaster-tray = {
    Unit = {
      Description = "Portmaster tray UI";
      PartOf = [ "hyprland-session.target" ];
      After = [
        "hyprland-session.target"
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
        # Tray only — daemon runs via services.portmaster.
        exec ${pkgs.portmaster}/bin/portmaster --background
      '';
      Restart = "on-failure";
      RestartSec = 30;
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

  # Block kwallet/ksecretd — gnome-keyring owns org.freedesktop.secrets.
  systemd.user.services.kwalletd6 = {
    Unit = {
      Description = "kwalletd6 disabled (using gnome-keyring)";
      ConditionPathExists = "/nonexistent";
    };
    Service.ExecStart = "${pkgs.coreutils}/bin/false";
    Install.WantedBy = lib.mkForce [ ];
  };

  systemd.user.services.ksecretd = {
    Unit = {
      Description = "ksecretd disabled (using gnome-keyring)";
      ConditionPathExists = "/nonexistent";
    };
    Service.ExecStart = "${pkgs.coreutils}/bin/false";
    Install.WantedBy = lib.mkForce [ ];
  };

  xdg.dataFile."dbus-1/services/org.kde.kwalletd6.service".text = ''
    [D-BUS Service]
    Name=org.kde.kwalletd6
    Exec=/bin/false
  '';

  xdg.dataFile."dbus-1/services/org.kde.kwalletd5.service".text = ''
    [D-BUS Service]
    Name=org.kde.kwalletd5
    Exec=/bin/false
  '';

  xdg.dataFile."dbus-1/services/org.kde.secretservicecompat.service".text = ''
    [D-BUS Service]
    Name=org.kde.secretservicecompat
    Exec=/bin/false
  '';

  xdg.dataFile."dbus-1/services/org.freedesktop.impl.portal.desktop.kwallet.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.impl.portal.desktop.kwallet
    Exec=/bin/false
  '';

  systemd.user.services.plasma-kded6 = {
    Unit = {
      Description = "KDE Daemon 6";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" "dbus.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kded}/bin/kded6";
      BusName = "org.kde.kded6";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.xdg-desktop-portal-gnome = {
    Unit = {
      Description = "Xdg Desktop Portal For GNOME (Secret/keyring backend)";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" "gnome-keyring.service" "xdg-desktop-portal.service" ];
    };
    Service = {
      ExecStart = "${pkgs.xdg-desktop-portal-gnome}/libexec/xdg-desktop-portal-gnome";
      BusName = "org.freedesktop.impl.portal.desktop.gnome";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.plasma-xdg-desktop-portal-kde = {
    Unit = {
      Description = "Xdg Desktop Portal For KDE";
      PartOf = [ "hyprland-session.target" ];
      After = [ "xdg-desktop-portal.service" "dbus.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.xdg-desktop-portal-kde}/libexec/xdg-desktop-portal-kde";
      BusName = "org.freedesktop.impl.portal.desktop.kde";
      Restart = "no";
      Environment = [
        "QT_STYLE_OVERRIDE="
        "XDG_CURRENT_DESKTOP=KDE:Hyprland"
      ];
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.mcontrolcenter = {
    Unit = {
      Description = "MControlCenter (MSI EC / brightness keys)";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mcontrolcenter}/bin/mcontrolcenter --minimize";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
