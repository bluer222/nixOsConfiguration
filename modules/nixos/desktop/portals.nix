{ config, pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config = {
      # Desktop name is case-folded to lowercase by xdg-desktop-portal.
      hyprland = {
        default = [ "hyprland" "kde" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "kde" ];
      };
    };
  };
}
