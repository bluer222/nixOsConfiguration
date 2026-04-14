{ config, pkgs, ... }:

{
  # KDE Plasma Desktop Environment
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.variables = {
    # Use KDE file picker instead of GTK
    GTK_USE_PORTAL = 1;
  };

  # Bluetooth support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # KDE Connect
  programs.kdeconnect.enable = true;

  # Howdy facial authentication
  services.howdy.enable = true;
  services.howdy = {
    control = "sufficient";
    settings = {
      video = {
        dark_threshold = 90;
      };
    };
  };

  # IR emitter support (for infrared cameras)
  services.linux-enable-ir-emitter.enable = true;
  services.linux-enable-ir-emitter.device = "video2";
}
