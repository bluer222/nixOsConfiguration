{ config, pkgs, ... }:

{
  # KDE Plasma Desktop Environment
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE Connect
  programs.kdeconnect.enable = true;
}
