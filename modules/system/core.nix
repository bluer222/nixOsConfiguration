{ config, pkgs, ... }:

{
  # Security settings
  security.protectKernelImage = false;
  security.sudo.extraConfig = "Defaults pwfeedback";
  security.polkit.enable = true;

  # Time and locale
  services.automatic-timezoned.enable = true;
  services.timesyncd.enable = true;

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
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
    magicOrExtension = "\\x7fELF....AI\\x02";
  };

  # Kernel settings
  boot.kernel.sysctl = {
    "vm.swappiness" = 40;
  };

  # Memory compression settings (disabled, using zswap instead)
  zramSwap = {
    enable = false;
    memoryPercent = 100;
    algorithm = "zstd";
    priority = 5;
  };

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.package = pkgs.nixVersions.latest;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Auto optimize store
  nix.settings.auto-optimise-store = true;

  # System auto-upgrade
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos";
    flags = [
      "--print-build-logs"
      "--recreate-lock-file"
    ];
    dates = "09:00";
    runGarbageCollection = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
