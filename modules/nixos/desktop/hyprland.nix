{ config, pkgs, inputs, ... }:

{
  # System-level Hyprland module (ensures login manager sees the session and XWayland is available)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    
    # Use the version from the flake input
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Ensure the session shows up in the login manager (SDDM/Plasma login manager)
  services.displayManager.sessionPackages = [ inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland ];
}
