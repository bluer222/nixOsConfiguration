{ config, pkgs, ... }:

{
  # Enable XDG Desktop Portals for screensharing and cross-desktop compatibility
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # hyprland portal is provided by programs.hyprland.portalPackage
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    # Default portal configuration
    config = {
      common.default = [ "kde" ];
      plasma.default = [ "kde" ];
      Hyprland.default = [ "hyprland" "gtk" ];
    };
  };
}
