{ config, pkgs, lib, ... }:

{
  # Dolphin "Open with" needs applications.menu; KDE ships plasma-applications.menu.
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  # Portals are configured in home-manager (xdg.portal) to avoid duplicate
  # dbus service registrations for xdg-desktop-portal-hyprland.
}
