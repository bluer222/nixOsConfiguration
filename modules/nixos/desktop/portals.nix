{ config, pkgs, lib, ... }:

{
  # Dolphin "Open with" needs applications.menu; KDE ships plasma-applications.menu.
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gnome # ScreenCast / portal Screenshot backend only
      xdg-desktop-portal-gtk
    ];

    config = {
      common = {
        default = [ "kde" "gtk" ];
      };
      # mkForce: nixpkgs programs.niri also sets config.niri (GNOME/keyring defaults).
      niri = lib.mkForce {
        default = [ "kde" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      };
    };
  };
}
