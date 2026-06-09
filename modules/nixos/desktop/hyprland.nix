{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager = {
    defaultSession = "hyprland";
    sessionPackages = [ pkgs.hyprland ];
  };
}
