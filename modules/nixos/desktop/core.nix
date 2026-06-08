{ config, pkgs, ... }:

{
  environment.variables = {
    # Use KDE file picker instead of GTK
    GTK_USE_PORTAL = 1;
  };

  # Bluetooth support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Howdy facial authentication
  services.howdy.enable = true;
  services.howdy = {
    settings = {
      video = {
        dark_threshold = 90;
      };
    };
  };

  # Use Howdy only for screen locking, sudo, and polkit (run0), not for initial login
  security.pam = {
    howdy.enable = false;
    services = {
      systemd-run0 = {
        enable = true;
        howdy = {
          enable = true;
          control = "sufficient";
        };
      };
      kde.howdy = {
        enable = true;
        control = "sufficient";
      };
      sudo.howdy = {
        enable = true;
        control = "sufficient";
      };
      polkit-1.howdy = {
        enable = true;
        control = "sufficient";
      };
    };
  };

  # IR emitter support (for infrared cameras)
  services.linux-enable-ir-emitter.enable = true;
  services.linux-enable-ir-emitter.device = "video2";
}
