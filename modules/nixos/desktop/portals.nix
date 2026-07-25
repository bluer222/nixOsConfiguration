{ config, pkgs, lib, ... }:

{
  # Dolphin "Open with" needs applications.menu; KDE ships plasma-applications.menu.
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      kdePackages.xdg-desktop-portal-kde
      # Last-resort FileChooser / Settings fallback (prefer KDE above).
      #xdg-desktop-portal-gtk
    ];

    config = {
      common = {
        default = [ "hyprland" "kde" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "kde" "gtk" ];
        # Force FileChooser to use the KDE portal (Dolphin-style picker)
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
      };
    };
  };

  # UWSM sets WAYLAND_DISPLAY before the compositor accepts clients. Portals then
  # dbus-activate, crash/fail, and hit start-limit — leaving FileChooser dead for
  # the whole session. Harden retries and re-start the stack once the session is up.
  #
  # Only tweak drop-in fields here — declaring wantedBy/after for package-provided
  # units (e.g. plasma-xdg-desktop-portal-kde) replaces the unit and drops ExecStart.
  /*
  systemd.user.services.xdg-desktop-portal-hyprland = {
    unitConfig = {
      StartLimitIntervalSec = "60";
      StartLimitBurst = "10";
    };
    serviceConfig = {
      RestartSec = "2";
    };
  };

  systemd.user.services.xdg-portal-fixup = {
    description = "Reset xdg portals after graphical session is ready";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "xdg-portal-fixup" ''
        set -eu
        systemctl --user reset-failed \
          xdg-desktop-portal-hyprland.service \
          plasma-xdg-desktop-portal-kde.service \
          xdg-desktop-portal.service \
          xdg-desktop-portal-gtk.service 2>/dev/null || true

        # Backends first so the host portal can bind FileChooser / Screencast.
        systemctl --user start plasma-xdg-desktop-portal-kde.service || true
        systemctl --user start xdg-desktop-portal-hyprland.service || true
        systemctl --user restart xdg-desktop-portal.service || true
      '';
    };
  };*/
}
