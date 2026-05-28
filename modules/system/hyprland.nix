{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    withUWSM = true; # recommended for most users
    xwayland.enable = true;
    };

    # Hint for Ozone apps to use Wayland is moved to user-level env for consistency
    }
