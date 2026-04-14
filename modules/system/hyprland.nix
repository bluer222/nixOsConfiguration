{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Optional: Enable hint for Ozone apps (like Chrome/VSCode) to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
