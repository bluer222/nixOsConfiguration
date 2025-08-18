# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, lib, stdenv, ... }:

let
#sddmTheme = pkgs.callPackage ./sddmbkrd.nix { };
in{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    #include gpu config because nvidia
    ./gpu.nix
    #enable tlp(power saving stuff) and config
    ./tlp.nix
    #enable nginx and config(locahlost)
    ./nginx.nix
    #printer
    ./printers.nix
    #systemd services
    ./systemd.nix
    #boot stuff
    ./boot.nix
    #instll apps and user config
    ./apps.nix
    #vr
    ./vr.nix
    #home manager?
    inputs.home-manager.nixosModules.home-manager
  ];


  #nixpkgs.hostPlatform = {
  #  system = "x86_64-linux";
  #  gcc.arch = "raptorlake";
  #  gcc.tune = "raptorlake";
  #};

  nix.settings.system-features = [ "gccarch-raptorlake" ];


   home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
home-manager.backupFileExtension = "hm-backup";
   # Configure Home Manager for a specific user
  home-manager.users.samm = {
  home.stateVersion = "25.05";

  };

  #allows hybernate
  security.protectKernelImage = false;

#auto time
services.automatic-timezoned.enable = true;
services.timesyncd.enable = true;

  #sudo password feedback
  security.sudo.extraConfig = "Defaults pwfeedback";
#polkit
  security.polkit.enable = true;
#run0 dont ask every time
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_KEEP;
      }
    });
  '';
  #appimage stuff(makes appimages work)
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
    magicOrExtension = "\\x7fELF....AI\\x02";
  };

environment.variables = {
#kde file picker instead of gtk one
GTK_USE_PORTAL=1;
};
  #set swappieness
  boot.kernel.sysctl = { "vm.swappiness" = 20; };

  #what it shows up as on the newtwork
  networking.hostName = "Sam-Computer"; # Define your hostname.

  # Enable networking via network manager
  networking.networkmanager.enable = true;
  boot.blacklistedKernelModules = [ "cdc_ncm" ];

  # Enable BBR congestion control and nvidia_uvm for cuda and i2c for auto brightness maybe
  #msi ec for mcontrolcenter
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
  boot.kernelModules = [ "tcp_bbr" "nvidia_uvm" "i2c-dev" "ax88179_178a" "ec_sys" "msi-ec"];

boot.extraModprobeConfig = ''
  softdep cdc_ncm pre: ax88179_178a
'';
    networking.usePredictableInterfaceNames = true;

boot.kernel.sysctl = {
  "net.core.default_qdisc" = "fq";
  "net.ipv4.tcp_congestion_control" = "bbr";
}; # see https://news.ycombinator.com/item?id=14814530

  #firewall
  networking.firewall.enable = true;

  #nftables is better but breaks qemu i think
  networking.nftables.enable = false;

  #auto optimize
  nix.settings.auto-optimise-store = true;

  # Set your time zone.
  #i set this to be automatic
  #time.timeZone = "America/New_York";

  # Select internationalisation properties.
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

  # Enable the KDE Plasma Desktop Environment.
services.displayManager.sddm.wayland.enable = true;
services.displayManager.sddm.enable = true;
services.desktopManager.plasma6.enable = true;
services.displayManager.sddm.package = lib.mkForce pkgs.kdePackages.sddm;
services.displayManager.sddm.theme = "breeze";
environment.systemPackages = [ ];
#lets try hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
    xwayland.enable = true; # Xwayland can be disabled.
  };
services.displayManager.sessionPackages = [ pkgs.hyprland ];
services.vnstat.enable = true;
  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    wireplumber.enable = true;
  };
  users.users.samm.shell = pkgs.zsh;


  programs.zsh = {
  enable = true;
  enableCompletion = true;
  autosuggestions = {
  enable = true;
  async = true;
  };
  ohMyZsh = {
  enable = true;
  theme = "robbyrussell";
  };
  syntaxHighlighting.enable = true;

  shellAliases = {
    srun = "systemd-run";
    rebs = "srun nixos-rebuild switch --flake '/etc/nixos#default' --log-format internal-json -v  |& nom --json";
    rebb = "srun nixos-rebuild boot --flake '/etc/nixos#default' --log-format internal-json -v  |& nom --json";

  };
  histSize = 10000;
};

  # enables support for Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  #kde connect so i can use phone from computer
  programs.kdeconnect.enable = true;

  #enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget


  #nix version
  nix.package = pkgs.nixVersions.latest;
  #new version for run0
  system.rebuild.enableNg = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
