{ config, pkgs, ... }:

{
  # Security settings
  security = {
    protectKernelImage = false; #disabled for hibernation 
    sudo.extraConfig = "Defaults pwfeedback";
    polkit.enable = true;

    # Minimize password verification delay
    pam.services = {
      login.nodelay = true;
      sudo.nodelay = true;
      polkit-1.nodelay = true;
      su.nodelay = true;
    };
  };

  # Time and locale
  services.automatic-timezoned.enable = true;
  services.timesyncd.enable = true;
  services.geoclue2.enable = true;
  programs.dconf.enable = true;

  # Name service caching
  services.nscd.enable = true;
  services.nscd.enableNsncd = true;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Kernel settings
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
  };

  # Nix settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System auto-upgrade
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#samm-desktop";
    flags = [
      "--print-build-logs"
      "--recreate-lock-file"
    ];
    dates = "09:00";
    runGarbageCollection = true;
  };
}
