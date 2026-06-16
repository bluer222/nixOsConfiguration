{ config, pkgs, lib, ... }:

{
  # Dolphin "Open with" needs applications.menu; KDE ships plasma-applications.menu.
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
    
    config = {
      common = {
        default = [ "hyprland" "kde" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "kde" "gtk" ];
        # Force FileChooser to use the KDE portal (Dolphin)
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
      };
    };
  };

}
