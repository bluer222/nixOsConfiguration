{ config, pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];
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
      swaylock = {
        enable = true;
        howdy = {
          enable = true;
          control = "[success=done default=ignore]";
        };
        kwallet = {
          enable = true;
          forceRun = true;
        };
      };
      greetd.kwallet.enable = true;
      systemd-run0 = {
        enable = true;
        howdy = {
          enable = true;
          control = "sufficient";
        };
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
