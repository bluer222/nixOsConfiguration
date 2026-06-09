{ config, pkgs, ... }:

{
  # KDE Plasma Desktop Environment
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE Connect
  programs.kdeconnect.enable = true;

  # Ensure Wayland is used for Electron/Ozone apps (Brave, OBS, etc.)
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    OBS_USE_EGL = "1";
  };
}
