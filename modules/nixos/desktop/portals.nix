{ config, pkgs, ... }:

{
  # Enable XDG Desktop Portals for screensharing and cross-desktop compatibility
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    # Default portal configuration
    config = {
      common.default = [ "kde" ];
      plasma.default = [ "kde" ];
      Hyprland.default = [ "hyprland" "gtk" ];
    };
  };
}
